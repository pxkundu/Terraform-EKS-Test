# Development Environment Configuration

# Azure Configuration
subscription_id = "your-subscription-id"
tenant_id       = "your-tenant-id"
location        = "eastus"

# Environment
environment = "dev"

# Network Configuration
vpc_name        = "aks-vnet-dev"
vpc_cidr        = ["10.0.0.0/16"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

# AKS Configuration
cluster_name    = "aks-cluster-dev"
cluster_version = "1.27"

# Backend Storage (set to true to create backend storage account)
create_backend_storage     = false
backend_private_endpoint   = false
backend_allowed_subnets    = []
backend_allowed_ips        = []

# Database Configuration
database_name                  = "appdb"
database_username              = "dbadmin"
database_password              = null  # Will generate random password if null
postgres_version               = "15"
database_sku                   = "B_Standard_B1ms"  # Burstable for dev
database_storage_mb             = 32768              # 32 GB
database_backup_retention_days  = 7
database_geo_redundant_backup   = false
database_allow_azure_services  = false

# Tags
tags = {
  Environment = "dev"
  Project     = "openwebui-azure"
  Team        = "platform"
  ManagedBy   = "terraform"
}
