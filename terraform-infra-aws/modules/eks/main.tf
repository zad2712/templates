# EKS Module - Main Configuration
# Author: Diego A. Zarate

terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EKS Service Role Policy Document
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# EKS Node Group Role Policy Document
data "aws_iam_policy_document" "node_group_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Locals for resource naming and configuration
locals {
  # Common tags
  common_tags = merge(var.tags, {
    Module      = "eks"
    Terraform   = "true"
    Environment = var.tags.Environment
    ManagedBy   = "terraform"
  })

  # EKS Clusters configuration
  eks_clusters = {
    for cluster_name, cluster_config in var.eks_clusters : cluster_name => {
      # Basic Configuration
      name     = "${var.name_prefix}-${cluster_name}"
      version  = cluster_config.version
      role_arn = aws_iam_role.eks_cluster_role[cluster_name].arn

      # VPC Configuration
      vpc_config = {
        subnet_ids              = cluster_config.subnet_ids
        endpoint_private_access = cluster_config.endpoint_private_access
        endpoint_public_access  = cluster_config.endpoint_public_access
        public_access_cidrs     = cluster_config.public_access_cidrs
        security_group_ids      = cluster_config.security_group_ids
      }

      # Encryption Configuration
      encryption_config = cluster_config.encryption_config

      # Logging Configuration
      enabled_cluster_log_types = cluster_config.enabled_cluster_log_types

      # Access Configuration
      access_config = cluster_config.access_config

      tags = merge(local.common_tags, cluster_config.tags, {
        Name = "${var.name_prefix}-${cluster_name}"
        Type = "eks-cluster"
      })
    }
  }

  # Node Groups configuration
  node_groups = {
    for node_group_key, node_group_config in flatten([
      for cluster_name, cluster_config in var.eks_clusters : [
        for ng_name, ng_config in cluster_config.node_groups : {
          key             = "${cluster_name}-${ng_name}"
          cluster_name    = cluster_name
          node_group_name = ng_name
          config          = ng_config
        }
      ]
    ]) : node_group_key.key => {
      cluster_name         = node_group_key.cluster_name
      node_group_name      = "${var.name_prefix}-${node_group_key.cluster_name}-${node_group_key.node_group_name}"
      node_role_arn        = aws_iam_role.node_group_role[node_group_key.cluster_name].arn
      subnet_ids           = node_group_key.config.subnet_ids
      capacity_type        = node_group_key.config.capacity_type
      ami_type             = node_group_key.config.ami_type
      instance_types       = node_group_key.config.instance_types
      disk_size            = node_group_key.config.disk_size

      # Scaling Configuration
      scaling_config = node_group_key.config.scaling_config

      # Update Configuration
      update_config = node_group_key.config.update_config

      # Remote Access Configuration
      remote_access = node_group_key.config.remote_access

      # Launch Template
      launch_template = node_group_key.config.launch_template

      # Labels and Taints
      labels = node_group_key.config.labels
      taints = node_group_key.config.taints

      tags = merge(local.common_tags, node_group_key.config.tags, {
        Name         = "${var.name_prefix}-${node_group_key.cluster_name}-${node_group_key.node_group_name}"
        Type         = "eks-node-group"
        Cluster      = node_group_key.cluster_name
        CapacityType = node_group_key.config.capacity_type
      })
    }
  }

  # Fargate Profiles configuration
  fargate_profiles = {
    for profile_key, profile_config in flatten([
      for cluster_name, cluster_config in var.eks_clusters : [
        for fp_name, fp_config in cluster_config.fargate_profiles : {
          key          = "${cluster_name}-${fp_name}"
          cluster_name = cluster_name
          profile_name = fp_name
          config       = fp_config
        }
      ]
    ]) : profile_key.key => {
      cluster_name           = profile_key.cluster_name
      fargate_profile_name   = "${var.name_prefix}-${profile_key.cluster_name}-${profile_key.profile_name}"
      pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role[profile_key.cluster_name].arn
      subnet_ids             = profile_key.config.subnet_ids

      # Selectors
      selectors = profile_key.config.selectors

      tags = merge(local.common_tags, profile_key.config.tags, {
        Name    = "${var.name_prefix}-${profile_key.cluster_name}-${profile_key.profile_name}"
        Type    = "eks-fargate-profile"
        Cluster = profile_key.cluster_name
      })
    }
  }

  # Add-ons configuration
  addons = {
    for addon_key, addon_config in flatten([
      for cluster_name, cluster_config in var.eks_clusters : [
        for addon_name, addon_cfg in cluster_config.addons : {
          key          = "${cluster_name}-${addon_name}"
          cluster_name = cluster_name
          addon_name   = addon_name
          config       = addon_cfg
        }
      ]
    ]) : addon_key.key => {
      cluster_name    = addon_key.cluster_name
      addon_name      = addon_key.addon_name
      addon_version   = addon_key.config.addon_version
      resolve_conflicts_on_create = addon_key.config.resolve_conflicts_on_create
      resolve_conflicts_on_update = addon_key.config.resolve_conflicts_on_update
      service_account_role_arn    = addon_key.config.service_account_role_arn
      configuration_values        = addon_key.config.configuration_values

      tags = merge(local.common_tags, addon_key.config.tags, {
        Name    = "${var.name_prefix}-${addon_key.cluster_name}-${addon_key.addon_name}"
        Type    = "eks-addon"
        Cluster = addon_key.cluster_name
        Addon   = addon_key.addon_name
      })
    }
  }
}

# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster_role" {
  for_each = var.eks_clusters

  name = "${var.name_prefix}-${each.key}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-cluster-role"
    Type = "eks-cluster-role"
  })
}

# Attach required policies to EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  for_each = var.eks_clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role[each.key].name
}

# EKS VPC Resource Controller Policy (for security groups)
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  for_each = var.eks_clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role[each.key].name
}

# EKS Node Group Role
resource "aws_iam_role" "node_group_role" {
  for_each = var.eks_clusters

  name = "${var.name_prefix}-${each.key}-node-group-role"

  assume_role_policy = data.aws_iam_policy_document.node_group_assume_role_policy.json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-node-group-role"
    Type = "eks-node-group-role"
  })
}

# Attach required policies to Node Group Role
resource "aws_iam_role_policy_attachment" "node_group_worker_node_policy" {
  for_each = var.eks_clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  for_each = var.eks_clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_registry_readonly" {
  for_each = var.eks_clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role[each.key].name
}

# Fargate Pod Execution Role
resource "aws_iam_role" "fargate_pod_execution_role" {
  for_each = {
    for cluster_name, cluster_config in var.eks_clusters : cluster_name => cluster_config
    if length(cluster_config.fargate_profiles) > 0
  }

  name = "${var.name_prefix}-${each.key}-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-fargate-pod-execution-role"
    Type = "eks-fargate-role"
  })
}

