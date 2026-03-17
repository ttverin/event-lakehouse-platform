terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.82.0"
    }
  }
}
data "azurerm_client_config" "current" {}

resource "azurerm_databricks_workspace" "workspace" {
  name                = var.workspace_name
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "premium"
}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.workspace.id
  azure_client_id             = data.azurerm_client_config.current.client_id
  azure_client_secret         = var.sp_client_secret
  azure_tenant_id             = data.azurerm_client_config.current.tenant_id
}

resource "databricks_cluster" "ticketmaster" {
  cluster_name            = "ticketmaster-cluster"
  spark_version           = "17.3.x-scala2.13"
  node_type_id            = "Standard_D4ds_v4"
  autotermination_minutes = 10
  num_workers             = 1
}

resource "databricks_secret_scope" "ticketmaster" {
  name = "ticketmaster-secrets"
}

resource "databricks_secret" "storage_key" {
  key          = "storage_account_key"
  string_value = var.storage_account_key
  scope        = databricks_secret_scope.ticketmaster.name
}

resource "databricks_secret" "ticketmaster_api_key" {
  key          = "ticketmaster_api_key"
  string_value = var.ticketmaster_api_key
  scope        = databricks_secret_scope.ticketmaster.name
}

resource "databricks_dbfs_file" "ingest" {
  source = "${path.module}/ingest_ticketmaster.py"
  path   = "/FileStore/code/ingest_ticketmaster.py"
}

resource "databricks_job" "ticketmaster_ingest" {
  name = "Ticketmaster Ingestion Daily"

  task {
    task_key = "ticketmaster_ingest_task"

    spark_python_task {
      python_file = "dbfs:/FileStore/code/ingest_ticketmaster.py"
    }

    new_cluster {
      spark_version           = "17.3.x-scala2.13"
      node_type_id            = "Standard_D4ds_v4"
      num_workers             = 1
    }
  }
}

output "workspace_name" {
  value = azurerm_databricks_workspace.workspace.name
}

output "workspace_id" {
  value = azurerm_databricks_workspace.workspace.id
}


