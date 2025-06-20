variable "efs_name" { type = string }
variable "vpc_id" { type = string }
variable "subnets" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "tags" { type = map(string) } 