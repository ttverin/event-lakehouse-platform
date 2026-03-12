# Function App Storage
resource "azurerm_storage_account" "function_storage" {
  name                     = "funcstorage${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

# App Service Plan
resource "azurerm_app_service_plan" "function_plan" {
  name                = "func-plan-${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Function App
resource "azurerm_linux_function_app" "event_ingest" {
  name                       = "event-ingest-${random_id.suffix.hex}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_app_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  https_only                 = true

  site_config {
    application_stack {
      node_version = "~18"  # Node.js 18 runtime
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
