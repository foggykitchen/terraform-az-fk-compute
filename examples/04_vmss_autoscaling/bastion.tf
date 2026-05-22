module "bastion" {
  source = "github.com/mlinxfeld/terraform-az-fk-bastion"

  name                = "foggykitchen-bastion"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  subnet_id = module.vnet.subnet_ids["AzureBastionSubnet"]

  sku                = "Standard"
  tunneling_enabled  = true
  ip_connect_enabled = true

  tags = var.tags
}
