# Azure OpenAI Service Module for OpenWebUI Integration
# This module creates all necessary Azure OpenAI components for LLM model access

# Data source to get current Azure subscription
data "azurerm_client_config" "current" {}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Azure Cognitive Services Account (OpenAI)
resource "azurerm_cognitive_account" "openai" {
  name                = "${var.project_name}-openai-${random_id.suffix.hex}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = var.openai_sku

  custom_subdomain_name = "${var.project_name}-openai-${random_id.suffix.hex}"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Azure OpenAI Deployments
resource "azurerm_cognitive_deployment" "models" {
  for_each = { for model in var.deployment_models : model.name => model }

  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.openai.id
  
  model {
    format  = "OpenAI"
    name    = each.value.model
    version = each.value.version
  }
  
  sku {
    name     = "Standard"
    capacity = each.value.capacity != null ? each.value.capacity : 1
  }
  
  rai_policy_name = var.enable_content_filter ? "Microsoft.Default" : null
}

# Managed Identity for OpenWebUI Application
resource "azurerm_user_assigned_identity" "openwebui" {
  name                = "${var.project_name}-openwebui-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Role assignment for OpenAI access
resource "azurerm_role_assignment" "openai_contributor" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_user_assigned_identity.openwebui.principal_id
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "openai" {
  count               = var.enable_model_logging ? 1 : 0
  name                = "${var.project_name}-openai-logs-${random_id.suffix.hex}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Storage Account for Knowledge Base (RAG)
resource "azurerm_storage_account" "knowledge_base" {
  count                    = var.enable_cognitive_search ? 1 : 0
  name                     = "${replace(var.project_name, "-", "")}kb${random_id.suffix.hex}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = var.tags
}

# Storage Container for Knowledge Base
resource "azurerm_storage_container" "knowledge_base" {
  count                = var.enable_cognitive_search ? 1 : 0
  name                 = "knowledge-base"
  storage_account_name = azurerm_storage_account.knowledge_base[0].name
  container_access_type = "private"
}

# Azure Cognitive Search (for RAG)
resource "azurerm_search_service" "knowledge_base" {
  count               = var.enable_cognitive_search ? 1 : 0
  name                = "${var.project_name}-search-${random_id.suffix.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "standard"
  replica_count       = 1
  partition_count     = 1

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Role assignment for Cognitive Search
resource "azurerm_role_assignment" "search_contributor" {
  count                = var.enable_cognitive_search ? 1 : 0
  scope                = azurerm_search_service.knowledge_base[0].id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_user_assigned_identity.openwebui.principal_id
}

# Role assignment for Storage Account
resource "azurerm_role_assignment" "storage_contributor" {
  count                = var.enable_cognitive_search ? 1 : 0
  scope                = azurerm_storage_account.knowledge_base[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.openwebui.principal_id
}

# Private Endpoint for OpenAI (if VNet is specified)
resource "azurerm_private_endpoint" "openai" {
  count               = var.create_private_endpoints && var.vnet_id != null ? 1 : 0
  name                = "${var.project_name}-openai-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_ids[0]

  private_service_connection {
    name                           = "${var.project_name}-openai-psc"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for OpenAI
resource "azurerm_private_dns_zone" "openai" {
  count               = var.create_private_endpoints && var.vnet_id != null ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  count                 = var.create_private_endpoints && var.vnet_id != null ? 1 : 0
  name                  = "${var.project_name}-openai-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.openai[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = var.tags
}

# Private DNS Record for OpenAI
resource "azurerm_private_dns_a_record" "openai" {
  count               = var.create_private_endpoints && var.vnet_id != null ? 1 : 0
  name                = azurerm_cognitive_account.openai.custom_subdomain_name
  zone_name           = azurerm_private_dns_zone.openai[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.openai[0].private_ip_address]

  tags = var.tags
}

# Azure Monitor Action Group for Alerts
resource "azurerm_monitor_action_group" "openai" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-openai-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "openai"

  tags = var.tags
}

# Azure Monitor Metric Alert for API Errors
resource "azurerm_monitor_metric_alert" "openai_errors" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-openai-errors"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_cognitive_account.openai.id]
  description         = "Alert when OpenAI API errors exceed threshold"

  criteria {
    metric_namespace = "Microsoft.CognitiveServices/accounts"
    metric_name      = "TotalCalls"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.openai[0].id
  }

  tags = var.tags
}

# Diagnostic Settings for OpenAI
resource "azurerm_monitor_diagnostic_setting" "openai" {
  count                      = var.enable_model_logging ? 1 : 0
  name                       = "${var.project_name}-openai-diagnostics"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.openai[0].id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

