data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "${var.project_name}st${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_account_key" {
  value = azurerm_storage_account.storage.primary_access_key
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}
