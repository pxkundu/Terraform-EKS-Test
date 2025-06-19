variable "alb_name" { type = string }
variable "subnets" { type = list(string) }
variable "security_groups" { type = list(string) }
variable "vpc_id" { type = string }
variable "tags" { type = map(string) } 