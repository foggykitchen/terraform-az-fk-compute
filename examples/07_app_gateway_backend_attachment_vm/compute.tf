module "compute" {
  source                        = "../.."
  name                          = "fk-web-vm"
  location                      = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name           = azurerm_resource_group.foggykitchen_rg.name
  deployment_mode               = "vm"
  subnet_id                     = module.vnet.subnet_ids["fk-subnet-private"]
  ssh_public_key                = var.ssh_public_key
  private_ip_address_allocation = "Static"
  private_ip_address            = "10.70.1.4"
  vm_size                       = var.vm_size
  app_gateway_attachment = {
    backend_pool_id = module.app_gateway.backend_address_pool_ids["web"]
  }
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable --now nginx
    EOF
  )
}
