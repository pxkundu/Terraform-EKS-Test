# Karpenter IAM Role and Policy
resource "aws_iam_role" "karpenter_controller" {
  name = "karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role_policy.json
}

data "aws_iam_policy_document" "karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "karpenter_controller_ec2" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "karpenter_controller_custom" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_custom.arn
}

resource "aws_iam_policy" "karpenter_controller_custom" {
  name   = "karpenter-controller-custom"
  policy = data.aws_iam_policy_document.karpenter_controller_custom.json
}

data "aws_iam_policy_document" "karpenter_controller_custom" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:TerminateInstances",
      "ec2:Describe*",
      "ec2:DeleteLaunchTemplate",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

# Karpenter Namespace and Service Account (IRSA)
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

resource "kubernetes_service_account" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
    }
  }
  depends_on = [kubernetes_namespace.karpenter]
}

# Karpenter Helm Chart
resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  namespace  = kubernetes_namespace.karpenter.metadata[0].name
  version    = var.karpenter_helm_version

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.karpenter.metadata[0].name
  }
  set {
    name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }
  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "clusterEndpoint"
    value = var.cluster_endpoint
  }
  set {
    name  = "aws.defaultInstanceProfile"
    value = var.default_instance_profile
  }
  depends_on = [kubernetes_service_account.karpenter]
} 