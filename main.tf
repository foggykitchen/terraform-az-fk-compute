locals {
  nic_ipconfig_name = "ipconfig1"
  use_multi_nic     = var.deployment_mode == "vm" && try(length(var.network_interfaces), 0) > 0

  primary_multi_nic_keys = local.use_multi_nic ? [
    for nic_key, nic in var.network_interfaces : nic_key if try(nic.primary, false)
  ] : []

  ordered_multi_nic_keys = local.use_multi_nic ? concat(
    local.primary_multi_nic_keys,
    sort([
      for nic_key, nic in var.network_interfaces : nic_key if !try(nic.primary, false)
    ])
  ) : []

  primary_multi_nic_key = local.use_multi_nic ? local.primary_multi_nic_keys[0] : null
}

# =========================
# Single VM
# =========================

resource "azurerm_network_interface" "vm_nic" {
  count                 = var.deployment_mode == "vm" && !local.use_multi_nic ? 1 : 0
  name                  = "${var.name}-nic"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = var.enable_ip_forwarding

  ip_configuration {
    name                          = local.nic_ipconfig_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address_allocation == "Static" ? var.private_ip_address : null
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition = (
        var.private_ip_address_allocation == "Dynamic" ||
        try(trimspace(var.private_ip_address), "") != ""
      )
      error_message = "private_ip_address must be set when private_ip_address_allocation is 'Static'."
    }
  }
}

resource "azurerm_network_interface" "vm_multi_nic" {
  for_each              = local.use_multi_nic ? var.network_interfaces : {}
  name                  = "${var.name}-${each.key}-nic"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = try(each.value.enable_ip_forwarding, false)

  ip_configuration {
    name                          = local.nic_ipconfig_name
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = try(each.value.private_ip_address_allocation, "Dynamic")
    private_ip_address            = try(each.value.private_ip_address_allocation, "Dynamic") == "Static" ? try(each.value.private_ip_address, null) : null
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition = (
        try(each.value.private_ip_address_allocation, "Dynamic") == "Dynamic" ||
        try(trimspace(each.value.private_ip_address), "") != ""
      )
      error_message = "private_ip_address must be set for every multi-NIC entry using Static allocation."
    }

    precondition {
      condition     = contains(["Dynamic", "Static"], try(each.value.private_ip_address_allocation, "Dynamic"))
      error_message = "private_ip_address_allocation must be either 'Dynamic' or 'Static' for every multi-NIC entry."
    }
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  count                     = (var.deployment_mode == "vm") && !local.use_multi_nic && (var.attach_nsg_to_nic) ? 1 : 0
  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = var.nsg_id
}

