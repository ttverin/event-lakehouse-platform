data "azurerm_client_config" "current" {}

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

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.function_name}-ai"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"

  lifecycle {
    ignore_changes = [workspace_id]
  }
}

resource "azurerm_user_assigned_identity" "func_identity" {
  name                = "${var.function_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_linux_function_app" "func" {
  name                = var.function_name
  location            = var.location
  resource_group_name = var.resource_group_name

  service_plan_id     = azurerm_service_plan.plan.id

  storage_account_name       = var.storage_account
  storage_account_access_key = var.storage_account_key

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.func_identity.id]
  }

  site_config {
    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    DATALAKE_ACCOUNT_NAME    = var.storage_account
    EVENTS_CONTAINER_NAME    = azurerm_storage_container.events.name
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app_insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app_insights.connection_string
    TICKETMASTER_API_KEY                 = var.ticketmaster_api_key
  }
}

resource "azurerm_role_assignment" "function_storage_access" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.func_identity.principal_id

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [principal_id]
  }
}

output "function_name" {
  value = azurerm_linux_function_app.func.name
}

output "application_insights_key" {
  value = azurerm_application_insights.app_insights.instrumentation_key
}

output "function_principal_id" {
  value = azurerm_user_assigned_identity.func_identity.principal_id
}