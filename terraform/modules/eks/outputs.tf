output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig" {
  description = "Kubeconfig file for cluster access"
  value = <<-EOT
apiVersion: v1
clusters:
- cluster:
    server: ${data.aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${data.aws_eks_cluster.cluster.certificate_authority[0].data}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: ${var.cluster_name}
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
kind: Config
preferences: {}
users:
- name: ${var.cluster_name}
  user:
    token: ${data.aws_eks_cluster_auth.cluster.token}
EOT
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL for IRSA"
  value       = module.eks.oidc_provider
}
