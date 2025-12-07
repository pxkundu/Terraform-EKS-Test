variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region/location"
  type        = string
  default     = "eastus"
}

variable "vpc_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "aks-vnet"
}

variable "vpc_cidr" {
  description = "CIDR blocks for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "my-aks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.27"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# Backend Storage Configuration
variable "create_backend_storage" {
  description = "Create backend storage account for Terraform state"
  type        = bool
  default     = false
}

variable "backend_private_endpoint" {
  description = "Create private endpoint for backend storage account"
  type        = bool
  default     = false
}

variable "backend_allowed_subnets" {
  description = "List of subnet IDs allowed to access backend storage"
  type        = list(string)
  default     = []
}

variable "backend_allowed_ips" {
  description = "List of IP ranges allowed to access backend storage"
  type        = list(string)
  default     = []
}

# Database Configuration
variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "database_username" {
  description = "Database administrator username"
  type        = string
  default     = "dbadmin"
}

variable "database_password" {
  description = "Database administrator password (if null, random password will be generated)"
  type        = string
  default     = null
  sensitive   = true
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "database_sku" {
  description = "SKU name for the database server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "database_storage_mb" {
  description = "Storage size in MB for the database"
  type        = number
  default     = 32768
}

variable "database_backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "database_geo_redundant_backup" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

variable "database_allow_azure_services" {
  description = "Allow Azure services to access the database"
  type        = bool
  default     = false
}
