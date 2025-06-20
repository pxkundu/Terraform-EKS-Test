# EFS Module

This module provisions an Amazon Elastic File System (EFS) using the official terraform-aws-modules/efs/aws module.

## Features
- Creates an EFS file system with configurable subnets and security groups
- Supports tagging for resource management

## Usage
```hcl
module "efs" {
  source = "./modules/efs"
  efs_name           = var.efs_name
  vpc_id             = var.vpc_id
  subnets            = var.subnets
  security_group_ids = var.security_group_ids
  tags               = var.tags
}
```

## Variables
- `efs_name` (string): Name of the EFS file system
- `vpc_id` (string): VPC ID
- `subnets` (list(string)): Subnet IDs
- `security_group_ids` (list(string)): Security group IDs
- `tags` (map(string)): Resource tags

## Outputs
- `efs_id`: EFS file system ID
- `efs_arn`: EFS file system ARN

## Best Practices
- Use security groups to restrict NFS access
- Tag resources for cost allocation 