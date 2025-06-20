variable "role_name" { type = string }
variable "trusted_role_arns" { type = list(string) }
variable "policy_arns" { type = list(string) }
variable "tags" { type = map(string) } 