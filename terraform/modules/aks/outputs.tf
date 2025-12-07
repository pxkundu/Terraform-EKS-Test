output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "cluster_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "kubeconfig" {
  description = "Kubeconfig for cluster access"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_resource_group_name" {
  description = "Resource group name where AKS nodes are deployed"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

