# output "databricks_workspace_url" {
#   value = azurerm_databricks_workspace.databricks.workspace_url
# }
#
# output "storage_account_name" {
#   value = azurerm_storage_account.datalake.name
# }

output "tenant_id" {
  description = "Azure Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Azure Subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
}