# Route53 Module

This module provisions a Route53 hosted zone using the official terraform-aws-modules/route53/aws module.

## Features
- Creates a DNS hosted zone for your domain
- Supports tagging for resource management

## Usage
```hcl
module "route53" {
  source = "./modules/route53"
  zone_name = var.zone_name
  tags      = var.tags
}
```

## Variables
- `zone_name` (string): DNS zone name
- `tags` (map(string)): Resource tags

## Outputs
- `zone_id`: Route53 hosted zone ID

## Best Practices
- Use meaningful zone names
- Tag resources for cost allocation 