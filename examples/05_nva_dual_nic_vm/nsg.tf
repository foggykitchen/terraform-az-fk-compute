module "nsg_inside" {
  source = "github.com/mlinxfeld/terraform-az-fk-nsg"

  name                = "${var.nva_vm_name}-inside-nsg"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  rules = [
    {
      name                       = "allow-ssh-from-inside-cidrs"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes    = var.inside_ssh_source_cidrs
      destination_address_prefix = "*"
    }
  ]

  tags = var.tags
}

module "nsg_outside" {
  source = "github.com/mlinxfeld/terraform-az-fk-nsg"

  name                = "${var.nva_vm_name}-outside-nsg"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  rules = [
    {
      name                       = "allow-ssh-from-outside-cidrs"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes    = var.outside_ssh_source_cidrs
      destination_address_prefix = "*"
    }
  ]

  tags = var.tags
}
