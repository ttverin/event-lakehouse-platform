terraform {
  backend "azurerm" {
    resource_group_name  = "tf-state-rg"
    storage_account_name = "tfstateeventlake"
    container_name       = "tfstate"
    key                  = "databricks-platform.tfstate"
  }
}
