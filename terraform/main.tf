provider "aws" {
  region  = var.region
  profile = "exam3"
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name       = var.vpc_name
  vpc_cidr       = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  cluster_name    = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnets
}

module "karpenter" {
  source = "./modules/karpenter"

  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  cluster_name           = var.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  default_instance_profile = "eksctl-${var.cluster_name}-nodegroup-ng-NodeInstanceProfile"
  karpenter_helm_version = "v0.34.0" # Use latest stable or pin as needed
}

resource "null_resource" "deploy_nginx" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${path.module}/kubeconfig.yaml
      kubectl apply -f ${path.module}/scripts/nginx-daemonset.yaml
    EOT
  }
}
