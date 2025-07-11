region          = "us-east-1"
vpc_name        = "dev-eks-vpc"
vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
cluster_name    = "dev-eks-cluster"
cluster_version = "1.27"
