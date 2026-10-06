output "deployment_mode" {
  value = var.deployment_mode
}

# -------- VM --------

output "vm_id" {
  value       = try(azurerm_linux_virtual_machine.vm[0].id, null)
  description = "VM resource ID"
}

output "vm_principal_id" {
  value       = try(azurerm_linux_virtual_machine.vm[0].identity[0].principal_id, null)
  description = "Principal ID of the VM managed identity"
}

output "vm_tenant_id" {
  value       = try(azurerm_linux_virtual_machine.vm[0].identity[0].tenant_id, null)
  description = "Tenant ID of the VM managed identity"
}

output "vm_private_ip" {
  value = (
    var.deployment_mode != "vm" ? null :
    local.use_multi_nic ? try(azurerm_network_interface.vm_multi_nic[local.primary_multi_nic_key].private_ip_address, null) :
    try(azurerm_network_interface.vm_nic[0].private_ip_address, null)
  )
  description = "Private IP address of the VM primary NIC"
}

output "vm_private_ips" {
  value = (
    var.deployment_mode != "vm" ? {} :
    local.use_multi_nic ? {
      for nic_key, nic in azurerm_network_interface.vm_multi_nic : nic_key => nic.private_ip_address
      } : {
      primary = try(azurerm_network_interface.vm_nic[0].private_ip_address, null)
    }
  )
  description = "Private IP addresses of the VM NICs"
}

output "vm_nic_ids" {
  value = (
    var.deployment_mode != "vm" ? {} :
    local.use_multi_nic ? {
      for nic_key, nic in azurerm_network_interface.vm_multi_nic : nic_key => nic.id
      } : {
      primary = try(azurerm_network_interface.vm_nic[0].id, null)
    }
  )
  description = "NIC IDs of the VM"
}

output "backend_nic_ids" {
  value = (
    var.deployment_mode != "vm" ? [] :
    local.use_multi_nic ? [for nic_key in local.ordered_multi_nic_keys : azurerm_network_interface.vm_multi_nic[nic_key].id] :
    [azurerm_network_interface.vm_nic[0].id]
  )
  description = "NIC IDs usable as LB backend targets"
}

# -------- VMSS --------

output "vmss_id" {
  value       = try(azurerm_linux_virtual_machine_scale_set.vmss[0].id, null)
  description = "VM Scale Set ID"
}

output "vmss_principal_id" {
  value       = try(azurerm_linux_virtual_machine_scale_set.vmss[0].identity[0].principal_id, null)
  description = "Principal ID of the VMSS managed identity"
}

output "vmss_tenant_id" {
  value       = try(azurerm_linux_virtual_machine_scale_set.vmss[0].identity[0].tenant_id, null)
  description = "Tenant ID of the VMSS managed identity"
}

output "autoscale_setting_id" {
  value       = try(azurerm_monitor_autoscale_setting.vmss_autoscale[0].id, null)
  description = "Autoscale setting ID (if enabled)"
}

output "attached_backend_pool_ids" {
  value = (
    var.lb_attachment != null ? [var.lb_attachment.backend_pool_id] : []
  )
  description = "Backend pool IDs this compute instance is attached to"
}

output "attached_app_gateway_backend_pool_ids" {
  value = (
    var.app_gateway_attachment != null ? [var.app_gateway_attachment.backend_pool_id] : []
  )
  description = "Application Gateway backend pool IDs this compute instance is attached to"
}
