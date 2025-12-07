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
  description = "Virtual Network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the database (null for public access)"
  type        = string
  default     = null
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
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

variable "sku_name" {
  description = "SKU name for the database server (e.g., B_Standard_B1ms, GP_Standard_D2s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

variable "high_availability_mode" {
  description = "High availability mode (SameZone, ZoneRedundant, or null for disabled)"
  type        = string
  default     = null
}

variable "standby_availability_zone" {
  description = "Standby availability zone for HA"
  type        = string
  default     = null
}

variable "maintenance_day" {
  description = "Day of week for maintenance (0-6, Sunday=0)"
  type        = number
  default     = 0
}

variable "maintenance_hour" {
  description = "Hour of day for maintenance (0-23)"
  type        = number
  default     = 2
}

variable "database_charset" {
  description = "Database character set"
  type        = string
  default     = "UTF8"
}

variable "database_collation" {
  description = "Database collation"
  type        = string
  default     = "en_US.utf8"
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_cidrs" {
  description = "List of subnet CIDRs for firewall rules (must match allowed_subnet_ids)"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "Map of IP ranges allowed to access the database (key: name, value: {start_ip, end_ip})"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the database"
  type        = bool
  default     = false
}

variable "enable_aad_auth" {
  description = "Enable Azure AD authentication"
  type        = bool
  default     = true
}

variable "tenant_id" {
  description = "Azure tenant ID for AAD authentication"
  type        = string
}

variable "server_configurations" {
  description = "Map of PostgreSQL server configuration parameters"
  type        = map(string)
  default = {
    "shared_preload_libraries" = "pg_stat_statements"
    "log_statement"            = "all"
    "log_min_duration_statement" = "1000"
  }
}

variable "managed_identity_principal_id" {
  description = "Principal ID of managed identity for database access"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

