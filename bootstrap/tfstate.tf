# Random suffix
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# Resource Group for Terraform state
variable "location" {
  type    = string
  default = "westeurope"
}

variable "project_name" {
  type    = string
  default = "eventhouse"
}

resource "azurerm_resource_group" "tfstate" {
  name     = "${var.project_name}-tfstate-rg"
  location = var.location
  tags = {
    Project = var.project_name
    Purpose = "Terraform state storage"
  }
}

# Storage Account for TF state
resource "azurerm_storage_account" "tfstate" {
  name                     = "${var.project_name}tfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Project = var.project_name
    Purpose = "Terraform state storage"
  }
}

# -----------------------
# Container inside storage account
# -----------------------
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id  = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# -----------------------
# Output backend info
# -----------------------
output "tfstate_resource_group" {
  value = azurerm_resource_group.tfstate.name
}

output "tfstate_storage_account" {
  value = azurerm_storage_account.tfstate.name
}

output "tfstate_container" {
  value = azurerm_storage_container.tfstate.name
}
