resource "azurerm_databricks_workspace" "workspace" {
  name                = var.workspace_name
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "standard"
}

output "workspace_name" {
  value = azurerm_databricks_workspace.workspace.name
}

output "workspace_id" {
  value = azurerm_databricks_workspace.workspace.id
}


