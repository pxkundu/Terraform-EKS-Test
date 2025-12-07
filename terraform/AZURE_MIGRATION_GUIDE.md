# AWS to Azure Migration Guide

## Overview

This guide documents the migration from AWS EKS infrastructure to Azure AKS infrastructure, including all service mappings and key differences.

## Quick Reference: AWS to Azure Service Mapping

| AWS Service | Azure Equivalent | Key Differences |
|------------|------------------|-----------------|
| **VPC** | **Virtual Network (VNet)** | VNet uses address spaces (list) instead of single CIDR |
| **Subnets** | **Subnets** | Similar concept, but integrated with NSGs |
| **Security Groups** | **Network Security Groups (NSG)** | NSGs are separate resources, not attached to instances |
| **EKS** | **Azure Kubernetes Service (AKS)** | AKS control plane is fully managed (no EC2 instances) |
| **Karpenter** | **Cluster Autoscaler** | Built into AKS, no separate installation needed |
| **Bedrock** | **Azure OpenAI Service** | Different API, requires model deployments |
| **S3** | **Azure Blob Storage** | Different API, uses containers instead of buckets |
| **CloudWatch** | **Azure Monitor + Log Analytics** | Separate services for metrics and logs |
| **IAM Roles** | **Managed Identities** | No ARNs, uses client IDs and principal IDs |
| **IAM Policies** | **Azure RBAC** | Role-based access control with different syntax |
| **Route53** | **Azure DNS** | Similar functionality, different API |
| **RDS** | **Azure Database Services** | PostgreSQL, MySQL, etc. as separate services |
| **EFS** | **Azure Files** | NFS support available, different mounting |
| **ALB** | **Application Gateway** | Layer 7 load balancing with WAF integration |
| **ACM** | **Key Vault Certificates** | Certificate management in Key Vault |
| **VPC Endpoints** | **Private Endpoints** | Similar concept, uses Private Link |

## Key Architectural Differences

### 1. Networking

**AWS:**
- VPC with single CIDR block
- Security groups attached to resources
- Route tables per subnet

**Azure:**
- VNet with address spaces (can have multiple)
- NSGs are separate resources, associated with subnets
- Route tables associated with subnets

### 2. Kubernetes

**AWS EKS:**
- Control plane runs on AWS-managed EC2 instances
- Requires separate node groups
- Karpenter for autoscaling (separate installation)

**Azure AKS:**
- Control plane is fully managed (no visible infrastructure)
- Built-in cluster autoscaler
- Integrated with Azure AD for RBAC

### 3. AI/ML Services

**AWS Bedrock:**
- Unified API for multiple foundation models
- Model access via IAM policies
- Knowledge base for RAG

**Azure OpenAI:**
- Requires model deployments per model
- API key or managed identity authentication
- Cognitive Search for RAG (separate service)

### 4. Identity & Access

**AWS IAM:**
- Roles with ARNs
- Policies attached to roles
- IRSA for Kubernetes integration

**Azure:**
- Managed identities (user-assigned or system-assigned)
- RBAC with role assignments
- Service account integration via managed identities

### 5. Storage

**AWS S3:**
- Buckets with objects
- Versioning at bucket level
- IAM-based access control

**Azure Blob Storage:**
- Storage accounts with containers
- Versioning at blob level
- RBAC or shared access signatures

### 6. Monitoring

**AWS CloudWatch:**
- Unified service for logs and metrics
- CloudWatch Logs and CloudWatch Metrics

**Azure:**
- Log Analytics Workspace for logs
- Azure Monitor for metrics
- Separate but integrated services

## Migration Checklist

### Pre-Migration

- [ ] Review current AWS infrastructure
- [ ] Identify all dependencies
- [ ] Document current configurations
- [ ] Plan Azure resource naming conventions
- [ ] Set up Azure subscription and permissions
- [ ] Review Azure quotas and limits

### Migration Steps

- [ ] Create Azure Resource Group
- [ ] Set up Virtual Network and subnets
- [ ] Configure Network Security Groups
- [ ] Deploy AKS cluster
- [ ] Configure managed identities
- [ ] Set up Azure OpenAI Service
- [ ] Deploy Cognitive Search (if using RAG)
- [ ] Configure Blob Storage
- [ ] Set up Log Analytics Workspace
- [ ] Configure Azure Monitor alerts
- [ ] Set up private endpoints
- [ ] Migrate application workloads
- [ ] Update application configurations
- [ ] Test end-to-end functionality

### Post-Migration

- [ ] Verify all services are accessible
- [ ] Test application functionality
- [ ] Validate monitoring and alerting
- [ ] Review cost optimization opportunities
- [ ] Update documentation
- [ ] Train team on Azure services
- [ ] Set up backup and disaster recovery

## Configuration Changes Required

### 1. Terraform Provider

**Before (AWS):**
```hcl
provider "aws" {
  region  = var.region
  profile = "exam3"
}
```

**After (Azure):**
```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
```

### 2. Resource Group

**AWS:** No equivalent (resources are regional)

