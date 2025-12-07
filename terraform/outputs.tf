output "cluster_fqdn" {
  description = "FQDN for AKS control plane"
  value       = module.aks.cluster_fqdn
}

output "kubeconfig" {
  description = "Kubeconfig file for cluster access"
  value       = module.aks.kubeconfig
  sensitive   = true  
}

output "cluster_identity_client_id" {
  description = "Client ID of the managed identity for AKS"
  value       = module.aks.cluster_identity_client_id
}

# Azure OpenAI Module Outputs
output "openai_endpoint" {
  description = "Azure OpenAI endpoint URL for API calls"
  value       = module.openai.openai_endpoint
}

output "openai_api_key" {
  description = "Azure OpenAI API key (sensitive)"
  value       = module.openai.openai_api_key
  sensitive   = true
}

output "openai_log_analytics_workspace" {
  description = "Log Analytics workspace for OpenAI model logs"
  value       = module.openai.log_analytics_workspace_name
}

output "openai_storage_account" {
  description = "Storage account for OpenAI knowledge base data"
  value       = module.openai.storage_account_name
}

output "openai_deployment_models" {
  description = "List of deployed OpenAI models"
  value       = module.openai.deployment_models
}

output "openai_configuration_summary" {
  description = "Summary of Azure OpenAI configuration"
  value       = module.openai.configuration_summary
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

# Database Module Outputs
output "database_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = module.database.server_fqdn
}

output "database_name" {
  description = "Name of the database"
  value       = module.database.database_name
}

output "database_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = module.database.connection_string
  sensitive   = true
}

output "database_administrator_login" {
  description = "Database administrator username"
  value       = module.database.administrator_login
}

# Backend Storage Outputs
output "backend_storage_account_name" {
  description = "Name of the backend storage account"
  value       = var.create_backend_storage ? module.backend[0].storage_account_name : null
}

output "backend_storage_container_name" {
  description = "Name of the backend storage container"
  value       = var.create_backend_storage ? module.backend[0].storage_container_name : null
}

output "backend_config" {
  description = "Backend configuration for Terraform"
  value       = var.create_backend_storage ? module.backend[0].backend_config : null
}