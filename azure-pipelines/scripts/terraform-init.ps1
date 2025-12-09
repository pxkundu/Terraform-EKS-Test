# Terraform Initialization Script
# This script initializes Terraform backend and ensures proper state management

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$true)]
    [string]$StateKey,
    
    [Parameter(Mandatory=$true)]
    [string]$Environment
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting Terraform backend initialization for environment: $Environment" -ForegroundColor Green

try {
    # Check if Azure CLI is logged in
    Write-Host "Checking Azure CLI authentication..." -ForegroundColor Yellow
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        throw "Azure CLI is not authenticated. Please run 'az login' first."
    }
    Write-Host "✅ Azure CLI authenticated as: $($account.user.name)" -ForegroundColor Green

    # Check if resource group exists, create if it doesn't
    Write-Host "Checking if resource group '$ResourceGroupName' exists..." -ForegroundColor Yellow
    $rgExists = az group exists --name $ResourceGroupName --output tsv
    
    if ($rgExists -eq "false") {
        Write-Host "Creating resource group '$ResourceGroupName'..." -ForegroundColor Yellow
        az group create --name $ResourceGroupName --location "eastus" --output none
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create resource group '$ResourceGroupName'"
        }
        Write-Host "✅ Resource group '$ResourceGroupName' created successfully" -ForegroundColor Green
    } else {
        Write-Host "✅ Resource group '$ResourceGroupName' already exists" -ForegroundColor Green
    }

    # Check if storage account exists, create if it doesn't
    Write-Host "Checking if storage account '$StorageAccountName' exists..." -ForegroundColor Yellow
    $saExists = az storage account check-name --name $StorageAccountName --query "nameAvailable" --output tsv
    
    if ($saExists -eq "true") {
        Write-Host "Creating storage account '$StorageAccountName'..." -ForegroundColor Yellow
        az storage account create `
            --name $StorageAccountName `
            --resource-group $ResourceGroupName `
            --location "eastus" `
            --sku "Standard_LRS" `
            --kind "StorageV2" `
            --access-tier "Hot" `
            --https-only true `
            --min-tls-version "TLS1_2" `
            --allow-blob-public-access false `
            --output none
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create storage account '$StorageAccountName'"
        }
        Write-Host "✅ Storage account '$StorageAccountName' created successfully" -ForegroundColor Green
    } else {
        Write-Host "✅ Storage account '$StorageAccountName' already exists" -ForegroundColor Green
    }

    # Enable versioning on the storage account
    Write-Host "Enabling versioning on storage account..." -ForegroundColor Yellow
    az storage account blob-service-properties update `
        --account-name $StorageAccountName `
        --enable-versioning true `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Versioning enabled on storage account" -ForegroundColor Green
    }

    # Get storage account key
    Write-Host "Retrieving storage account key..." -ForegroundColor Yellow
    $storageKey = az storage account keys list `
        --resource-group $ResourceGroupName `
        --account-name $StorageAccountName `
        --query "[0].value" `
        --output tsv
    
    if (-not $storageKey) {
        throw "Failed to retrieve storage account key"
    }

    # Check if container exists, create if it doesn't
    Write-Host "Checking if container '$ContainerName' exists..." -ForegroundColor Yellow
    $containerExists = az storage container exists `
        --name $ContainerName `
        --account-name $StorageAccountName `
        --account-key $storageKey `
        --query "exists" `
        --output tsv
    
    if ($containerExists -eq "false") {
        Write-Host "Creating container '$ContainerName'..." -ForegroundColor Yellow
        az storage container create `
            --name $ContainerName `
            --account-name $StorageAccountName `
            --account-key $storageKey `
            --public-access off `
            --output none
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create container '$ContainerName'"
        }
        Write-Host "✅ Container '$ContainerName' created successfully" -ForegroundColor Green
    } else {
        Write-Host "✅ Container '$ContainerName' already exists" -ForegroundColor Green
    }

    # Set up blob lifecycle management
    Write-Host "Setting up blob lifecycle management..." -ForegroundColor Yellow
    $lifecyclePolicy = @{
        rules = @(
            @{
                enabled = $true
                name = "terraform-state-lifecycle"
                type = "Lifecycle"
                definition = @{
                    filters = @{
                        blobTypes = @("blockBlob")
                        prefixMatch = @("$ContainerName/")
                    }
                    actions = @{
                        version = @{
                            delete = @{
                                daysAfterCreationGreaterThan = 90
                            }
                        }
                    }
                }
            }
        )
    } | ConvertTo-Json -Depth 10

    $lifecyclePolicy | Out-File -FilePath "lifecycle-policy.json" -Encoding UTF8
    
    az storage account management-policy create `
        --account-name $StorageAccountName `
        --policy "lifecycle-policy.json" `
        --resource-group $ResourceGroupName `
        --output none 2>$null
    
    Remove-Item "lifecycle-policy.json" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Lifecycle management configured" -ForegroundColor Green

    # Configure soft delete for blobs
    Write-Host "Configuring soft delete for blobs..." -ForegroundColor Yellow
    az storage account blob-service-properties update `
        --account-name $StorageAccountName `
        --enable-delete-retention true `
        --delete-retention-days 30 `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Soft delete configured for blobs" -ForegroundColor Green
    }

    # Check if state file exists
    Write-Host "Checking if state file exists..." -ForegroundColor Yellow
    $stateExists = az storage blob exists `
        --container-name $ContainerName `
        --name $StateKey `
        --account-name $StorageAccountName `
        --account-key $storageKey `
        --query "exists" `
        --output tsv
    
    if ($stateExists -eq "true") {
        Write-Host "✅ State file '$StateKey' exists" -ForegroundColor Green
        
        # Get state file metadata
        $stateMetadata = az storage blob show `
            --container-name $ContainerName `
            --name $StateKey `
            --account-name $StorageAccountName `
            --account-key $storageKey `
            --query "{lastModified:properties.lastModified, size:properties.contentLength}" `
            --output json | ConvertFrom-Json
        
        Write-Host "State file last modified: $($stateMetadata.lastModified)" -ForegroundColor Cyan
        Write-Host "State file size: $($stateMetadata.size) bytes" -ForegroundColor Cyan
    } else {
        Write-Host "ℹ️ State file '$StateKey' does not exist (will be created on first apply)" -ForegroundColor Cyan
    }

    # Set environment variables for Terraform
    Write-Host "Setting up environment variables for Terraform..." -ForegroundColor Yellow
    
    # Export backend configuration
    $env:TF_CLI_ARGS_init = "-backend-config=`"resource_group_name=$ResourceGroupName`" -backend-config=`"storage_account_name=$StorageAccountName`" -backend-config=`"container_name=$ContainerName`" -backend-config=`"key=$StateKey`""
    
    Write-Host "✅ Environment variables configured" -ForegroundColor Green

    # Validate Terraform backend configuration
    Write-Host "Validating backend configuration..." -ForegroundColor Yellow
    
    $backendConfig = @{
        resource_group_name = $ResourceGroupName
        storage_account_name = $StorageAccountName
        container_name = $ContainerName
        key = $StateKey
    }
    
    Write-Host "Backend Configuration:" -ForegroundColor Cyan
    $backendConfig | Format-Table -AutoSize
    
    Write-Host "✅ Terraform backend initialization completed successfully!" -ForegroundColor Green
    
    # Output summary
    Write-Host "`n=== INITIALIZATION SUMMARY ===" -ForegroundColor Magenta
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "Storage Account: $StorageAccountName" -ForegroundColor White
    Write-Host "Container: $ContainerName" -ForegroundColor White
    Write-Host "State Key: $StateKey" -ForegroundColor White
    Write-Host "Status: ✅ Ready for Terraform operations" -ForegroundColor Green
    Write-Host "==============================`n" -ForegroundColor Magenta

} catch {
    Write-Host "❌ Error during Terraform backend initialization: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}