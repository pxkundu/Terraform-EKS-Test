# ACM Module

This module provisions an AWS Certificate Manager (ACM) certificate using the official terraform-aws-modules/acm/aws module.

## Features
- Creates an ACM certificate for your domain
- Supports DNS or email validation
- Supports subject alternative names (SANs)

## Usage
```hcl
module "acm" {
  source = "./modules/acm"
  domain_name               = var.domain_name
  validation_method         = var.validation_method
  subject_alternative_names = var.subject_alternative_names
  tags                     = var.tags
}
```

## Variables
- `domain_name` (string): Domain name for the certificate
- `validation_method` (string): Validation method (DNS or EMAIL)
- `subject_alternative_names` (list(string)): SANs
- `tags` (map(string)): Resource tags

## Outputs
- `acm_arn`: ACM certificate ARN

## Best Practices
- Use DNS validation for automation
- Tag certificates for management 