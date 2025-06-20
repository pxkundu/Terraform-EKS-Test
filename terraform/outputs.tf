output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig" {
  description = "Kubeconfig file for cluster access"
  value       = module.eks.kubeconfig
  sensitive   = true  
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL for IRSA"
  value       = module.eks.oidc_provider_url
}