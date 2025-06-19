variable "bucket_name" { type = string }
variable "acl" { type = string }
variable "versioning_enabled" { type = bool }
variable "force_destroy" { type = bool }
variable "tags" { type = map(string) } 