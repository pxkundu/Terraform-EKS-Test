# ALB Module

This module provisions an Application Load Balancer (ALB) using the official terraform-aws-modules/alb/aws module.

## Features
- Creates an ALB with configurable subnets and security groups
- Supports tagging and integration with EKS

## Usage
```hcl
module "alb" {
  source = "./modules/alb"
  alb_name        = var.alb_name
  subnets         = var.subnets
  security_groups = var.security_groups
  vpc_id          = var.vpc_id
  tags            = var.tags
}
```

## Variables
- `alb_name` (string): Name of the ALB
- `subnets` (list(string)): Subnet IDs
- `security_groups` (list(string)): Security group IDs
- `vpc_id` (string): VPC ID
- `tags` (map(string)): Resource tags

## Outputs
- `alb_arn`: ALB ARN
- `alb_dns_name`: ALB DNS name

## Best Practices
- Use security groups to restrict access
- Tag resources for cost allocation 