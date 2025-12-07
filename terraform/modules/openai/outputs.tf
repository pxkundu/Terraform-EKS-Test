output "openai_endpoint" {
  description = "Azure OpenAI endpoint URL"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_api_key" {
  description = "Azure OpenAI API key (primary)"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "openai_secondary_key" {
  description = "Azure OpenAI secondary API key"
  value       = azurerm_cognitive_account.openai.secondary_access_key
  sensitive   = true
}

output "openai_account_name" {
  description = "Name of the Azure OpenAI account"
  value       = azurerm_cognitive_account.openai.name
}

output "openwebui_identity_client_id" {
  description = "Client ID of the managed identity for OpenWebUI"
  value       = azurerm_user_assigned_identity.openwebui.client_id
}

output "openwebui_identity_principal_id" {
  description = "Principal ID of the managed identity for OpenWebUI"
  value       = azurerm_user_assigned_identity.openwebui.principal_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.enable_model_logging ? azurerm_log_analytics_workspace.openai[0].name : null
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.enable_model_logging ? azurerm_log_analytics_workspace.openai[0].id : null
}

output "storage_account_name" {
  description = "Name of the storage account for knowledge base"
  value       = var.enable_cognitive_search ? azurerm_storage_account.knowledge_base[0].name : null
}

output "storage_account_id" {
  description = "ID of the storage account for knowledge base"
  value       = var.enable_cognitive_search ? azurerm_storage_account.knowledge_base[0].id : null
}

output "cognitive_search_name" {
  description = "Name of the Cognitive Search service"
  value       = var.enable_cognitive_search ? azurerm_search_service.knowledge_base[0].name : null
}

output "cognitive_search_endpoint" {
  description = "Endpoint of the Cognitive Search service"
  value       = var.enable_cognitive_search ? azurerm_search_service.knowledge_base[0].primary_endpoint : null
}

output "deployment_models" {
  description = "List of deployed OpenAI models"
  value = {
    for k, v in azurerm_cognitive_deployment.models : k => {
      name    = v.name
      model   = v.model[0].name
      version = v.model[0].version
    }
  }
}

output "configuration_summary" {
  description = "Summary of Azure OpenAI configuration"
  value = {
    endpoint              = azurerm_cognitive_account.openai.endpoint
    account_name          = azurerm_cognitive_account.openai.name
    deployments           = length(azurerm_cognitive_deployment.models)
    cognitive_search      = var.enable_cognitive_search
    model_logging         = var.enable_model_logging
    monitoring            = var.enable_monitoring
    private_endpoints     = var.create_private_endpoints
  }
}

