output "karpenter_service_account_name" {
  value = kubernetes_service_account.karpenter.metadata[0].name
}

output "karpenter_iam_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
} 