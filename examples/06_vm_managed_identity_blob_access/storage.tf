module "storage" {
  source = "github.com/mlinxfeld/terraform-az-fk-storage"

  name                = "${var.storage_name_prefix}${random_string.suffix.result}"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true

  create_containers = true
  containers        = var.containers

  create_file_shares   = false
  enable_network_rules = false

  tags = var.tags
}
