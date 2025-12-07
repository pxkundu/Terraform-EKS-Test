# Backend Configuration for Dev Environment
# This file configures Terraform to use Azure Storage Account for state management

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"  # Pre-created resource group for state
    storage_account_name = "tfstate<unique-suffix>"  # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
    
    # Optional: Enable state locking
    # Use Azure Blob Storage lease for state locking
  }
}

# Note: Before using this backend, you must:
# 1. Create the storage account and container manually, OR
# 2. Use the backend module in main.tf to create it first with local backend
# 3. Then migrate to this remote backend using: terraform init -migrate-state

