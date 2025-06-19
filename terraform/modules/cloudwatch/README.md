# CloudWatch Module

This module provisions CloudWatch log groups and metric alarms for monitoring AWS resources.

## Features
- Creates a log group for application or infrastructure logs
- Sets up a CPU utilization alarm for EC2 instances

## Usage
```hcl
module "cloudwatch" {
  source = "./modules/cloudwatch"
  log_group_name     = var.log_group_name
  retention_in_days  = var.retention_in_days
  alarm_name         = var.alarm_name
  cpu_threshold      = var.cpu_threshold
  alarm_actions      = var.alarm_actions
  instance_id        = var.instance_id
  tags               = var.tags
}
```

## Variables
- `log_group_name` (string): Name of the log group
- `retention_in_days` (number): Log retention period
- `alarm_name` (string): Name of the metric alarm
- `cpu_threshold` (number): CPU threshold for alarm
- `alarm_actions` (list(string)): Actions to take on alarm
- `instance_id` (string): EC2 instance ID
- `tags` (map(string)): Resource tags

## Outputs
- `log_group_arn`: Log group ARN
- `alarm_arn`: Metric alarm ARN

## Best Practices
- Set appropriate retention for log groups
- Use alarms for proactive monitoring 