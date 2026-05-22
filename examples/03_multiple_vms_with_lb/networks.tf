module "vnet" {
  source = "github.com/foggykitchen/terraform-az-fk-vnet"

  name                = var.vnet_name
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  address_space = [var.vnet_address_space]
  subnets       = var.subnets

  tags = var.tags
}

module "natgw" {
  source = "github.com/mlinxfeld/terraform-az-fk-natgw"

  name                = "foggykitchen-natgw"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  public_ip_name = "foggykitchen-natgw-pip"

  subnet_associations = {
    private_subnet = {
      subnet_id = module.vnet.subnet_ids["fk-subnet-private"]
    }
  }

  tags = var.tags
}