resource "azurerm_network_interface_security_group_association" "vm_multi_nic_nsg" {
  for_each = local.use_multi_nic ? {
    for nic_key, nic in var.network_interfaces : nic_key => nic
    if try(nic.attach_nsg_to_nic, false)
  } : {}

  network_interface_id      = azurerm_network_interface.vm_multi_nic[each.key].id
  network_security_group_id = each.value.nsg_id

  lifecycle {
    precondition {
      condition     = try(trimspace(each.value.nsg_id), "") != ""
      error_message = "nsg_id must be set for every multi-NIC entry where attach_nsg_to_nic is true."
    }
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.deployment_mode == "vm" ? 1 : 0
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = local.use_multi_nic ? [
    for nic_key in local.ordered_multi_nic_keys : azurerm_network_interface.vm_multi_nic[nic_key].id
    ] : [
    azurerm_network_interface.vm_nic[0].id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = var.image_reference.publisher
    offer     = var.image_reference.offer
    sku       = var.image_reference.sku
    version   = var.image_reference.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = var.custom_data

  dynamic "identity" {
    for_each = var.identity_type == "SystemAssigned" ? [1] : []

    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = local.use_multi_nic || try(trimspace(var.subnet_id), "") != ""
      error_message = "subnet_id must be set when using the single-NIC VM deployment path."
    }

    precondition {
      condition     = !local.use_multi_nic || length(local.primary_multi_nic_keys) == 1
      error_message = "Exactly one multi-NIC entry must be marked as primary = true."
    }

    precondition {
      condition     = !local.use_multi_nic || var.app_gateway_attachment == null
      error_message = "app_gateway_attachment is currently supported only in the single-NIC VM deployment path."
    }

    precondition {
      condition     = !local.use_multi_nic || var.lb_attachment == null
      error_message = "lb_attachment is currently supported only in the single-NIC VM deployment path."
    }
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "vm_lb_attach" {
  count = var.deployment_mode == "vm" && !local.use_multi_nic && var.lb_attachment != null ? 1 : 0

  network_interface_id    = azurerm_network_interface.vm_nic[0].id
  ip_configuration_name   = local.nic_ipconfig_name
  backend_address_pool_id = var.lb_attachment.backend_pool_id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "vm_app_gateway_attach" {
  count = var.deployment_mode == "vm" && !local.use_multi_nic && var.app_gateway_attachment != null ? 1 : 0

  network_interface_id    = azurerm_network_interface.vm_nic[0].id
  ip_configuration_name   = local.nic_ipconfig_name
  backend_address_pool_id = var.app_gateway_attachment.backend_pool_id
}

# =========================
# VM Scale Set
# =========================

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  count               = var.deployment_mode == "vmss" ? 1 : 0
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.vm_size
  instances           = var.instance_count
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = var.image_reference.publisher
    offer     = var.image_reference.offer
    sku       = var.image_reference.sku
    version   = var.image_reference.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name                 = "${var.name}-nic"
    primary              = true
    enable_ip_forwarding = var.enable_ip_forwarding

    ip_configuration {
      name      = local.nic_ipconfig_name
      primary   = true
      subnet_id = var.subnet_id

      application_gateway_backend_address_pool_ids = (
        var.app_gateway_attachment != null ? [var.app_gateway_attachment.backend_pool_id] : []
      )

      load_balancer_backend_address_pool_ids = (
        var.lb_attachment != null ? [var.lb_attachment.backend_pool_id] : []
      )
    }
  }

  custom_data = (var.custom_data != null && trimspace(var.custom_data) != "") ? var.custom_data : null

  dynamic "identity" {
    for_each = var.identity_type == "SystemAssigned" ? [1] : []

    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.private_ip_address_allocation == "Dynamic"
      error_message = "private_ip_address_allocation must remain 'Dynamic' when deployment_mode is 'vmss'."
    }

    precondition {
      condition     = var.network_interfaces == null || length(var.network_interfaces) == 0
      error_message = "network_interfaces is currently supported only for deployment_mode = 'vm'."
    }

    precondition {
      condition     = try(trimspace(var.subnet_id), "") != ""
      error_message = "subnet_id must be set when deployment_mode is 'vmss'."
    }
  }
}

# =========================
# Autoscale (VMSS only)
# =========================

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  count               = var.deployment_mode == "vmss" && var.enable_autoscale ? 1 : 0
  name                = "${var.name}-autoscale"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss[0].id

  profile {
    name = "default"

    capacity {
      minimum = tostring(var.autoscale_min_instances)
      maximum = tostring(var.autoscale_max_instances)
      default = tostring(var.instance_count)
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss[0].id
        operator           = "GreaterThan"
        threshold          = var.autoscale_cpu_scale_out_threshold
        time_aggregation   = "Average"
        statistic          = "Average"
        time_window        = "PT5M"
        time_grain         = "PT1M"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = var.autoscale_cooldown
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss[0].id
        operator           = "LessThan"
        threshold          = var.autoscale_cpu_scale_in_threshold
        time_aggregation   = "Average"
        statistic          = "Average"
        time_window        = "PT5M"
        time_grain         = "PT1M"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = var.autoscale_cooldown
      }
    }
  }

  tags = var.tags
}
