data "azurerm_client_config" "current" {}

module "storage" {
  source               = "./modules/storage"
  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
}

module "databricks" {
  source         = "./modules/databricks"
  workspace_name = "dbw-${var.project_name}-${var.environment}"
  resource_group = module.storage.resource_group_name
  location       = var.location
  project_name         = var.project_name
  environment          = var.environment
  storage_account_key  = module.storage.storage_account_key
  sp_client_secret     = var.sp_client_secret
}


module "functions" {
  source               = "./modules/functions"
  function_name        = "ticketmaster-ingest"
  resource_group_name  = module.storage.resource_group_name
  storage_account      = module.storage.storage_account_name
  storage_account_key  = module.storage.storage_account_key
  storage_account_id   = module.storage.storage_account_id
  location             = var.location
  ticketmaster_api_key = var.ticketmaster_api_key

}
