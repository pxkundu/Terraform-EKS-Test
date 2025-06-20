# Autoscaling Module

This module provisions an EC2 Auto Scaling Group using the official terraform-aws-modules/autoscaling/aws module.

## Features
- Creates an Auto Scaling Group with configurable size and launch template
- Supports health checks and target group integration

## Usage
```hcl
module "autoscaling" {
  source = "./modules/autoscaling"
  asg_name                  = var.asg_name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  subnets                   = var.subnets
  launch_template_id        = var.launch_template_id
  target_group_arns         = var.target_group_arns
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  tags                      = var.tags
}
```

## Variables
- `asg_name` (string): Name of the Auto Scaling Group
- `min_size` (number): Minimum group size
- `max_size` (number): Maximum group size
- `desired_capacity` (number): Desired group size
- `subnets` (list(string)): Subnet IDs
- `launch_template_id` (string): Launch template ID
- `target_group_arns` (list(string)): Target group ARNs
- `health_check_type` (string): Health check type
- `health_check_grace_period` (number): Health check grace period
- `tags` (map(string)): Resource tags

## Outputs
- `autoscaling_group_arn`: Auto Scaling Group ARN

## Best Practices
- Use launch templates for flexibility
- Set health checks for reliability 