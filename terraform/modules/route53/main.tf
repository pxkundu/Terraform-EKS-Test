module "route53" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 2.0"

  zone_name = var.zone_name
  tags      = var.tags
} 