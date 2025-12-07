# Azure Infrastructure for OpenWebUI

This directory contains Terraform configurations for deploying OpenWebUI on Azure Kubernetes Service (AKS) with Azure OpenAI Service integration.

## 🚀 Quick Start

### Prerequisites

1. **Azure Subscription**: Active Azure subscription
2. **Azure CLI**: Installed and configured (`az login`)
3. **Terraform**: Version >= 1.0
4. **kubectl**: Kubernetes command-line tool

### Quick Deployment

```bash
# 1. Clone the repository
git clone <repository-url>
cd Terraform-EKS-Test/terraform

# 2. Create terraform.tfvars
cat > terraform.tfvars <<EOF
subscription_id = "your-subscription-id"
tenant_id       = "your-tenant-id"
location        = "eastus"
cluster_name    = "my-aks-cluster"
EOF

# 3. Initialize Terraform
terraform init

# 4. Review the plan
terraform plan

# 5. Apply the configuration
terraform apply
```

## 📁 Directory Structure

```
terraform/
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Variable definitions
├── outputs.tf                       # Output definitions
├── terraform.tfvars                 # Variable values (create this)
├── modules/
│   ├── vnet/                        # Virtual Network module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aks/                         # AKS cluster module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── openai/                      # Azure OpenAI module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── AZURE_ARCHITECTURE.md            # Architecture documentation
├── AZURE_SOLUTION_ARCHITECTURE.md   # Detailed solution architecture
└── AZURE_MIGRATION_GUIDE.md         # AWS to Azure migration guide
```

## 🏗️ Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Cloud                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Resource Group                          │  │
│  │                                                   │  │
│  │  ┌──────────────┐  ┌──────────────┐            │  │
│  │  │ Virtual      │  │ AKS Cluster  │            │  │
│  │  │ Network      │  │              │            │  │
│  │  └──────────────┘  └──────────────┘            │  │
│  │                                                   │  │
│  │  ┌──────────────┐  ┌──────────────┐            │  │
│  │  │ Azure OpenAI │  │ Blob Storage │            │  │
│  │  │ Service      │  │              │            │  │
│  │  └──────────────┘  └──────────────┘            │  │
│  │                                                   │  │
│  │  ┌──────────────┐  ┌──────────────┐            │  │
│  │  │ Log Analytics│  │ Azure Monitor│            │  │
│  │  │ Workspace    │  │              │            │  │
│  │  └──────────────┘  └──────────────┘            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

For detailed architecture diagrams, see:
- [AZURE_ARCHITECTURE.md](./AZURE_ARCHITECTURE.md) - Complete architecture documentation
- [AZURE_SOLUTION_ARCHITECTURE.md](./AZURE_SOLUTION_ARCHITECTURE.md) - Detailed solution breakdown

## 📋 Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `subscription_id` | Azure subscription ID | `"12345678-1234-1234-1234-123456789012"` |
| `tenant_id` | Azure tenant ID | `"87654321-4321-4321-4321-210987654321"` |
| `location` | Azure region | `"eastus"` |
| `cluster_name` | AKS cluster name | `"my-aks-cluster"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_name` | Virtual Network name | `"aks-vnet"` |
| `vpc_cidr` | VNet address spaces | `["10.0.0.0/16"]` |
| `private_subnets` | Private subnet CIDRs | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `public_subnets` | Public subnet CIDRs | `["10.0.101.0/24", "10.0.102.0/24"]` |
| `cluster_version` | Kubernetes version | `"1.27"` |

## 🔧 Modules

### VNet Module

Creates Azure Virtual Network with public and private subnets.

**Usage:**
```hcl
module "vnet" {
  source = "./modules/vnet"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_name           = var.vpc_name
  vnet_cidr           = var.vpc_cidr
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
}
```

### AKS Module

Creates Azure Kubernetes Service cluster with auto-scaling.

**Usage:**
```hcl
module "aks" {
  source = "./modules/aks"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  cluster_name        = var.cluster_name
  kubernetes_version  = var.cluster_version
  vnet_id             = module.vnet.vnet_id
  subnet_ids          = module.vnet.private_subnets
}
```

### OpenAI Module

Creates Azure OpenAI Service with model deployments and RAG support.

