module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name               = var.domain_name
  validation_method         = var.validation_method
  subject_alternative_names = var.subject_alternative_names
  tags                     = var.tags
} 