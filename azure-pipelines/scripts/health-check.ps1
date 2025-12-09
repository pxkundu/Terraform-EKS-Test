# Infrastructure Health Check Script
# This script performs comprehensive health checks on deployed Azure infrastructure

param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

# Set error action preference
$ErrorActionPreference = "Continue"

Write-Host "Starting infrastructure health check for environment: $Environment" -ForegroundColor Green

# Initialize results
$healthResults = @{
    Environment = $Environment
    ResourceGroup = $ResourceGroupName
    Cluster = $ClusterName
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    OverallStatus = "Unknown"
    Checks = @{}
}

function Write-HealthCheck {
    param(
        [string]$CheckName,
        [string]$Status,
        [string]$Message,
        [string]$Details = ""
    )
    
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        default { "Cyan" }
    }
    
    Write-Host "[$Status] $CheckName - $Message" -ForegroundColor $color
    if ($Details -and $Detailed) {
        Write-Host "    Details: $Details" -ForegroundColor Gray
    }
    
    $healthResults.Checks[$CheckName] = @{
        Status = $Status
        Message = $Message
        Details = $Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
}

try {
    # 1. Azure CLI Authentication Check
    Write-Host "`n=== AUTHENTICATION CHECK ===" -ForegroundColor Magenta
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if ($account) {
            Write-HealthCheck "Azure CLI Authentication" "PASS" "Authenticated as $($account.user.name)" "Subscription: $($account.name)"
        } else {
            Write-HealthCheck "Azure CLI Authentication" "FAIL" "Not authenticated"
            throw "Azure CLI authentication failed"
        }
    } catch {
        Write-HealthCheck "Azure CLI Authentication" "FAIL" "Authentication check failed: $($_.Exception.Message)"
    }

    # 2. Resource Group Check
    Write-Host "`n=== RESOURCE GROUP CHECK ===" -ForegroundColor Magenta
    try {
        $rg = az group show --name $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        if ($rg) {
            Write-HealthCheck "Resource Group Existence" "PASS" "Resource group exists" "Location: $($rg.location), State: $($rg.properties.provisioningState)"
        } else {
            Write-HealthCheck "Resource Group Existence" "FAIL" "Resource group not found"
        }
    } catch {
        Write-HealthCheck "Resource Group Existence" "FAIL" "Failed to check resource group: $($_.Exception.Message)"
    }

    # 3. AKS Cluster Check
    Write-Host "`n=== AKS CLUSTER CHECK ===" -ForegroundColor Magenta
    try {
        $cluster = az aks show --resource-group $ResourceGroupName --name $ClusterName --output json 2>$null | ConvertFrom-Json
        if ($cluster) {
            $powerState = $cluster.powerState.code
            $provisioningState = $cluster.provisioningState
            $kubernetesVersion = $cluster.kubernetesVersion
            
            if ($powerState -eq "Running" -and $provisioningState -eq "Succeeded") {
                Write-HealthCheck "AKS Cluster Status" "PASS" "Cluster is running" "Version: $kubernetesVersion, Nodes: $($cluster.agentPoolProfiles[0].count)"
            } else {
                Write-HealthCheck "AKS Cluster Status" "WARN" "Cluster state: $powerState, Provisioning: $provisioningState"
            }
        } else {
            Write-HealthCheck "AKS Cluster Status" "FAIL" "AKS cluster not found"
        }
    } catch {
        Write-HealthCheck "AKS Cluster Status" "FAIL" "Failed to check AKS cluster: $($_.Exception.Message)"
    }

    # 4. Kubernetes Connectivity Check
    Write-Host "`n=== KUBERNETES CONNECTIVITY CHECK ===" -ForegroundColor Magenta
    try {
        # Get AKS credentials
        az aks get-credentials --resource-group $ResourceGroupName --name $ClusterName --overwrite-existing --output none 2>$null
        
        # Check kubectl connectivity
        $nodes = kubectl get nodes --no-headers 2>$null
        if ($LASTEXITCODE -eq 0 -and $nodes) {
            $nodeCount = ($nodes | Measure-Object).Count
            $readyNodes = ($nodes | Where-Object { $_ -match " Ready " } | Measure-Object).Count
            
            if ($nodeCount -eq $readyNodes) {
                Write-HealthCheck "Kubernetes Connectivity" "PASS" "All $nodeCount nodes are ready"
            } else {
                Write-HealthCheck "Kubernetes Connectivity" "WARN" "$readyNodes of $nodeCount nodes are ready"
            }
        } else {
            Write-HealthCheck "Kubernetes Connectivity" "FAIL" "Cannot connect to Kubernetes cluster"
        }
    } catch {
        Write-HealthCheck "Kubernetes Connectivity" "FAIL" "Kubernetes connectivity check failed: $($_.Exception.Message)"
    }

    # 5. System Pods Check
    Write-Host "`n=== SYSTEM PODS CHECK ===" -ForegroundColor Magenta
    try {
        $systemPods = kubectl get pods -n kube-system --no-headers 2>$null
        if ($LASTEXITCODE -eq 0 -and $systemPods) {
            $totalPods = ($systemPods | Measure-Object).Count
            $runningPods = ($systemPods | Where-Object { $_ -match " Running " } | Measure-Object).Count
            $failedPods = ($systemPods | Where-Object { $_ -match " Failed " } | Measure-Object).Count
            
            if ($failedPods -eq 0 -and $runningPods -gt 0) {
                Write-HealthCheck "System Pods Health" "PASS" "$runningPods of $totalPods system pods are running"
            } elseif ($failedPods -gt 0) {
                Write-HealthCheck "System Pods Health" "WARN" "$failedPods failed pods detected"
            } else {
                Write-HealthCheck "System Pods Health" "FAIL" "No running system pods found"
            }
        } else {
            Write-HealthCheck "System Pods Health" "FAIL" "Cannot retrieve system pods status"
        }
    } catch {
        Write-HealthCheck "System Pods Health" "FAIL" "System pods check failed: $($_.Exception.Message)"
    }

    # 6. Azure OpenAI Service Check
    Write-Host "`n=== AZURE OPENAI SERVICE CHECK ===" -ForegroundColor Magenta
    try {
        $openaiAccounts = az cognitiveservices account list --resource-group $ResourceGroupName --query "[?kind=='OpenAI']" --output json 2>$null | ConvertFrom-Json
        if ($openaiAccounts -and $openaiAccounts.Count -gt 0) {
            $account = $openaiAccounts[0]
            $provisioningState = $account.properties.provisioningState
            
            if ($provisioningState -eq "Succeeded") {
                Write-HealthCheck "Azure OpenAI Service" "PASS" "OpenAI service is available" "Endpoint: $($account.properties.endpoint)"
            } else {
                Write-HealthCheck "Azure OpenAI Service" "WARN" "OpenAI service state: $provisioningState"
            }
        } else {
            Write-HealthCheck "Azure OpenAI Service" "WARN" "No OpenAI service found in resource group"
        }
    } catch {
        Write-HealthCheck "Azure OpenAI Service" "FAIL" "OpenAI service check failed: $($_.Exception.Message)"
    }

    # 7. Database Check
    Write-Host "`n=== DATABASE CHECK ===" -ForegroundColor Magenta
    try {
        $dbServers = az postgres flexible-server list --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        if ($dbServers -and $dbServers.Count -gt 0) {
            $server = $dbServers[0]
            $state = $server.state
            
            if ($state -eq "Ready") {
                Write-HealthCheck "PostgreSQL Database" "PASS" "Database server is ready" "Server: $($server.fullyQualifiedDomainName)"
            } else {
                Write-HealthCheck "PostgreSQL Database" "WARN" "Database server state: $state"
            }
        } else {
            Write-HealthCheck "PostgreSQL Database" "WARN" "No PostgreSQL server found in resource group"
        }
    } catch {
        Write-HealthCheck "PostgreSQL Database" "FAIL" "Database check failed: $($_.Exception.Message)"
    }

    # 8. Network Security Check
    Write-Host "`n=== NETWORK SECURITY CHECK ===" -ForegroundColor Magenta
    try {
        $nsgs = az network nsg list --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        $privateEndpoints = az network private-endpoint list --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        
        $nsgCount = if ($nsgs) { $nsgs.Count } else { 0 }
        $peCount = if ($privateEndpoints) { $privateEndpoints.Count } else { 0 }
        
        if ($nsgCount -gt 0) {
            Write-HealthCheck "Network Security Groups" "PASS" "$nsgCount NSGs configured"
        } else {
            Write-HealthCheck "Network Security Groups" "WARN" "No NSGs found"
        }
        
        if ($peCount -gt 0) {
            Write-HealthCheck "Private Endpoints" "PASS" "$peCount private endpoints configured"
        } else {
            Write-HealthCheck "Private Endpoints" "WARN" "No private endpoints found"
        }
    } catch {
        Write-HealthCheck "Network Security" "FAIL" "Network security check failed: $($_.Exception.Message)"
    }

    # 9. Monitoring Check
    Write-Host "`n=== MONITORING CHECK ===" -ForegroundColor Magenta
    try {
        $workspaces = az monitor log-analytics workspace list --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        if ($workspaces -and $workspaces.Count -gt 0) {
            $workspace = $workspaces[0]
            Write-HealthCheck "Log Analytics Workspace" "PASS" "Monitoring workspace available" "Workspace: $($workspace.name)"
        } else {
            Write-HealthCheck "Log Analytics Workspace" "WARN" "No Log Analytics workspace found"
        }
    } catch {
        Write-HealthCheck "Monitoring" "FAIL" "Monitoring check failed: $($_.Exception.Message)"
    }

    # 10. Storage Check
    Write-Host "`n=== STORAGE CHECK ===" -ForegroundColor Magenta
    try {
        $storageAccounts = az storage account list --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        if ($storageAccounts -and $storageAccounts.Count -gt 0) {
            $healthyAccounts = 0
            foreach ($account in $storageAccounts) {
                if ($account.provisioningState -eq "Succeeded") {
                    $healthyAccounts++
                }
            }
            
            if ($healthyAccounts -eq $storageAccounts.Count) {
                Write-HealthCheck "Storage Accounts" "PASS" "All $($storageAccounts.Count) storage accounts are healthy"
            } else {
                Write-HealthCheck "Storage Accounts" "WARN" "$healthyAccounts of $($storageAccounts.Count) storage accounts are healthy"
            }
        } else {
            Write-HealthCheck "Storage Accounts" "WARN" "No storage accounts found"
        }
    } catch {
        Write-HealthCheck "Storage" "FAIL" "Storage check failed: $($_.Exception.Message)"
    }

    # Calculate overall status
    $passCount = ($healthResults.Checks.Values | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($healthResults.Checks.Values | Where-Object { $_.Status -eq "FAIL" }).Count
    $warnCount = ($healthResults.Checks.Values | Where-Object { $_.Status -eq "WARN" }).Count
    $totalChecks = $healthResults.Checks.Count

    if ($failCount -eq 0 -and $warnCount -eq 0) {
        $healthResults.OverallStatus = "HEALTHY"
        $statusColor = "Green"
    } elseif ($failCount -eq 0) {
        $healthResults.OverallStatus = "WARNING"
        $statusColor = "Yellow"
    } else {
        $healthResults.OverallStatus = "UNHEALTHY"
        $statusColor = "Red"
    }

    # Generate summary report
    Write-Host "`n=== HEALTH CHECK SUMMARY ===" -ForegroundColor Magenta
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "AKS Cluster: $ClusterName" -ForegroundColor White
    Write-Host "Check Time: $($healthResults.Timestamp)" -ForegroundColor White
    Write-Host "Overall Status: $($healthResults.OverallStatus)" -ForegroundColor $statusColor
    Write-Host "Results: $passCount PASS, $warnCount WARN, $failCount FAIL (Total: $totalChecks)" -ForegroundColor White
    Write-Host "=============================" -ForegroundColor Magenta

    # Export results to JSON
    $resultsJson = $healthResults | ConvertTo-Json -Depth 10
    $resultsPath = "health-check-results-$Environment.json"
    $resultsJson | Out-File -FilePath $resultsPath -Encoding UTF8
    Write-Host "`nHealth check results exported to: $resultsPath" -ForegroundColor Cyan

    # Set pipeline variables for Azure DevOps
    Write-Host "##vso[task.setvariable variable=HealthCheckStatus]$($healthResults.OverallStatus)"
    Write-Host "##vso[task.setvariable variable=HealthCheckPassCount]$passCount"
    Write-Host "##vso[task.setvariable variable=HealthCheckFailCount]$failCount"
    Write-Host "##vso[task.setvariable variable=HealthCheckWarnCount]$warnCount"

    # Exit with appropriate code
    if ($failCount -gt 0) {
        Write-Host "`n❌ Health check completed with failures" -ForegroundColor Red
        exit 1
    } elseif ($warnCount -gt 0) {
        Write-Host "`n⚠️ Health check completed with warnings" -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "`n✅ Health check completed successfully" -ForegroundColor Green
        exit 0
    }

} catch {
    Write-Host "`n❌ Health check failed with error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    $healthResults.OverallStatus = "ERROR"
    $healthResults.Checks["General"] = @{
        Status = "FAIL"
        Message = "Health check script failed: $($_.Exception.Message)"
        Details = $_.ScriptStackTrace
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    # Export error results
    $resultsJson = $healthResults | ConvertTo-Json -Depth 10
    $resultsPath = "health-check-results-$Environment-error.json"
    $resultsJson | Out-File -FilePath $resultsPath -Encoding UTF8
    
    exit 1
}