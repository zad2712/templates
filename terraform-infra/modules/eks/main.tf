# =============================================================================
# EKS MODULE - BEST PRACTICES WITH COST OPTIMIZATION
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# =============================================================================
# EKS CLUSTER IAM ROLE
# =============================================================================

resource "aws_iam_role" "cluster" {
  count = var.create_cluster ? 1 : 0
  
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  count = var.create_cluster ? 1 : 0
  
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

# =============================================================================
# EKS CLUSTER
# =============================================================================

resource "aws_eks_cluster" "main" {
  count = var.create_cluster ? 1 : 0
  
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster[0].arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = var.cluster_additional_security_group_ids
  }

  # Enable control plane logging
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Encryption configuration
  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.cluster
  ]

  tags = var.tags
}

# =============================================================================
# CLOUDWATCH LOG GROUP FOR CLUSTER
# =============================================================================

resource "aws_cloudwatch_log_group" "cluster" {
  count = var.create_cluster && length(var.cluster_enabled_log_types) > 0 ? 1 : 0
  
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  tags              = var.tags
}

# =============================================================================
# NODE GROUP IAM ROLE
# =============================================================================

resource "aws_iam_role" "node_group" {
  count = var.create_cluster && length(var.node_groups) > 0 ? 1 : 0
  
  name               = "${var.cluster_name}-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  count = var.create_cluster && length(var.node_groups) > 0 ? 1 : 0
  
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  count = var.create_cluster && length(var.node_groups) > 0 ? 1 : 0
  
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  count = var.create_cluster && length(var.node_groups) > 0 ? 1 : 0
  
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group[0].name
}

# =============================================================================
# EKS NODE GROUPS
# =============================================================================

resource "aws_eks_node_group" "main" {
  for_each = var.create_cluster ? var.node_groups : {}

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_group[0].arn
  subnet_ids      = each.value.subnet_ids

  # Instance configuration
  instance_types = each.value.instance_types
  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = each.value.max_unavailable_percentage
  }

  # Launch template configuration
  dynamic "launch_template" {
    for_each = each.value.launch_template_id != null ? [1] : []
    content {
      id      = each.value.launch_template_id
      version = each.value.launch_template_version
    }
  }

  # Taints
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = each.value.labels
  tags   = merge(var.tags, each.value.tags)

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy,
  ]
}

# =============================================================================
# EKS FARGATE PROFILE IAM ROLE
# =============================================================================

resource "aws_iam_role" "fargate_profile" {
  count = var.create_cluster && length(var.fargate_profiles) > 0 ? 1 : 0
  
  name = "${var.cluster_name}-fargate-profile-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "fargate_profile_policy" {
  count = var.create_cluster && length(var.fargate_profiles) > 0 ? 1 : 0
  
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_profile[0].name
}

# =============================================================================
# EKS FARGATE PROFILES
# =============================================================================

resource "aws_eks_fargate_profile" "main" {
  for_each = var.create_cluster ? var.fargate_profiles : {}

  cluster_name           = aws_eks_cluster.main[0].name
  fargate_profile_name   = each.key
  pod_execution_role_arn = aws_iam_role.fargate_profile[0].arn
  subnet_ids            = each.value.subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    aws_iam_role_policy_attachment.fargate_profile_policy
  ]
}

# =============================================================================
# EKS ADDONS
# =============================================================================

resource "aws_eks_addon" "main" {
  for_each = var.create_cluster ? var.cluster_addons : {}

  cluster_name             = aws_eks_cluster.main[0].name
  addon_name               = each.key
  addon_version            = each.value.addon_version
  resolve_conflicts        = each.value.resolve_conflicts
  service_account_role_arn = each.value.service_account_role_arn

  tags = var.tags

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_fargate_profile.main
  ]
}