module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = var.security_groups
  vpc_id             = var.vpc_id
  tags               = var.tags
} 