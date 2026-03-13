variable "workspace_name" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "storage_account_key" {
  type = string
}

variable "sp_client_secret" {
  type      = string
  sensitive = true
}
