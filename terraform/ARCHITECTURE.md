# Project Architecture

This diagram illustrates how the main AWS infrastructure components in this project interact and work together:

```mermaid
flowchart TD
  subgraph AWS
    VPC[VPC]
    Subnets[Public & Private Subnets]
    EKS[EKS Cluster]
    Karpenter[Karpenter Autoscaler]
    NodeGroups[Managed Node Groups]
    ALB[Application Load Balancer]
    RDS[RDS Database]
    S3[S3 Bucket]
    EFS[EFS File System]
    Route53[Route53 DNS]
    ACM[ACM Certificates]
    CloudWatch[CloudWatch Logs & Alarms]
    Autoscaling[EC2 Auto Scaling Group]
    SG[Security Groups]
    IAM[IAM Roles & Policies]
  end

  Route53 --> ALB
  ACM --> ALB
  ALB --> EKS
  EKS --> NodeGroups
  EKS --> Karpenter
  Karpenter --> NodeGroups
  NodeGroups --> Subnets
  Subnets --> VPC
  EKS --> S3
  EKS --> EFS
  EKS --> RDS
  EKS --> CloudWatch
  EKS --> Autoscaling
  EKS --> SG
  EKS --> IAM
  Karpenter --> IAM
  RDS --> SG
  ALB --> SG
  Autoscaling --> SG
  EFS --> SG
  S3 --> IAM
  CloudWatch --> IAM
  EKS --> Route53
  EKS --> ACM

  classDef aws fill:#f9f,stroke:#333,stroke-width:1px;
  class AWS aws;
```

**Legend:**
- All resources are provisioned and managed by Terraform modules in this project.
- Arrows indicate primary relationships or dependencies (e.g., EKS nodes run in subnets, ALB routes to EKS, etc.).
- Karpenter dynamically manages node scaling for EKS. 