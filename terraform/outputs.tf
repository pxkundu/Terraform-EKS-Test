output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig" {
  description = "Kubeconfig file for cluster access"
  value       = module.eks.kubeconfig
  sensitive   = true  
}