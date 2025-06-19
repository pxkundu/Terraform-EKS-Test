# S3 Module

This module provisions an Amazon S3 bucket using the official terraform-aws-modules/s3-bucket/aws module.

## Features
- Creates an S3 bucket with configurable ACL and versioning
- Supports force destroy for easy cleanup

## Usage
```hcl
module "s3" {
  source = "./modules/s3"
  bucket_name        = var.bucket_name
  acl                = var.acl
  versioning_enabled = var.versioning_enabled
  force_destroy      = var.force_destroy
  tags               = var.tags
}
```

## Variables
- `bucket_name` (string): Name of the S3 bucket
- `acl` (string): Access control list (e.g., private, public-read)
- `versioning_enabled` (bool): Enable versioning
- `force_destroy` (bool): Allow bucket deletion with objects
- `tags` (map(string)): Resource tags

## Outputs
- `bucket_arn`: S3 bucket ARN
- `bucket_domain_name`: S3 bucket domain name

## Best Practices
- Use private ACL unless public access is required
- Enable versioning for data protection 