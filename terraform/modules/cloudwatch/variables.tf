variable "log_group_name" { type = string }
variable "retention_in_days" { type = number }
variable "alarm_name" { type = string }
variable "cpu_threshold" { type = number }
variable "alarm_actions" { type = list(string) }
variable "instance_id" { type = string }
variable "tags" { type = map(string) } 