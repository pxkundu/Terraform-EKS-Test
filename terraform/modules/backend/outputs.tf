output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.tfstate.id
}

output "storage_container_name" {
  description = "Name of the storage container"
  value       = azurerm_storage_container.tfstate.name
}

output "storage_account_primary_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.tfstate.primary_access_key
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint for the storage account"
  value       = azurerm_storage_account.tfstate.primary_blob_endpoint
}

output "backend_config" {
  description = "Backend configuration for Terraform"
  value = {
    resource_group_name  = var.resource_group_name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = "${var.environment}/terraform.tfstate"
  }
}

