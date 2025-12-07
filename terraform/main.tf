# Azure Provider Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend configuration - uncomment and configure after initial deployment
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstate<unique-suffix>"
  #   container_name       = "tfstate"
  #   key                  = "<environment>/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Resource Group for Application Resources
resource "azurerm_resource_group" "main" {
  name     = "${var.cluster_name}-rg"
  location = var.location

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "openwebui-azure"
    ManagedBy   = "terraform"
  })
}

# Resource Group for Terraform State (if creating backend storage)
resource "azurerm_resource_group" "tfstate" {
  count    = var.create_backend_storage ? 1 : 0
  name     = "terraform-state-rg"
  location = var.location

  tags = merge(var.tags, {
    Purpose     = "TerraformState"
    ManagedBy   = "terraform"
  })
}

# Backend Storage Account Module (for Terraform state)
module "backend" {
  count  = var.create_backend_storage ? 1 : 0
  source = "./modules/backend"

  resource_group_name = azurerm_resource_group.tfstate[0].name
  location            = var.location
  project_name        = var.cluster_name
  environment         = var.environment
  vnet_id             = module.vnet.vnet_id
  private_subnet_id   = length(module.vnet.private_subnets) > 0 ? module.vnet.private_subnets[0] : null
  create_private_endpoint = var.backend_private_endpoint
  allowed_subnet_ids      = var.backend_allowed_subnets
  allowed_ip_ranges       = var.backend_allowed_ips

  tags = var.tags
}

module "vnet" {
  source = "./modules/vnet"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = var.vpc_name
  vnet_cidr           = var.vpc_cidr
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  cluster_name        = var.cluster_name
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "openwebui-azure"
    ManagedBy   = "terraform"
  })
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  cluster_name        = var.cluster_name
  kubernetes_version  = var.cluster_version
  vnet_id             = module.vnet.vnet_id
  subnet_ids          = module.vnet.private_subnets
  node_count          = 2
  vm_size             = "Standard_D2s_v3"
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "openwebui-azure"
    ManagedBy   = "terraform"
  })
}

module "openai" {
  source = "./modules/openai"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.cluster_name
  environment         = var.environment
  
  # Enable cognitive services for RAG capabilities
  enable_cognitive_search = true
  
  # Enable model invocation logging
  enable_model_logging = true
  
  # Enable monitoring and alerts
  enable_monitoring = true
  
  # VNet configuration for private endpoints
  vnet_id                = module.vnet.vnet_id
  private_subnet_ids     = module.vnet.private_subnets
  create_private_endpoints = true
  
  # Model configuration - Azure OpenAI models
  deployment_models = [
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
    },
    {
      name     = "text-embedding-ada-002"
      model    = "text-embedding-ada-002"
      version  = "2"
      capacity = 1
    }
  ]
  
  # Response configuration
  max_tokens      = 4096
  temperature     = 0.7
  top_p           = 0.9
  enable_streaming = true
  
  # Logging configuration
  log_retention_days = 30
  
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "openwebui-azure"
    ManagedBy   = "terraform"
  })
}

# Database Module (PostgreSQL)
module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.cluster_name
  environment         = var.environment
  vnet_id             = module.vnet.vnet_id
  subnet_id           = length(module.vnet.private_subnets) > 1 ? module.vnet.private_subnets[1] : module.vnet.private_subnets[0]
  
  database_name    = var.database_name
  db_username      = var.database_username
  db_password      = var.database_password
  postgres_version = var.postgres_version
  sku_name         = var.database_sku
  storage_mb        = var.database_storage_mb
  
  backup_retention_days = var.database_backup_retention_days
  geo_redundant_backup  = var.database_geo_redundant_backup
  
  allowed_subnet_ids   = module.vnet.private_subnets
  allowed_subnet_cidrs = var.private_subnets
  allow_azure_services = var.database_allow_azure_services
  
  tenant_id                      = var.tenant_id
  managed_identity_principal_id = module.aks.cluster_identity_principal_id
  log_analytics_workspace_id     = module.openai.log_analytics_workspace_id

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = "openwebui-azure"
    ManagedBy   = "terraform"
  })
}

resource "null_resource" "deploy_nginx" {
  depends_on = [module.aks]

  provisioner "local-exec" {
    command = <<EOT
      az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${var.cluster_name} --overwrite-existing
      kubectl apply -f ${path.module}/scripts/nginx-daemonset.yaml
    EOT
  }
}

resource "null_resource" "deploy_openwebui" {
  depends_on = [module.openai, module.aks]

  provisioner "local-exec" {
    command = <<EOT
      az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${var.cluster_name} --overwrite-existing
      
      # Replace placeholders in OpenWebUI deployment for Azure
      sed -i.bak "s/\${OPENAI_ENDPOINT}/${module.openai.openai_endpoint}/g" ${path.module}/modules/openai/openwebui-deployment.yaml
      sed -i.bak "s/\${OPENAI_API_KEY}/${module.openai.openai_api_key}/g" ${path.module}/modules/openai/openwebui-deployment.yaml
      sed -i.bak "s/\${AZURE_LOCATION}/${var.location}/g" ${path.module}/modules/openai/openwebui-deployment.yaml
      sed -i.bak "s/\${INGRESS_HOST}/openwebui.local/g" ${path.module}/modules/openai/openwebui-deployment.yaml
      
      # Deploy OpenWebUI
      kubectl apply -f ${path.module}/modules/openai/openwebui-deployment.yaml
    EOT
  }
}
