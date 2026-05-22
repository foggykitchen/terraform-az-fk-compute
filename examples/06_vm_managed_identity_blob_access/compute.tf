module "compute" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-compute.git?ref=v0.3.5"

  name                = var.vm_name
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  deployment_mode = "vm"
  subnet_id       = module.vnet.subnet_ids["fk-subnet"]
  identity_type   = "SystemAssigned"

  admin_username = var.admin_username
  ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  vm_size        = var.vm_size
  custom_data    = filebase64("${path.module}/cloud-init-blob-client.yaml")

  lb_attachment = null

  tags = var.tags
}