**Usage:**
```hcl
module "openai" {
  source = "./modules/openai"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.cluster_name
  
  deployment_models = [
    {
      name    = "gpt-4"
      model   = "gpt-4"
      version = "0613"
    }
  ]
}
```

## 🔐 Security

### Managed Identities

The infrastructure uses Azure Managed Identities for secure, passwordless authentication:

- **AKS Managed Identity**: For cluster operations
- **OpenWebUI Managed Identity**: For accessing Azure OpenAI and other services

### Network Security

- **Network Security Groups (NSG)**: Firewall rules for network traffic
- **Private Endpoints**: Secure connectivity to Azure services
- **Private DNS Zones**: DNS resolution for private endpoints

### Best Practices

1. Use private endpoints for production workloads
2. Enable Azure AD integration for AKS
3. Implement network policies in Kubernetes
4. Use Key Vault for secrets management
5. Enable diagnostic logging for all resources

## 📊 Monitoring

### Azure Monitor

- **Metrics**: CPU, memory, network, and custom metrics
- **Logs**: Centralized logging in Log Analytics Workspace
- **Alerts**: Automated alerting based on metrics and logs

### Key Metrics

- AKS node CPU and memory usage
- Pod count and status
- Azure OpenAI API call count and errors
- Storage capacity and operations

### Accessing Logs

```bash
# Query Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "AzureActivity | limit 10"
```

## 💰 Cost Optimization

### Recommendations

1. **Right-size node pools**: Use appropriate VM sizes
2. **Enable autoscaling**: Scale down during low usage
3. **Optimize storage**: Use appropriate storage tiers
4. **Review log retention**: Adjust based on compliance needs
5. **Use reserved capacity**: For predictable workloads

### Estimated Costs

- **AKS Control Plane**: Free
- **Compute Nodes**: ~$60/node/month
- **Azure OpenAI**: Pay-per-use
- **Storage**: ~$0.02/GB/month
- **Monitoring**: ~$2.30/GB ingested

**Total Estimated**: ~$450-600/month (excluding OpenAI usage)

## 🚨 Troubleshooting

### Common Issues

#### Cannot Connect to AKS

```bash
# Get credentials
az aks get-credentials --resource-group <rg> --name <cluster>

# Verify connection
kubectl get nodes
```

#### Managed Identity Not Working

```bash
# Check role assignments
az role assignment list --assignee <principal-id>

# Verify service account
kubectl describe sa <service-account-name> -n <namespace>
```

#### Private Endpoint Issues

```bash
# Check DNS resolution
nslookup <endpoint-name>

# Verify private DNS zone
az network private-dns zone show --name <zone-name>
```

For more troubleshooting tips, see [AZURE_ARCHITECTURE.md](./AZURE_ARCHITECTURE.md#troubleshooting).

## 📚 Documentation

- **[AZURE_ARCHITECTURE.md](./AZURE_ARCHITECTURE.md)**: Complete architecture documentation
- **[AZURE_SOLUTION_ARCHITECTURE.md](./AZURE_SOLUTION_ARCHITECTURE.md)**: Detailed solution breakdown with diagrams
- **[AZURE_MIGRATION_GUIDE.md](./AZURE_MIGRATION_GUIDE.md)**: AWS to Azure migration guide

## 🔄 Migration from AWS

If you're migrating from AWS EKS, see the [Migration Guide](./AZURE_MIGRATION_GUIDE.md) for:
- Service mapping (AWS → Azure)
- Configuration changes
- Migration checklist
- Cost comparison

## 🛠️ Development

### Local Development

```bash
# Format Terraform code
terraform fmt -recursive

# Validate configuration
terraform validate

# Check for issues
terraform plan
```

### Testing

```bash
# Test AKS connectivity
kubectl get nodes

# Test OpenAI connectivity
kubectl exec -it <pod-name> -- curl <openai-endpoint>

# Check logs
kubectl logs <pod-name>
```

## 📞 Support

For issues or questions:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review Azure service health
3. Consult Azure documentation
4. Contact Azure support (if applicable)

## 📝 License

See LICENSE file in the repository root.

---

**Last Updated**: 2024  
**Version**: 1.0

