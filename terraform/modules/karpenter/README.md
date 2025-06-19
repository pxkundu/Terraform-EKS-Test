# Karpenter Module

This module installs and configures [Karpenter](https://karpenter.sh/), an open-source Kubernetes node autoscaler, for your EKS cluster.

## Features
- Provisions all required IAM roles and policies for Karpenter using IRSA (IAM Roles for Service Accounts)
- Installs the Karpenter controller via the official Helm chart
- Provides a sample Karpenter Provisioner manifest (`provisioner.yaml`)

## Usage
```hcl
module "karpenter" {
  source = "./modules/karpenter"
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  cluster_name           = var.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  default_instance_profile = "eksctl-${var.cluster_name}-nodegroup-ng-NodeInstanceProfile"
  karpenter_helm_version = "v0.34.0"
}
```

## Variables
- `oidc_provider_arn` (string): OIDC provider ARN from EKS
- `oidc_provider_url` (string): OIDC provider URL from EKS
- `cluster_name` (string): EKS cluster name
- `cluster_endpoint` (string): EKS API endpoint
- `default_instance_profile` (string): Default instance profile for nodes
- `karpenter_helm_version` (string): Helm chart version

## Outputs
- `karpenter_service_account_name`: Name of the Karpenter service account
- `karpenter_iam_role_arn`: IAM role ARN for Karpenter

## Provisioner Manifest
Edit and apply `provisioner.yaml` to control how Karpenter provisions nodes (instance types, zones, etc.).

## Requirements
- `kubectl` and `helm` must be installed and available in your PATH.
- EKS OIDC provider must be enabled (handled by the EKS module). 