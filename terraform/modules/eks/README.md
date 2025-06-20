# EKS Module

This module provisions an Amazon EKS cluster using the official terraform-aws-modules/eks/aws module.

## Features
- Creates an EKS cluster with managed node groups
- Outputs kubeconfig for cluster access
- Outputs OIDC provider ARN and URL for IRSA (IAM Roles for Service Accounts) integration (required for Karpenter and other controllers)

## Usage
```hcl
module "eks" {
  source = "./modules/eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
}
```

## Variables
- `cluster_name` (string): Name of the EKS cluster
- `cluster_version` (string): Kubernetes version
- `vpc_id` (string): VPC ID for the cluster
- `subnet_ids` (list(string)): Subnet IDs for the cluster

## Outputs
- `cluster_endpoint`: EKS API endpoint
- `kubeconfig`: Kubeconfig YAML for cluster access
- `oidc_provider_arn`: OIDC provider ARN for IRSA
- `oidc_provider_url`: OIDC provider URL for IRSA

## Integration
Use the OIDC outputs to configure IRSA for controllers like Karpenter, ExternalDNS, etc. 