module "nsg" {
  source = "github.com/foggykitchen/terraform-az-fk-nsg"

  name                = "fk-private-subnet-nsg"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  rules = [
    {
      name                       = "allow-http-from-app-gateway"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefixes    = module.vnet.subnet_address_prefixes["fk-subnet-app-gateway"]
      destination_address_prefix = "*"
    },
    {
      name                       = "deny-other-inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  subnet_associations = {
    compute = { subnet_id = module.vnet.subnet_ids["fk-subnet-private"] }
  }
}
