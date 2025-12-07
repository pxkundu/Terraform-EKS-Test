variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region/location"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vnet_id" {
  description = "Virtual Network ID for private endpoint"
  type        = string
  default     = null
}

variable "private_subnet_id" {
  description = "Private subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access storage account"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access storage account"
  type        = list(string)
  default     = []
}

variable "create_private_endpoint" {
  description = "Create private endpoint for storage account"
  type        = bool
  default     = false
}

variable "managed_identity_principal_id" {
  description = "Principal ID of managed identity for storage access"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

