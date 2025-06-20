# IAM Module

This module provisions IAM roles and policies using the official terraform-aws-modules/iam/aws module.

## Features
- Creates IAM roles with trust relationships and attached policies
- Supports custom trusted roles and policy ARNs

## Usage
```hcl
module "iam" {
  source = "./modules/iam"
  role_name         = var.role_name
  trusted_role_arns = var.trusted_role_arns
  policy_arns       = var.policy_arns
  tags              = var.tags
}
```

## Variables
- `role_name` (string): Name of the IAM role
- `trusted_role_arns` (list(string)): ARNs of trusted roles
- `policy_arns` (list(string)): ARNs of policies to attach
- `tags` (map(string)): Resource tags

## Outputs
- `role_arn`: IAM role ARN

## Best Practices
- Use least privilege for policies
- Use tags for role management 