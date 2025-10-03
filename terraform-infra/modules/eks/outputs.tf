# =============================================================================
# EKS MODULE OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].id : null
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].arn : null
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].name : null
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = var.create_cluster ? aws_eks_cluster.main[0].endpoint : null
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].version : null
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].platform_version : null
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].status : null
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id : null
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].certificate_authority[0].data : null
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = var.create_cluster ? aws_eks_cluster.main[0].identity[0].oidc[0].issuer : null
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster"
  value       = var.create_cluster ? aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id : null
}

# =============================================================================
# NODE GROUP OUTPUTS
# =============================================================================

output "node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      arn               = v.arn
      status            = v.status
      capacity_type     = v.capacity_type
      instance_types    = v.instance_types
      ami_type          = v.ami_type
      node_group_name   = v.node_group_name
      subnet_ids        = v.subnet_ids
      scaling_config    = v.scaling_config
    }
  }
}

output "node_group_arns" {
  description = "List of the EKS managed node group ARNs"
  value       = [for ng in aws_eks_node_group.main : ng.arn]
}

output "node_group_status" {
  description = "Status of the EKS managed node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.status }
}

# =============================================================================
# FARGATE PROFILE OUTPUTS  
# =============================================================================

output "fargate_profiles" {
  description = "Map of attribute maps for all EKS Fargate profiles created"
  value = {
    for k, v in aws_eks_fargate_profile.main : k => {
      arn                    = v.arn
      status                 = v.status
      fargate_profile_name   = v.fargate_profile_name
      pod_execution_role_arn = v.pod_execution_role_arn
    }
  }
}

# =============================================================================
# IAM ROLE OUTPUTS
# =============================================================================

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = var.create_cluster ? aws_iam_role.cluster[0].name : null
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = var.create_cluster ? aws_iam_role.cluster[0].arn : null
}

output "node_group_iam_role_name" {
  description = "IAM role name associated with EKS node group"
  value       = var.create_cluster && length(var.node_groups) > 0 ? aws_iam_role.node_group[0].name : null
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN associated with EKS node group"
  value       = var.create_cluster && length(var.node_groups) > 0 ? aws_iam_role.node_group[0].arn : null
}

output "fargate_profile_iam_role_name" {
  description = "IAM role name associated with EKS Fargate profile"
  value       = var.create_cluster && length(var.fargate_profiles) > 0 ? aws_iam_role.fargate_profile[0].name : null
}

output "fargate_profile_iam_role_arn" {
  description = "IAM role ARN associated with EKS Fargate profile"
  value       = var.create_cluster && length(var.fargate_profiles) > 0 ? aws_iam_role.fargate_profile[0].arn : null
}

# =============================================================================
# ADDON OUTPUTS
# =============================================================================

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value = {
    for k, v in aws_eks_addon.main : k => {
      arn               = v.arn
      status            = v.status
      addon_version     = v.addon_version
      service_account_role_arn = v.service_account_role_arn
    }
  }
}

# =============================================================================
# CONFIGURATION OUTPUTS FOR KUBECTL
# =============================================================================

output "kubectl_config" {
  description = "kubectl config as generated by the module"
  value = var.create_cluster ? {
    cluster_name                     = aws_eks_cluster.main[0].name
    endpoint                        = aws_eks_cluster.main[0].endpoint
    cluster_ca_certificate          = aws_eks_cluster.main[0].certificate_authority[0].data
    cluster_security_group_id       = aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id
    aws_auth_configmap_yaml         = ""  # Will be populated by kubernetes provider
  } : null
  sensitive = true
}
