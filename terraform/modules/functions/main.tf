resource "azurerm_service_plan" "plan" {
  name                = "${var.function_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_storage_container" "events" {
  name                  = "events"
  storage_account_name    = var.storage_account
  container_access_type = "private"
}

resource "azurerm_linux_function_app" "func" {
  name                = var.function_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id

  storage_account_name       = var.storage_account
  storage_account_access_key = var.storage_account_key

  site_config {
    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    DATALAKE_ACCOUNT_NAME    = var.storage_account
    EVENTS_CONTAINER_NAME    = azurerm_storage_container.events.name
  }
}

output "function_name" {
  value = azurerm_linux_function_app.func.name
}