# Attach Fargate Pod Execution Role Policy
resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy" {
  for_each = {
    for cluster_name, cluster_config in var.eks_clusters : cluster_name => cluster_config
    if length(cluster_config.fargate_profiles) > 0
  }

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role[each.key].name
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  for_each = local.eks_clusters

  name     = each.value.name
  role_arn = each.value.role_arn
  version  = each.value.version

  vpc_config {
    subnet_ids              = each.value.vpc_config.subnet_ids
    endpoint_private_access = each.value.vpc_config.endpoint_private_access
    endpoint_public_access  = each.value.vpc_config.endpoint_public_access
    public_access_cidrs     = each.value.vpc_config.public_access_cidrs
    security_group_ids      = each.value.vpc_config.security_group_ids
  }

  # Encryption Configuration
  dynamic "encryption_config" {
    for_each = each.value.encryption_config != null ? [each.value.encryption_config] : []
    content {
      provider {
        key_arn = encryption_config.value.provider.key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  # Logging Configuration
  enabled_cluster_log_types = each.value.enabled_cluster_log_types

  # Access Configuration
  dynamic "access_config" {
    for_each = each.value.access_config != null ? [each.value.access_config] : []
    content {
      authentication_mode                         = access_config.value.authentication_mode
      bootstrap_cluster_creator_admin_permissions = access_config.value.bootstrap_cluster_creator_admin_permissions
    }
  }

  tags = each.value.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}

# EKS Node Groups
resource "aws_eks_node_group" "this" {
  for_each = local.node_groups

  cluster_name    = aws_eks_cluster.this[each.value.cluster_name].name
  node_group_name = each.value.node_group_name
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids

  capacity_type  = each.value.capacity_type
  ami_type      = each.value.ami_type
  instance_types = each.value.instance_types
  disk_size     = each.value.disk_size

  # Scaling Configuration
  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  # Update Configuration
  dynamic "update_config" {
    for_each = each.value.update_config != null ? [each.value.update_config] : []
    content {
      max_unavailable_percentage = update_config.value.max_unavailable_percentage
      max_unavailable           = update_config.value.max_unavailable
    }
  }

  # Remote Access Configuration
  dynamic "remote_access" {
    for_each = each.value.remote_access != null ? [each.value.remote_access] : []
    content {
      ec2_ssh_key               = remote_access.value.ec2_ssh_key
      source_security_group_ids = remote_access.value.source_security_group_ids
    }
  }

  # Launch Template
  dynamic "launch_template" {
    for_each = each.value.launch_template != null ? [each.value.launch_template] : []
    content {
      id      = launch_template.value.id
      name    = launch_template.value.name
      version = launch_template.value.version
    }
  }

  # Labels
  labels = each.value.labels

  # Taints
  dynamic "taint" {
    for_each = each.value.taints != null ? each.value.taints : []
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = each.value.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_node_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_readonly
  ]

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}

# EKS Fargate Profiles
resource "aws_eks_fargate_profile" "this" {
  for_each = local.fargate_profiles

  cluster_name           = aws_eks_cluster.this[each.value.cluster_name].name
  fargate_profile_name   = each.value.fargate_profile_name
  pod_execution_role_arn = each.value.pod_execution_role_arn
  subnet_ids             = each.value.subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = each.value.tags

  depends_on = [
    aws_iam_role_policy_attachment.fargate_pod_execution_role_policy
  ]
}

# EKS Add-ons
resource "aws_eks_addon" "this" {
  for_each = local.addons

  cluster_name             = aws_eks_cluster.this[each.value.cluster_name].name
  addon_name               = each.value.addon_name
  addon_version            = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  service_account_role_arn = each.value.service_account_role_arn
  configuration_values     = each.value.configuration_values

  tags = each.value.tags

  depends_on = [
    aws_eks_node_group.this,
    aws_eks_fargate_profile.this
  ]
}

# OIDC Identity Provider for the cluster
resource "aws_iam_openid_connect_provider" "eks" {
  for_each = var.eks_clusters

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[each.key].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-oidc"
    Type = "eks-oidc-provider"
  })
}

# Get the TLS certificate for OIDC
data "tls_certificate" "eks" {
  for_each = var.eks_clusters

  url = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer
}

# CloudWatch Log Group for EKS Cluster Logs
resource "aws_cloudwatch_log_group" "eks" {
  for_each = {
    for cluster_name, cluster_config in var.eks_clusters : cluster_name => cluster_config
    if length(cluster_config.enabled_cluster_log_types) > 0
  }

  name              = "/aws/eks/${aws_eks_cluster.this[each.key].name}/cluster"
  retention_in_days = var.log_retention_in_days
  kms_key_id       = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-logs"
    Type = "eks-log-group"
  })
}