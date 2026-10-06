module "vnet" {
  source = "github.com/foggykitchen/terraform-az-fk-vnet"

  name                = "fk-app-gateway-vm-vnet"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  address_space       = ["10.70.0.0/16"]
  subnets             = var.subnets

}

module "natgw" {
  source = "github.com/foggykitchen/terraform-az-fk-natgw"

  name                = "fk-app-gateway-vm-natgw"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  public_ip_name      = "fk-app-gateway-vm-natgw-pip"
  subnet_associations = {
    compute = { subnet_id = module.vnet.subnet_ids["fk-subnet-private"] }
  }
}
