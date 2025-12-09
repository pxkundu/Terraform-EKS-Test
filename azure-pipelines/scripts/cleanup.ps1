# Infrastructure Cleanup Script
# This script performs cleanup operations for Azure infrastructure resources

param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string[]]$ExcludeResources = @(),
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 7
)

# Set error action preference
$ErrorActionPreference = "Continue"

Write-Host "Starting infrastructure cleanup for environment: $Environment" -ForegroundColor Green

# Initialize cleanup results
$cleanupResults = @{
    Environment = $Environment
    ResourceGroup = $ResourceGroupName
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    DryRun = $DryRun.IsPresent
    Actions = @()
    Summary = @{
        ResourcesScanned = 0
        ResourcesToDelete = 0
        ResourcesDeleted = 0
        ResourcesSkipped = 0
        Errors = 0
    }
}

function Write-CleanupAction {
    param(
        [string]$Action,
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$Status,
        [string]$Reason = "",
        [string]$Details = ""
    )
    
    $color = switch ($Status) {
        "DELETED" { "Green" }
        "SKIPPED" { "Yellow" }
        "ERROR" { "Red" }
        "PLANNED" { "Cyan" }
        default { "White" }
    }
    
    $message = "[$Status] $Action - $ResourceType '$ResourceName'"
    if ($Reason) {
        $message += " - $Reason"
    }
    
    Write-Host $message -ForegroundColor $color
    if ($Details) {
        Write-Host "    Details: $Details" -ForegroundColor Gray
    }
    
    $cleanupResults.Actions += @{
        Action = $Action
        ResourceType = $ResourceType
        ResourceName = $ResourceName
        Status = $Status
        Reason = $Reason
        Details = $Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
}

try {
    # 1. Authentication Check
    Write-Host "`n=== AUTHENTICATION CHECK ===" -ForegroundColor Magenta
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        throw "Azure CLI is not authenticated. Please run 'az login' first."
    }
    Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green

    # 2. Resource Group Validation
    Write-Host "`n=== RESOURCE GROUP VALIDATION ===" -ForegroundColor Magenta
    $rg = az group show --name $ResourceGroupName --output json 2>$null | ConvertFrom-Json
    if (-not $rg) {
        Write-Host "⚠️ Resource group '$ResourceGroupName' not found. Nothing to clean up." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "✅ Resource group '$ResourceGroupName' found" -ForegroundColor Green

    # 3. Get all resources in the resource group
    Write-Host "`n=== SCANNING RESOURCES ===" -ForegroundColor Magenta
    $resources = az resource list --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
    
    if (-not $resources -or $resources.Count -eq 0) {
        Write-Host "ℹ️ No resources found in resource group '$ResourceGroupName'" -ForegroundColor Cyan
        exit 0
    }
    
    $cleanupResults.Summary.ResourcesScanned = $resources.Count
    Write-Host "Found $($resources.Count) resources to evaluate" -ForegroundColor Cyan

    # 4. Analyze resources for cleanup
    Write-Host "`n=== ANALYZING RESOURCES FOR CLEANUP ===" -ForegroundColor Magenta
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    Write-Host "Retention cutoff date: $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    
    foreach ($resource in $resources) {
        $resourceName = $resource.name
        $resourceType = $resource.type
        $resourceId = $resource.id
        
        # Skip excluded resources
        if ($ExcludeResources -contains $resourceName -or $ExcludeResources -contains $resourceType) {
            Write-CleanupAction "EVALUATE" $resourceType $resourceName "SKIPPED" "Resource excluded from cleanup"
            $cleanupResults.Summary.ResourcesSkipped++
            continue
        }
        
        # Skip critical resources based on type
        $criticalResourceTypes = @(
            "Microsoft.KeyVault/vaults",
            "Microsoft.Storage/storageAccounts",
            "Microsoft.ContainerService/managedClusters"
        )
        
        if ($criticalResourceTypes -contains $resourceType -and -not $Force) {
            Write-CleanupAction "EVALUATE" $resourceType $resourceName "SKIPPED" "Critical resource type (use -Force to override)"
            $cleanupResults.Summary.ResourcesSkipped++
            continue
        }
        
        # Check resource age and usage
        try {
            $resourceDetails = az resource show --ids $resourceId --output json 2>$null | ConvertFrom-Json
            
            # Determine if resource should be cleaned up
            $shouldCleanup = $false
            $reason = ""
            
            # Check for specific cleanup criteria based on resource type
            switch ($resourceType) {
                "Microsoft.Compute/disks" {
                    if ($resourceDetails.properties.diskState -eq "Unattached") {
                        $shouldCleanup = $true
                        $reason = "Unattached disk"
                    }
                }
                "Microsoft.Network/publicIPAddresses" {
                    if (-not $resourceDetails.properties.ipConfiguration) {
                        $shouldCleanup = $true
                        $reason = "Unused public IP"
                    }
                }
                "Microsoft.Network/networkInterfaces" {
                    if (-not $resourceDetails.properties.virtualMachine) {
                        $shouldCleanup = $true
                        $reason = "Unused network interface"
                    }
                }
                "Microsoft.Network/networkSecurityGroups" {
                    if (-not $resourceDetails.properties.subnets -and -not $resourceDetails.properties.networkInterfaces) {
                        $shouldCleanup = $true
                        $reason = "Unused network security group"
                    }
                }
                "Microsoft.Insights/components" {
                    # Check if Application Insights is older than retention period
                    if ($resourceDetails.properties.creationDate) {
                        $creationDate = [DateTime]::Parse($resourceDetails.properties.creationDate)
                        if ($creationDate -lt $cutoffDate) {
                            $shouldCleanup = $true
                            $reason = "Older than retention period"
                        }
                    }
                }
                default {
                    # For other resources, check tags or creation time if available
                    if ($resourceDetails.tags -and $resourceDetails.tags.environment -eq "temp") {
                        $shouldCleanup = $true
                        $reason = "Temporary resource (tagged)"
                    }
                }
            }
            
            # Special handling for development environment
            if ($Environment -eq "dev" -and -not $shouldCleanup) {
                # In dev environment, be more aggressive with cleanup
                if ($resourceDetails.tags -and $resourceDetails.tags.autoCleanup -eq "true") {
                    $shouldCleanup = $true
                    $reason = "Auto-cleanup enabled"
                }
            }
            
            if ($shouldCleanup) {
                $cleanupResults.Summary.ResourcesToDelete++
                
                if ($DryRun) {
                    Write-CleanupAction "DELETE" $resourceType $resourceName "PLANNED" $reason
                } else {
                    # Perform actual deletion
                    Write-Host "Deleting $resourceType '$resourceName'..." -ForegroundColor Yellow
                    
                    $deleteResult = az resource delete --ids $resourceId --output none 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-CleanupAction "DELETE" $resourceType $resourceName "DELETED" $reason
                        $cleanupResults.Summary.ResourcesDeleted++
                    } else {
                        Write-CleanupAction "DELETE" $resourceType $resourceName "ERROR" "Deletion failed" $deleteResult
                        $cleanupResults.Summary.Errors++
                    }
                }
            } else {
                Write-CleanupAction "EVALUATE" $resourceType $resourceName "SKIPPED" "Resource in use or protected"
                $cleanupResults.Summary.ResourcesSkipped++
            }
            
        } catch {
            Write-CleanupAction "EVALUATE" $resourceType $resourceName "ERROR" "Failed to analyze resource" $_.Exception.Message
            $cleanupResults.Summary.Errors++
        }
    }

    # 5. Clean up old deployments
    Write-Host "`n=== CLEANING UP OLD DEPLOYMENTS ===" -ForegroundColor Magenta
    try {
        $deployments = az deployment group list --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        
        if ($deployments -and $deployments.Count -gt 0) {
            $oldDeployments = $deployments | Where-Object { 
                $deploymentDate = [DateTime]::Parse($_.properties.timestamp)
                $deploymentDate -lt $cutoffDate -and $_.properties.provisioningState -eq "Succeeded"
            }
            
            foreach ($deployment in $oldDeployments) {
                if ($DryRun) {
                    Write-CleanupAction "DELETE" "Deployment" $deployment.name "PLANNED" "Old deployment"
                } else {
                    $deleteResult = az deployment group delete --resource-group $ResourceGroupName --name $deployment.name --output none 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-CleanupAction "DELETE" "Deployment" $deployment.name "DELETED" "Old deployment"
                    } else {
                        Write-CleanupAction "DELETE" "Deployment" $deployment.name "ERROR" "Deletion failed" $deleteResult
                        $cleanupResults.Summary.Errors++
                    }
                }
            }
        }
    } catch {
        Write-Host "⚠️ Failed to clean up deployments: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # 6. Clean up Kubernetes resources (if AKS cluster exists)
    if ($ClusterName) {
        Write-Host "`n=== CLEANING UP KUBERNETES RESOURCES ===" -ForegroundColor Magenta
        try {
            # Get AKS credentials
            az aks get-credentials --resource-group $ResourceGroupName --name $ClusterName --overwrite-existing --output none 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                # Clean up failed pods
                $failedPods = kubectl get pods -A --field-selector=status.phase=Failed --no-headers 2>$null
                if ($failedPods) {
                    $podCount = ($failedPods | Measure-Object).Count
                    if ($DryRun) {
                        Write-CleanupAction "DELETE" "FailedPods" "$podCount pods" "PLANNED" "Failed pods cleanup"
                    } else {
                        kubectl delete pods -A --field-selector=status.phase=Failed --output none 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Write-CleanupAction "DELETE" "FailedPods" "$podCount pods" "DELETED" "Failed pods cleanup"
                        }
                    }
                }
                
                # Clean up completed jobs older than retention period
                $completedJobs = kubectl get jobs -A --field-selector=status.successful=1 --no-headers 2>$null
                if ($completedJobs) {
                    $jobsToDelete = @()
                    foreach ($job in $completedJobs) {
                        $jobInfo = $job -split '\s+'
                        $namespace = $jobInfo[0]
                        $jobName = $jobInfo[1]
                        
                        # Get job creation time
                        $jobAge = kubectl get job $jobName -n $namespace -o jsonpath='{.metadata.creationTimestamp}' 2>$null
                        if ($jobAge) {
                            $creationTime = [DateTime]::Parse($jobAge)
                            if ($creationTime -lt $cutoffDate) {
                                $jobsToDelete += "$namespace/$jobName"
                            }
                        }
                    }
                    
                    foreach ($jobToDelete in $jobsToDelete) {
                        $parts = $jobToDelete -split '/'
                        $namespace = $parts[0]
                        $jobName = $parts[1]
                        
                        if ($DryRun) {
                            Write-CleanupAction "DELETE" "Job" "$namespace/$jobName" "PLANNED" "Completed job older than retention"
                        } else {
                            kubectl delete job $jobName -n $namespace --output none 2>$null
                            if ($LASTEXITCODE -eq 0) {
                                Write-CleanupAction "DELETE" "Job" "$namespace/$jobName" "DELETED" "Completed job cleanup"
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Host "⚠️ Failed to clean up Kubernetes resources: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # 7. Generate cleanup report
    Write-Host "`n=== CLEANUP SUMMARY ===" -ForegroundColor Magenta
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "Cleanup Time: $($cleanupResults.Timestamp)" -ForegroundColor White
    Write-Host "Mode: $(if ($DryRun) { 'DRY RUN' } else { 'EXECUTION' })" -ForegroundColor $(if ($DryRun) { 'Cyan' } else { 'Yellow' })
    Write-Host "Resources Scanned: $($cleanupResults.Summary.ResourcesScanned)" -ForegroundColor White
    Write-Host "Resources To Delete: $($cleanupResults.Summary.ResourcesToDelete)" -ForegroundColor White
    Write-Host "Resources Deleted: $($cleanupResults.Summary.ResourcesDeleted)" -ForegroundColor Green
    Write-Host "Resources Skipped: $($cleanupResults.Summary.ResourcesSkipped)" -ForegroundColor Yellow
    Write-Host "Errors: $($cleanupResults.Summary.Errors)" -ForegroundColor $(if ($cleanupResults.Summary.Errors -gt 0) { 'Red' } else { 'Green' })
    Write-Host "=========================" -ForegroundColor Magenta

    # Export results to JSON
    $resultsJson = $cleanupResults | ConvertTo-Json -Depth 10
    $resultsPath = "cleanup-results-$Environment.json"
    $resultsJson | Out-File -FilePath $resultsPath -Encoding UTF8
    Write-Host "`nCleanup results exported to: $resultsPath" -ForegroundColor Cyan

    # Set pipeline variables for Azure DevOps
    Write-Host "##vso[task.setvariable variable=CleanupResourcesScanned]$($cleanupResults.Summary.ResourcesScanned)"
    Write-Host "##vso[task.setvariable variable=CleanupResourcesDeleted]$($cleanupResults.Summary.ResourcesDeleted)"
    Write-Host "##vso[task.setvariable variable=CleanupResourcesSkipped]$($cleanupResults.Summary.ResourcesSkipped)"
    Write-Host "##vso[task.setvariable variable=CleanupErrors]$($cleanupResults.Summary.Errors)"

    # Exit with appropriate code
    if ($cleanupResults.Summary.Errors -gt 0) {
        Write-Host "`n⚠️ Cleanup completed with errors" -ForegroundColor Yellow
        exit 0  # Don't fail the pipeline for cleanup errors
    } else {
        Write-Host "`n✅ Cleanup completed successfully" -ForegroundColor Green
        exit 0
    }

} catch {
    Write-Host "`n❌ Cleanup failed with error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    $cleanupResults.Summary.Errors++
    
    # Export error results
    $resultsJson = $cleanupResults | ConvertTo-Json -Depth 10
    $resultsPath = "cleanup-results-$Environment-error.json"
    $resultsJson | Out-File -FilePath $resultsPath -Encoding UTF8
    
    exit 1
}