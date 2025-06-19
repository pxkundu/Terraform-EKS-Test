module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = var.bucket_name
  acl    = var.acl
  versioning = {
    enabled = var.versioning_enabled
  }
  force_destroy = var.force_destroy
  tags = var.tags
} 