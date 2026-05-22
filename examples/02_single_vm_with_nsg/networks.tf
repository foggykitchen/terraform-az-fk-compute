module "vnet" {
  source = "github.com/foggykitchen/terraform-az-fk-vnet"

  name                = var.vnet_name
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  address_space = [var.vnet_address_space]
  subnets       = var.subnets

  tags = var.tags
}
