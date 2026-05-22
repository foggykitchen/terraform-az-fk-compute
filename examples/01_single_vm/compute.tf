module "compute" {
  source = "github.com/mlinxfeld/terraform-az-fk-compute"

  name                = var.vm_name
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  deployment_mode = "vm"
  subnet_id        = module.vnet.subnet_ids["fk-subnet-public"]

  admin_username = var.admin_username
  ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  vm_size        = var.vm_size

  # LB not used in this example
  lb_attachment = null

  tags = var.tags
}
