# Azure Infrastructure - Quick Start Guide

## 🎯 What's Been Migrated

This branch (`azure-migration`) contains a complete migration from AWS EKS to Azure AKS infrastructure. All AWS services have been replaced with their Azure equivalents.

## 📦 What's Included

### Core Infrastructure
- ✅ **Virtual Network (VNet)** - Replaces AWS VPC
- ✅ **Azure Kubernetes Service (AKS)** - Replaces AWS EKS
- ✅ **Cluster Autoscaler** - Built into AKS (replaces Karpenter)
- ✅ **Azure OpenAI Service** - Replaces AWS Bedrock
- ✅ **Azure Blob Storage** - Replaces AWS S3
- ✅ **Azure Monitor & Log Analytics** - Replaces AWS CloudWatch
- ✅ **Managed Identities** - Replaces AWS IAM Roles
- ✅ **Private Endpoints** - Replaces AWS VPC Endpoints

### Documentation
- ✅ **AZURE_ARCHITECTURE.md** - Complete architecture documentation
- ✅ **AZURE_SOLUTION_ARCHITECTURE.md** - Detailed solution breakdown with mermaid diagrams
- ✅ **AZURE_MIGRATION_GUIDE.md** - AWS to Azure migration guide
- ✅ **README_AZURE.md** - Quick reference guide

## 🚀 Getting Started

### 1. Prerequisites

```bash
# Install Azure CLI (if not already installed)
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
# Download from: https://aka.ms/installazurecliwindows
```

### 2. Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Verify
az account show
```

### 3. Configure Terraform

Create `terraform.tfvars`:

```hcl
subscription_id = "your-subscription-id-here"
tenant_id       = "your-tenant-id-here"
location        = "eastus"  # or your preferred region
cluster_name    = "my-aks-cluster"
vpc_name        = "aks-vnet"
vpc_cidr        = ["10.0.0.0/16"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
cluster_version = "1.27"
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy (type 'yes' when prompted)
terraform apply
```

### 5. Access Your Cluster

```bash
# Get cluster credentials
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>

# Verify connection
kubectl get nodes

# Check pods
kubectl get pods --all-namespaces
```

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud                               │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Resource Group                           │  │
│  │                                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │  │
│  │  │   Virtual   │  │     AKS     │  │   Azure     │ │  │
│  │  │   Network   │  │   Cluster   │  │   OpenAI    │ │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │  │
│  │                                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │  │
│  │  │    Blob     │  │    Log      │  │   Monitor   │ │  │
│  │  │   Storage   │  │  Analytics  │  │             │ │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

For detailed architecture diagrams, see:
- [AZURE_SOLUTION_ARCHITECTURE.md](./AZURE_SOLUTION_ARCHITECTURE.md)

## 🔑 Key Differences from AWS

| Aspect | AWS | Azure |
|--------|-----|-------|
| **Provider** | `provider "aws"` | `provider "azurerm"` |
| **Network** | VPC (single CIDR) | VNet (address spaces list) |
| **Kubernetes** | EKS (control plane on EC2) | AKS (fully managed) |
| **Autoscaling** | Karpenter (separate) | Built into AKS |
| **AI Service** | Bedrock (unified API) | OpenAI (deployments per model) |
| **Identity** | IAM Roles (ARNs) | Managed Identities (Client IDs) |
| **Storage** | S3 (buckets) | Blob Storage (containers) |
| **Monitoring** | CloudWatch | Monitor + Log Analytics |

## 📁 Module Structure

```
modules/
├── vnet/          # Virtual Network
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── aks/           # AKS Cluster
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── openai/        # Azure OpenAI Service
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## 🔐 Security Features

- ✅ **Managed Identities**: Passwordless authentication
- ✅ **Private Endpoints**: Secure service connectivity
- ✅ **Network Security Groups**: Firewall rules
- ✅ **RBAC**: Role-based access control
- ✅ **Encryption**: At rest and in transit

## 📈 Monitoring

- ✅ **Azure Monitor**: Metrics and performance
- ✅ **Log Analytics**: Centralized logging
- ✅ **Metric Alerts**: Automated alerting
- ✅ **Action Groups**: Notification targets

## 💡 Next Steps

1. **Review Documentation**:
   - [AZURE_ARCHITECTURE.md](./AZURE_ARCHITECTURE.md) - Complete guide
   - [AZURE_MIGRATION_GUIDE.md](./AZURE_MIGRATION_GUIDE.md) - Migration details

2. **Customize Configuration**:
   - Adjust node pool sizes
   - Configure additional model deployments
   - Set up custom monitoring alerts

3. **Deploy Applications**:
   - Deploy OpenWebUI (automated via Terraform)
   - Configure ingress
   - Set up SSL certificates

4. **Optimize Costs**:
   - Review node pool sizing
   - Optimize storage tiers
   - Adjust log retention

## 🆘 Need Help?

1. **Check Documentation**:
   - [README_AZURE.md](./README_AZURE.md) - Quick reference
   - [AZURE_ARCHITECTURE.md](./AZURE_ARCHITECTURE.md) - Troubleshooting section

2. **Common Commands**:
   ```bash
   # Get cluster info
   az aks show --resource-group <rg> --name <cluster>
   
   # View logs
   kubectl logs <pod-name>
   
   # Check node status
   kubectl get nodes
   ```

3. **Azure Resources**:
   - [Azure Documentation](https://docs.microsoft.com/azure/)
   - [AKS Documentation](https://docs.microsoft.com/azure/aks/)
   - [OpenAI Documentation](https://learn.microsoft.com/azure/cognitive-services/openai/)

## ✅ Verification Checklist

After deployment, verify:

- [ ] AKS cluster is running: `kubectl get nodes`
- [ ] OpenWebUI pods are running: `kubectl get pods`
- [ ] Azure OpenAI is accessible: Check endpoint in outputs
- [ ] Log Analytics is receiving logs: Check Azure Portal
- [ ] Private endpoints are configured: Check VNet in Portal
- [ ] Managed identities have correct roles: `az role assignment list`

## 📝 Notes

- The AKS control plane is **free** (unlike EKS which charges ~$73/month)
- Private endpoints cost ~$7.30/month each
- Log Analytics charges ~$2.30/GB ingested
- Azure OpenAI is pay-per-use (similar to Bedrock)

---

**Ready to deploy?** Run `terraform apply` and follow the prompts!

**Questions?** Check the detailed documentation files or Azure's official documentation.

