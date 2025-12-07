# Azure Kubernetes Service (AKS) Module
# This module creates an AKS cluster with managed identity and cluster autoscaler

# User-assigned managed identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Default node pool
  default_node_pool {
    name            = "default"
    vm_size         = var.vm_size
    vnet_subnet_id  = var.subnet_ids[0]
    min_count       = var.min_node_count
    max_count       = var.max_node_count
    os_disk_size_gb = 50
    type            = "VirtualMachineScaleSets"
  }

  # Network configuration
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  # RBAC configuration
  role_based_access_control_enabled = true

  # Azure AD integration (optional)
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  # OMS Agent (Azure Monitor) integration
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

# Additional node pool (optional)
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  count                 = var.enable_additional_node_pool ? 1 : 0
  name                  = "additional"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.additional_pool_vm_size
  min_count             = var.additional_pool_min_count
  max_count             = var.additional_pool_max_count
  os_disk_size_gb       = 50
  vnet_subnet_id        = length(var.subnet_ids) > 1 ? var.subnet_ids[1] : var.subnet_ids[0]

  tags = var.tags
}

