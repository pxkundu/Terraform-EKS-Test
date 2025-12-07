# Terraform Backend Setup Guide

## Overview

This guide explains how to set up and configure the remote backend for Terraform state management using Azure Storage Account, following industry best practices.

## Architecture

The backend configuration uses:
- **Azure Storage Account**: Stores Terraform state files
- **Blob Container**: Organized by environment (dev, staging, prod)
- **State Locking**: Automatic locking via Azure Blob Storage leases
- **Versioning**: Enabled for state file recovery
- **Encryption**: At rest and in transit
- **Private Endpoints**: Optional for enhanced security

## Best Practices Implemented

1. **Environment Isolation**: Separate state files per environment
2. **State Locking**: Prevents concurrent modifications
3. **Versioning**: Enables state file recovery
4. **Access Control**: Network rules and RBAC
5. **Encryption**: TLS 1.2+ and encryption at rest
6. **Backup**: Soft delete and retention policies

## Setup Steps

### Option 1: Manual Setup (Recommended for Production)

1. **Create Resource Group for State**:
   ```bash
   az group create \
     --name terraform-state-rg \
     --location eastus
   ```

2. **Create Storage Account**:
   ```bash
   # Generate unique name (storage account names must be globally unique)
   STORAGE_NAME="tfstate$(openssl rand -hex 4)"
   
   az storage account create \
     --name $STORAGE_NAME \
     --resource-group terraform-state-rg \
     --location eastus \
     --sku Standard_ZRS \
     --kind StorageV2 \
     --min-tls-version TLS1_2
   ```

3. **Enable Versioning and Soft Delete**:
   ```bash
   az storage account blob-service-properties update \
     --account-name $STORAGE_NAME \
     --resource-group terraform-state-rg \
     --enable-versioning true \
     --enable-delete-retention true \
     --delete-retention-days 30 \
     --enable-container-delete-retention true \
     --container-delete-retention-days 30
   ```

4. **Create Container**:
   ```bash
   az storage container create \
     --name tfstate \
     --account-name $STORAGE_NAME \
     --auth-mode login
   ```

5. **Configure Backend**:
   Edit `environments/<env>/backend.tf`:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "terraform-state-rg"
       storage_account_name = "<your-storage-account-name>"
       container_name       = "tfstate"
       key                  = "<environment>/terraform.tfstate"
     }
   }
   ```

6. **Initialize Terraform**:
   ```bash
   cd environments/<env>
   terraform init
   ```

### Option 2: Automated Setup (Using Terraform Module)

1. **Initial Deployment with Local Backend**:
   ```bash
   # First, deploy with local backend to create the storage account
   terraform init
   terraform apply -target=module.backend
   ```

2. **Get Storage Account Details**:
   ```bash
   terraform output backend_config
   ```

3. **Update Backend Configuration**:
   Edit `environments/<env>/backend.tf` with the output values

4. **Migrate State**:
   ```bash
   terraform init -migrate-state
   ```

## Environment-Specific Configuration

### Development Environment

File: `environments/dev/backend.tf`
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<unique-suffix>"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
```

### Staging Environment

File: `environments/staging/backend.tf`
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<unique-suffix>"
    container_name       = "tfstate"
    key                  = "staging/terraform.tfstate"
  }
}
```

### Production Environment

File: `environments/prod/backend.tf`
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<unique-suffix>"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}
```

## Security Configuration

### Network Rules

Restrict access to the storage account:

```bash
# Allow specific subnets
az storage account network-rule add \
  --account-name <storage-account-name> \
  --subnet <subnet-id>

# Allow specific IPs
az storage account network-rule add \
  --account-name <storage-account-name> \
  --ip-address <ip-address>
```

### Private Endpoints

For enhanced security, use private endpoints:

```hcl
# In main.tf, set:
variable "backend_private_endpoint" {
  default = true
}
```

### Access Control

Use managed identities for access:

```bash
# Assign Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee <principal-id> \
  --scope /subscriptions/<sub-id>/resourceGroups/terraform-state-rg/providers/Microsoft.Storage/storageAccounts/<storage-account-name>
```

## State File Structure

```
tfstate/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

## Troubleshooting

### Issue: State Lock Error

**Problem**: State is locked by another process

**Solution**:
```bash
# Check for locks
az storage blob show \
  --account-name <storage-account-name> \
  --container-name tfstate \
  --name <environment>/terraform.tfstate

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: Access Denied

**Problem**: Cannot access storage account

**Solution**:
1. Check network rules
2. Verify RBAC permissions
3. Check if private endpoint is configured correctly

### Issue: State File Not Found

**Problem**: State file doesn't exist

**Solution**:
1. Verify backend configuration
2. Check container and key names
3. Ensure storage account exists

## Migration from Local to Remote Backend

1. **Backup Local State**:
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

2. **Configure Remote Backend**:
   Edit `backend.tf` with remote configuration

3. **Initialize and Migrate**:
   ```bash
   terraform init -migrate-state
   ```

4. **Verify Migration**:
   ```bash
   terraform state list
   ```

5. **Remove Local State** (after verification):
   ```bash
   rm terraform.tfstate terraform.tfstate.backup
   ```

## Best Practices

1. **Never Commit State Files**: Add to `.gitignore`
2. **Use Separate Storage Accounts**: Per environment or organization
3. **Enable Versioning**: For state recovery
4. **Regular Backups**: Export state files periodically
5. **Access Control**: Use RBAC and network rules
6. **Monitor Access**: Enable diagnostic logging
7. **State Locking**: Always enabled (default)
8. **Encryption**: Always enabled (default)

## Cost Considerations

- **Storage Account**: ~$0.0184/GB/month
- **Transactions**: ~$0.004 per 10,000 operations
- **Data Transfer**: Free within same region

**Estimated Cost**: ~$1-5/month for typical usage

## Additional Resources

- [Terraform Azure Backend Documentation](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [Azure Storage Best Practices](https://docs.microsoft.com/azure/storage/common/storage-security-guide)
- [State Management Best Practices](https://www.terraform.io/docs/language/state/index.html)

---

**Last Updated**: 2024  
**Version**: 1.0

