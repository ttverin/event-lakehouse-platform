output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.databricks.workspace_url
}

output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}