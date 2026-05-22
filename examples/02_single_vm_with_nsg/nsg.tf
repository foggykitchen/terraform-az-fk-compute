module "nsg" {
  source = "github.com/mlinxfeld/terraform-az-fk-nsg"

  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  rules = concat(
    [
      {
        name                       = "Allow-SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = var.ssh_source_cidrs
        destination_address_prefix = "*"
      }
    ],
    var.enable_http ? [
      {
        name                       = "Allow-HTTP"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ] : []
  )

  tags = var.tags
}
