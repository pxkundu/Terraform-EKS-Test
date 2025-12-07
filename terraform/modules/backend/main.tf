# Backend Storage Account Module
# This module creates a storage account for Terraform state files following industry best practices

# Random suffix for unique storage account name
resource "random_id" "storage_suffix" {
  byte_length = 4
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "tfstate" {
  name                     = "${replace(var.project_name, "-", "")}tfstate${var.environment}${random_id.storage_suffix.hex}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "ZRS" # Zone-redundant storage for high availability
  min_tls_version          = "TLS1_2"

  # Enable versioning for state file recovery
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  # Network rules - restrict access
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ip_ranges
  }
  
  # HTTPS only is enabled by default
  # Public access is disabled by default

  tags = merge(var.tags, {
    Purpose = "TerraformState"
    Environment = var.environment
  })
}

# Storage Container for State Files
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Private Endpoint for Storage Account (optional, for enhanced security)
resource "azurerm_private_endpoint" "tfstate" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = "${var.project_name}-tfstate-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-tfstate-psc"
    private_connection_resource_id = azurerm_storage_account.tfstate.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for Storage Account
resource "azurerm_private_dns_zone" "blob" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.create_private_endpoint ? 1 : 0
  name                  = "${var.project_name}-blob-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id   = var.vnet_id
  registration_enabled  = false

  tags = var.tags
}

# Role Assignment for Storage Account Access (if using managed identity)
resource "azurerm_role_assignment" "tfstate_contributor" {
  count                = var.managed_identity_principal_id != null ? 1 : 0
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_principal_id
}