**Azure:** Required for all resources
```hcl
resource "azurerm_resource_group" "main" {
  name     = "${var.cluster_name}-rg"
  location = var.location
}
```

### 3. Network Configuration

**AWS VPC:**
```hcl
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}
```

**Azure VNet:**
```hcl
module "vnet" {
  source = "./modules/vnet"
  vnet_cidr = ["10.0.0.0/16"]  # Note: list format
}
```

### 4. Kubernetes Cluster

**AWS EKS:**
```hcl
module "eks" {
  source = "./modules/eks"
  cluster_name = var.cluster_name
}
```

**Azure AKS:**
```hcl
module "aks" {
  source = "./modules/aks"
  cluster_name = var.cluster_name
  location = var.location
  resource_group_name = azurerm_resource_group.main.name
}
```

### 5. AI Service Configuration

**AWS Bedrock:**
```hcl
module "bedrock" {
  source = "./modules/bedrock"
  allowed_models = ["anthropic.claude-3-sonnet-v1"]
}
```

**Azure OpenAI:**
```hcl
module "openai" {
  source = "./modules/openai"
  deployment_models = [
    {
      name    = "gpt-4"
      model   = "gpt-4"
      version = "0613"
    }
  ]
}
```

### 6. Authentication

**AWS IAM Role:**
```hcl
resource "aws_iam_role" "app_role" {
  name = "app-role"
}
```

**Azure Managed Identity:**
```hcl
resource "azurerm_user_assigned_identity" "app" {
  name = "app-identity"
  location = var.location
  resource_group_name = azurerm_resource_group.main.name
}
```

## Cost Comparison

### Estimated Monthly Costs

| Component | AWS | Azure | Notes |
|-----------|-----|-------|-------|
| **Control Plane** | $0.10/hour (~$73/month) | $0 (Free) | AKS control plane is free |
| **Worker Nodes** | ~$60/node/month | ~$60/node/month | Similar pricing |
| **AI Service** | Pay-per-use | Pay-per-use | Similar pricing models |
| **Storage** | $0.023/GB/month | $0.018/GB/month | Azure slightly cheaper |
| **Networking** | Varies | ~$7.30/private endpoint | Azure private endpoints have fixed cost |
| **Monitoring** | $0.50/GB ingested | $2.30/GB ingested | Azure more expensive for logs |

**Note:** Actual costs vary based on usage, region, and service tiers.

## Performance Considerations

### Network Performance

- **AWS:** VPC endpoints provide low-latency connectivity
- **Azure:** Private endpoints provide similar performance
- Both keep traffic on the cloud provider's backbone

### Compute Performance

- **AWS EKS:** Control plane managed, nodes are EC2 instances
- **Azure AKS:** Both control plane and nodes are managed
- Similar performance characteristics for workloads

### Storage Performance

- **AWS S3:** High throughput, eventual consistency
- **Azure Blob:** Similar performance, strong consistency options

## Security Considerations

### Network Security

- Both platforms support network isolation
- Azure NSGs are more flexible (can be associated with subnets or NICs)
- AWS Security Groups are simpler but less flexible

### Identity Security

- AWS IAM is more mature with fine-grained policies
- Azure RBAC is role-based, simpler but less granular
- Both support managed identities/service principals

### Data Security

- Both support encryption at rest and in transit
- Azure Key Vault is more integrated with other services
- AWS KMS is more widely used

## Troubleshooting Common Issues

### Issue 1: Cannot Connect to AKS

**Solution:**
```bash
# Get credentials
az aks get-credentials --resource-group <rg> --name <cluster>

# Verify connection
kubectl get nodes
```

### Issue 2: Managed Identity Not Working

**Solution:**
- Verify role assignments: `az role assignment list --assignee <principal-id>`
- Check service account annotations in Kubernetes
- Verify managed identity is attached to AKS

### Issue 3: Private Endpoint Not Resolving

**Solution:**
- Verify private DNS zone is linked to VNet
- Check DNS resolution: `nslookup <endpoint>`
- Verify private endpoint is in correct subnet

### Issue 4: High Costs

**Solution:**
- Review node pool sizes and autoscaling settings
- Optimize log retention periods
- Use appropriate storage tiers
- Review and optimize private endpoint usage

## Best Practices

1. **Start Small**: Begin with a development environment
2. **Use Managed Services**: Leverage Azure managed services where possible
3. **Implement Monitoring Early**: Set up Azure Monitor from the start
4. **Use Private Endpoints**: For production workloads, use private endpoints
5. **Tag Resources**: Implement consistent tagging strategy
6. **Review Costs Regularly**: Monitor and optimize costs
7. **Document Changes**: Keep documentation up to date
8. **Test Disaster Recovery**: Regularly test backup and recovery procedures

## Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/azure/aks/)
- [Azure OpenAI Service Documentation](https://learn.microsoft.com/azure/cognitive-services/openai/)
- [Azure Virtual Network Documentation](https://docs.microsoft.com/azure/virtual-network/)
- [Azure Monitor Documentation](https://docs.microsoft.com/azure/azure-monitor/)
- [Managed Identities Documentation](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)

---

**Last Updated**: 2024  
**Version**: 1.0

