# Terraform AWS EKS Cluster Project

## Project Structure

```
terraform/
├── environments/
│   └── dev/
│       └── terraform.tfvars
├── modules/
│   ├── eks/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── scripts/
├── main.tf
├── outputs.tf
├── variables.tf
└── README.md
```

## Prerequisites

- AWS CLI installed and configured with the "exam3" profile (`aws configure --profile exam3`).
- Terraform >= 1.0.0 installed.
- Appropriate IAM permissions for the "exam3" profile to create and delete VPC, EKS, EC2, and IAM resources.

## Setup and Deployment

1. Navigate to the project root:

   ```bash
   cd terraform
   ```
2. Set the AWS profile to "exam3":

   ```bash
   export AWS_PROFILE=exam3
   ```

   Verify the profile:

   ```bash
   aws sts get-caller-identity --profile exam3
   ```
3. Initialize Terraform to download providers and modules:

   ```bash
   terraform init
   ```
4. Navigate to the development environment:

   ```bash
   cd environments/dev
   ```
5. Plan the deployment using the environment-specific variables:

   ```bash
   terraform plan -var-file=terraform.tfvars
   ```
6. Apply the configuration to deploy the EKS cluster:

   ```bash
   terraform apply -var-file=terraform.tfvars
   ```

   Confirm with `yes` when prompted. Deployment may take 10-15 minutes.
7. Save the kubeconfig for cluster access:

   ```bash
   terraform output -raw kubeconfig > kubeconfig.yaml
   ```
8. Test cluster access:

   ```bash
   export KUBECONFIG=$(pwd)/kubeconfig.yaml
   kubectl get nodes
   ```

## Testing

- Verify cluster endpoint:

  ```bash
  kubectl cluster-info
  ```
- Confirm 2 t3.medium nodes are running:

  ```bash
  kubectl get nodes
  ```
- Check VPC and subnets:

  ```bash
  aws ec2 describe-vpcs --profile exam3
  ```

## Cleanup

To destroy all resources created by this project and avoid ongoing AWS costs, follow these steps:

1. Navigate to the `environments/dev` directory:

   ```bash
   cd environments/dev
   ```

2. Ensure the "exam3" AWS profile is set:

   ```bash
   export AWS_PROFILE=exam3
   ```

   Verify the profile:

   ```bash
   aws sts get-caller-identity --profile exam3
   ```

3. Run the destroy command:

   ```bash
   terraform destroy -var-file=terraform.tfvars
   ```

   - Confirm with `yes` when prompted.
   - This will delete all resources (EKS cluster, VPC, subnets, IAM roles, etc.) created by the Terraform configuration.
   - The process may take 10-15 minutes due to EKS cluster deletion.

4. Verify resource deletion:

   ```bash
   aws eks describe-cluster --name dev-eks-cluster --profile exam3
   aws ec2 describe-vpcs --profile exam3
   ```

   - The EKS cluster should return a "not found" error.
   - No VPCs with the tag `kubernetes.io/cluster/dev-eks-cluster` should remain.

5. (Optional) Remove the Terraform state files to clean up the local environment:

   ```bash
   rm terraform.tfstate terraform.tfstate.backup
   ```

   **Warning**: Only remove state files if you are certain no further management of these resources is needed, as this prevents Terraform from tracking previously created resources.

## Troubleshooting

- **Sensitive Output Error**: If you encounter an error about sensitive values in `kubeconfig`, add `sensitive = true` to the `kubeconfig` output in `outputs.tf`:

  ```hcl
  output "kubeconfig" {
    description = "Kubeconfig file for cluster access"
    value       = module.eks.kubeconfig
    sensitive   = true
  }
  ```
- **Inline Policy Warning**: The `terraform-aws-modules/eks/aws` module may show a deprecation warning for `inline_policy`. This can be ignored for now or resolved by updating the module version in `modules/eks/main.tf` to `~> 20.0` and running `terraform init -upgrade`.
- **Permission Issues**: Ensure the "exam3" profile has permissions for EKS, VPC, EC2, and IAM actions.
- **Destroy Failures**: If the destroy process fails, check for dependent resources (e.g., ENIs or security groups) in the AWS Console and manually delete them, then re-run `terraform destroy`.