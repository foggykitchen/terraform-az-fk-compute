module "app_gateway" {
  source                = "git::https://github.com/foggykitchen/terraform-az-fk-application-gateway.git?ref=v0.1.2"
  name                  = "fk-app-gateway"
  location              = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name   = azurerm_resource_group.foggykitchen_rg.name
  gateway_subnet_id     = module.vnet.subnet_ids["fk-subnet-app-gateway"]
  public_ip_id          = module.gateway_public_ip.id
  frontend_ports        = { http = { port = 80 } }
  backend_address_pools = { web = {} }
  backend_http_settings = { web = { port = 80, protocol = "Http", probe_key = "web" } }
  probes                = { web = { protocol = "Http", path = "/", host = "localhost" } }
  http_listeners        = { http = { frontend_port_key = "http", protocol = "Http" } }
  request_routing_rules = {
    web = {
      priority                  = 100
      rule_type                 = "Basic"
      http_listener_key         = "http"
      backend_address_pool_key  = "web"
      backend_http_settings_key = "web"
    }
  }
}
