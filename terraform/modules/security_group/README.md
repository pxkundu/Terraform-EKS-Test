# Security Group Module

This module provisions security groups using the official terraform-aws-modules/security-group/aws module.

## Features
- Creates security groups with configurable ingress and egress rules
- Supports tagging for resource management

## Usage
```hcl
module "security_group" {
  source = "./modules/security_group"
  sg_name                  = var.sg_name
  sg_description           = var.sg_description
  vpc_id                   = var.vpc_id
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  egress_with_cidr_blocks  = var.egress_with_cidr_blocks
  tags                     = var.tags
}
```

## Variables
- `sg_name` (string): Name of the security group
- `sg_description` (string): Description
- `vpc_id` (string): VPC ID
- `ingress_with_cidr_blocks` (list(map(string))): Ingress rules
- `egress_with_cidr_blocks` (list(map(string))): Egress rules
- `tags` (map(string)): Resource tags

## Outputs
- `security_group_id`: Security group ID

## Best Practices
- Restrict ingress to required sources only
- Use tags for management and cost allocation 