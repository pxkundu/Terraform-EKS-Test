# Backend Configuration for Staging Environment

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<unique-suffix>"  # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "staging/terraform.tfstate"
  }
}

