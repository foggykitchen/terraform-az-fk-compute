module "rbac" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-rbac.git?ref=v0.1.0"

  scope                = module.storage.storage_account_id
  principal_id         = module.compute.vm_principal_id
  role_definition_name = "Storage Blob Data Contributor"
}
