# Variables for Azure OpenAI Module

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region/location"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "enable_cognitive_search" {
  description = "Enable Azure Cognitive Search for RAG capabilities"
  type        = bool
  default     = false
}

variable "enable_model_logging" {
  description = "Enable model invocation logging"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor monitoring and alerts"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 30
}

variable "openai_sku" {
  description = "SKU for Azure OpenAI (S0, S1, etc.)"
  type        = string
  default     = "S0"
}

variable "vnet_id" {
  description = "VNet ID for private endpoints (optional)"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for private endpoints"
  type        = list(string)
  default     = []
}

variable "create_private_endpoints" {
  description = "Create private endpoints for OpenAI"
  type        = bool
  default     = false
}

variable "deployment_models" {
  description = "List of OpenAI model deployments"
  type = list(object({
    name     = string
    model    = string
    version  = string
    capacity = optional(number)
  }))
  default = [
    {
      name     = "gpt-4"
      model    = "gpt-4"
      version  = "0613"
      capacity = 1
    },
    {
      name     = "gpt-35-turbo"
      model    = "gpt-35-turbo"
      version  = "0613"
      capacity = 1
    }
  ]
}

variable "max_tokens" {
  description = "Maximum tokens for model responses"
  type        = number
  default     = 4096
}

variable "temperature" {
  description = "Temperature for model responses (0.0 to 1.0)"
  type        = number
  default     = 0.7
  validation {
    condition     = var.temperature >= 0.0 && var.temperature <= 1.0
    error_message = "Temperature must be between 0.0 and 1.0."
  }
}

variable "top_p" {
  description = "Top-p for model responses (0.0 to 1.0)"
  type        = number
  default     = 0.9
  validation {
    condition     = var.top_p >= 0.0 && var.top_p <= 1.0
    error_message = "Top-p must be between 0.0 and 1.0."
  }
}

variable "enable_streaming" {
  description = "Enable streaming responses"
  type        = bool
  default     = true
}

variable "enable_content_filter" {
  description = "Enable content filtering for OpenAI"
  type        = bool
  default     = true
}

