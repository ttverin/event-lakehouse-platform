terraform {
  backend "azurerm" {
    resource_group_name  = "eventhouse-tfstate-rg"
    storage_account_name = "eventhousetfstatejkrgh"
    container_name       = "tfstate"
    key                  = "databricks-platform.tfstate"
  }
}