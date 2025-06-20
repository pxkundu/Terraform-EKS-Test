module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.0"

  name      = var.efs_name
  vpc_id    = var.vpc_id
  subnets   = var.subnets
  security_group_ids = var.security_group_ids
  tags      = var.tags
} 