module "loadbalancer" {
  source = "github.com/mlinxfeld/terraform-az-fk-loadbalancer"

  name                = "foggykitchen-lb"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  public_lb     = true
  public_ip_name = "foggykitchen-lb-public-ip"
  frontend_name = "PublicLBIP"

  backend_pool_name = "fk-backend-pool"

  probe = {
    name                = "http-probe"
    protocol            = "Tcp"
    port                = 80
    interval_in_seconds = 5
    number_of_probes    = 2
  }

  rule = {
    name          = "http"
    protocol      = "Tcp"
    frontend_port = 80
    backend_port  = 80
  }

  tags = var.tags
}
