# Azure Database for PostgreSQL Module
# This module creates a managed PostgreSQL database following industry best practices

# Random password for database (if not provided)
resource "random_password" "db_password" {
  count   = var.db_password == null ? 1 : 0
  length  = 32
  special = true
}

# PostgreSQL Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-postgres-${var.environment}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgres_version
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres[0].id
  administrator_login    = var.db_username
  administrator_password = var.db_password != null ? var.db_password : random_password.db_password[0].result

  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup

  # High availability configuration (only if mode is specified)
  dynamic "high_availability" {
    for_each = var.high_availability_mode != null ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Maintenance window
  maintenance_window {
    day_of_week  = var.maintenance_day
    start_hour   = var.maintenance_hour
    start_minute = 0
  }

  # Authentication
  authentication {
    active_directory_auth_enabled = var.enable_aad_auth
    password_auth_enabled         = true
    tenant_id                     = var.tenant_id
  }

  tags = var.tags
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  count               = var.subnet_id != null ? 1 : 0
  name                = "${var.project_name}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = var.subnet_id != null ? 1 : 0
  name                  = "${var.project_name}-postgres-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = var.tags
}

# Private Endpoint for PostgreSQL (if subnet is provided)
resource "azurerm_private_endpoint" "postgres" {
  count               = var.subnet_id != null ? 1 : 0
  name                = "${var.project_name}-postgres-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.project_name}-postgres-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.main.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = var.database_charset
  collation = var.database_collation
}

# Firewall Rules
resource "azurerm_postgresql_flexible_server_firewall_rule" "aks" {
  count            = length(var.allowed_subnet_ids) > 0 ? length(var.allowed_subnet_ids) : 0
  name             = "aks-subnet-${count.index}"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = cidrhost(var.allowed_subnet_cidrs[count.index], 0)
  end_ip_address   = cidrhost(var.allowed_subnet_cidrs[count.index], -1)
}

# Firewall Rule for Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  count            = var.allow_azure_services ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Firewall Rule for specific IPs
resource "azurerm_postgresql_flexible_server_firewall_rule" "custom" {
  for_each         = var.allowed_ip_ranges
  name             = "custom-${replace(each.key, ".", "-")}"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

# Configuration Parameters
resource "azurerm_postgresql_flexible_server_configuration" "main" {
  for_each  = var.server_configurations
  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}

# Role Assignment for Managed Identity (if AKS needs access)
resource "azurerm_role_assignment" "postgres_contributor" {
  count                = var.managed_identity_principal_id != null ? 1 : 0
  scope                = azurerm_postgresql_flexible_server.main.id
  role_definition_name = "Contributor"
  principal_id         = var.managed_identity_principal_id
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "postgres" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.project_name}-postgres-diagnostics"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

