module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  name                = var.role_name
  create_role         = true
  role_requires_mfa   = false
  trusted_role_arns   = var.trusted_role_arns
  policy_arns         = var.policy_arns
  tags                = var.tags
} 