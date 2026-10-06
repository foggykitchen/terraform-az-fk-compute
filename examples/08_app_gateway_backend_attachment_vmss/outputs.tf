output "attached_app_gateway_backend_pool_ids" {
  value = module.compute.attached_app_gateway_backend_pool_ids
}
output "compute_id" {
  value = module.compute.vmss_id
}
output "gateway_public_ip" {
  value = module.gateway_public_ip.ip_address
}

output "nsg_id" {
  value = module.nsg.id
}

output "resource_group_name" {
  value = azurerm_resource_group.foggykitchen_rg.name
}
