resource "aws_cloudwatch_log_group" "app" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "This metric monitors EC2 CPU utilization"
  actions_enabled     = true
  alarm_actions       = var.alarm_actions
  dimensions = {
    InstanceId = var.instance_id
  }
  tags = var.tags
} 