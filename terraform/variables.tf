variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "eventhouse"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Deployment environment (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Project owner"
  type        = string
  default     = "teemu.tverin@zuhlke.com"
}

variable "ticketmaster_api_key" {
  description = "Ticketmaster API key"
  type        = string
  sensitive   = true
}