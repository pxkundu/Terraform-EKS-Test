output "log_group_arn" {
  value = aws_cloudwatch_log_group.app.arn
}

output "alarm_arn" {
  value = aws_cloudwatch_metric_alarm.cpu_utilization.arn
} 