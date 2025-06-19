# VPC Module

This module provisions a Virtual Private Cloud (VPC) using the official terraform-aws-modules/vpc/aws module.

## Features
- Creates a VPC with public and private subnets
- Enables NAT gateway and DNS hostnames
- Tags subnets for EKS and Karpenter discovery

## Usage
```hcl
module "vpc" {
  source = "./modules/vpc"
  vpc_name        = var.vpc_name
  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  cluster_name    = var.cluster_name
}
```

## Variables
- `vpc_name` (string): Name of the VPC
- `vpc_cidr` (string): CIDR block for the VPC
- `private_subnets` (list(string)): Private subnet CIDRs
- `public_subnets` (list(string)): Public subnet CIDRs
- `cluster_name` (string): EKS cluster name for subnet tagging

## Outputs
- `vpc_id`: VPC ID
- `private_subnets`: List of private subnet IDs
- `public_subnets`: List of public subnet IDs

## Integration
Subnets are tagged for EKS and Karpenter to enable node provisioning and load balancer integration. 