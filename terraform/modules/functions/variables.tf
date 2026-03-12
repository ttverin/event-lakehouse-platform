variable "function_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_account" {
  type = string
}

variable "storage_account_key" {
  type = string
}

variable "location" {
  type = string
}

variable "ticketmaster_api_key" {
  description = "Ticketmaster API key"
  type        = string
  sensitive   = true
}

variable "storage_account_id" {
  type = string
}