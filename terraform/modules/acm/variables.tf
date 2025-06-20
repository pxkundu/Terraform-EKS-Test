variable "domain_name" { type = string }
variable "validation_method" { type = string }
variable "subject_alternative_names" { type = list(string) }
variable "tags" { type = map(string) } 