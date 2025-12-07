variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region/location"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.27"
}

variable "vnet_id" {
  description = "ID of the Virtual Network"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the AKS cluster"
  type        = list(string)
}

variable "node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the default node pool"
  type        = number
  default     = 10
}

variable "vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_additional_node_pool" {
  description = "Enable additional node pool"
  type        = bool
  default     = false
}

variable "additional_pool_vm_size" {
  description = "VM size for the additional node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "additional_pool_node_count" {
  description = "Initial number of nodes in the additional node pool"
  type        = number
  default     = 1
}

variable "additional_pool_min_count" {
  description = "Minimum number of nodes in the additional node pool"
  type        = number
  default     = 1
}

variable "additional_pool_max_count" {
  description = "Maximum number of nodes in the additional node pool"
  type        = number
  default     = 5
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = null
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

