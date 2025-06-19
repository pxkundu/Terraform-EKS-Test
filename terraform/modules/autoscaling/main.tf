module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name                      = var.asg_name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnets
  launch_template_id        = var.launch_template_id
  target_group_arns         = var.target_group_arns
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  tags                      = var.tags
} 