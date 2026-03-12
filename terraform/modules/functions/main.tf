resource "azurerm_service_plan" "plan" {
  name                = "${var.function_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
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
  }
}

output "function_name" {
  value = azurerm_linux_function_app.func.name
}
