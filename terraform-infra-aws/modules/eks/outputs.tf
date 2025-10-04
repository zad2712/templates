# EKS Module - Outputs
# Author: Diego A. Zarate

# EKS Cluster Outputs
output "eks_clusters" {
  description = "Map of EKS cluster information"
  value = {
    for cluster_name, cluster in aws_eks_cluster.this : cluster_name => {
      arn                   = cluster.arn
      id                    = cluster.id
      name                  = cluster.name
      endpoint              = cluster.endpoint
      version               = cluster.version
      platform_version      = cluster.platform_version
      status                = cluster.status
      certificate_authority = cluster.certificate_authority
      identity              = cluster.identity
      vpc_config            = cluster.vpc_config
      created_at           = cluster.created_at
      tags                 = cluster.tags_all
    }
  }
}

output "cluster_endpoints" {
  description = "EKS cluster endpoints"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.endpoint }
}

output "cluster_arns" {
  description = "EKS cluster ARNs"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.arn }
}

output "cluster_ids" {
  description = "EKS cluster IDs"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.id }
}

output "cluster_names" {
  description = "EKS cluster names"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.name }
}

output "cluster_versions" {
  description = "EKS cluster Kubernetes versions"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.version }
}

output "cluster_platform_versions" {
  description = "EKS cluster platform versions"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.platform_version }
}

output "cluster_certificate_authorities" {
  description = "EKS cluster certificate authority data"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.certificate_authority }
}

output "cluster_security_group_ids" {
  description = "EKS cluster security group IDs"
  value = {
    for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.vpc_config[0].cluster_security_group_id
  }
}

# IAM Role Outputs
output "cluster_iam_roles" {
  description = "Map of EKS cluster IAM role information"
  value = {
    for cluster_name, role in aws_iam_role.eks_cluster_role : cluster_name => {
      arn  = role.arn
      name = role.name
      id   = role.id
    }
  }
}

output "cluster_iam_role_arns" {
  description = "EKS cluster IAM role ARNs"
  value       = { for cluster_name, role in aws_iam_role.eks_cluster_role : cluster_name => role.arn }
}

output "node_group_iam_roles" {
  description = "Map of EKS node group IAM role information"
  value = {
    for cluster_name, role in aws_iam_role.node_group_role : cluster_name => {
      arn  = role.arn
      name = role.name
      id   = role.id
    }
  }
}

output "node_group_iam_role_arns" {
  description = "EKS node group IAM role ARNs"
  value       = { for cluster_name, role in aws_iam_role.node_group_role : cluster_name => role.arn }
}

output "fargate_pod_execution_roles" {
  description = "Map of EKS Fargate pod execution role information"
  value = {
    for cluster_name, role in aws_iam_role.fargate_pod_execution_role : cluster_name => {
      arn  = role.arn
      name = role.name
      id   = role.id
    }
  }
}

output "fargate_pod_execution_role_arns" {
  description = "EKS Fargate pod execution role ARNs"
  value       = { for cluster_name, role in aws_iam_role.fargate_pod_execution_role : cluster_name => role.arn }
}

# Node Group Outputs
output "node_groups" {
  description = "Map of EKS node group information"
  value = {
    for ng_name, node_group in aws_eks_node_group.this : ng_name => {
      arn           = node_group.arn
      id            = node_group.id
      cluster_name  = node_group.cluster_name
      node_group_name = node_group.node_group_name
      capacity_type = node_group.capacity_type
      ami_type      = node_group.ami_type
      instance_types = node_group.instance_types
      disk_size     = node_group.disk_size
      scaling_config = node_group.scaling_config
      status        = node_group.status
      version       = node_group.version
      release_version = node_group.release_version
      resources     = node_group.resources
      tags          = node_group.tags_all
    }
  }
}

output "node_group_arns" {
  description = "EKS node group ARNs"
  value       = { for ng_name, node_group in aws_eks_node_group.this : ng_name => node_group.arn }
}

output "node_group_statuses" {
  description = "EKS node group statuses"
  value       = { for ng_name, node_group in aws_eks_node_group.this : ng_name => node_group.status }
}

output "node_group_versions" {
  description = "EKS node group Kubernetes versions"
  value       = { for ng_name, node_group in aws_eks_node_group.this : ng_name => node_group.version }
}

output "node_group_resources" {
  description = "EKS node group resources (Auto Scaling Groups, etc.)"
  value       = { for ng_name, node_group in aws_eks_node_group.this : ng_name => node_group.resources }
}

# Fargate Profile Outputs
output "fargate_profiles" {
  description = "Map of EKS Fargate profile information"
  value = {
    for fp_name, fargate_profile in aws_eks_fargate_profile.this : fp_name => {
      arn                   = fargate_profile.arn
      id                    = fargate_profile.id
      cluster_name          = fargate_profile.cluster_name
      fargate_profile_name  = fargate_profile.fargate_profile_name
      pod_execution_role_arn = fargate_profile.pod_execution_role_arn
      subnet_ids           = fargate_profile.subnet_ids
      selectors            = fargate_profile.selector
      status               = fargate_profile.status
      tags                 = fargate_profile.tags_all
    }
  }
}

output "fargate_profile_arns" {
  description = "EKS Fargate profile ARNs"
  value       = { for fp_name, fargate_profile in aws_eks_fargate_profile.this : fp_name => fargate_profile.arn }
}

output "fargate_profile_statuses" {
  description = "EKS Fargate profile statuses"
  value       = { for fp_name, fargate_profile in aws_eks_fargate_profile.this : fp_name => fargate_profile.status }
}

# Add-on Outputs
output "addons" {
  description = "Map of EKS add-on information"
  value = {
    for addon_name, addon in aws_eks_addon.this : addon_name => {
      arn           = addon.arn
      id            = addon.id
      cluster_name  = addon.cluster_name
      addon_name    = addon.addon_name
      addon_version = addon.addon_version
      status        = addon.status
      created_at    = addon.created_at
      modified_at   = addon.modified_at
      tags          = addon.tags_all
    }
  }
}

output "addon_arns" {
  description = "EKS add-on ARNs"
  value       = { for addon_name, addon in aws_eks_addon.this : addon_name => addon.arn }
}

output "addon_statuses" {
  description = "EKS add-on statuses"
  value       = { for addon_name, addon in aws_eks_addon.this : addon_name => addon.status }
}

output "addon_versions" {
  description = "EKS add-on versions"
  value       = { for addon_name, addon in aws_eks_addon.this : addon_name => addon.addon_version }
}

# OIDC Identity Provider Outputs
output "oidc_providers" {
  description = "Map of EKS OIDC identity provider information"
  value = {
    for cluster_name, oidc in aws_iam_openid_connect_provider.eks : cluster_name => {
      arn = oidc.arn
      url = oidc.url
    }
  }
}

output "oidc_provider_arns" {
  description = "EKS OIDC identity provider ARNs"
  value       = { for cluster_name, oidc in aws_iam_openid_connect_provider.eks : cluster_name => oidc.arn }
}

output "oidc_issuer_urls" {
  description = "EKS OIDC issuer URLs"
  value       = { for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.identity[0].oidc[0].issuer }
}

# CloudWatch Log Group Outputs
output "cloudwatch_log_groups" {
  description = "Map of EKS CloudWatch log group information"
  value = {
    for cluster_name, log_group in aws_cloudwatch_log_group.eks : cluster_name => {
      arn  = log_group.arn
      name = log_group.name
    }
  }
}

output "cloudwatch_log_group_names" {
  description = "EKS CloudWatch log group names"
  value       = { for cluster_name, log_group in aws_cloudwatch_log_group.eks : cluster_name => log_group.name }
}

output "cloudwatch_log_group_arns" {
  description = "EKS CloudWatch log group ARNs"
  value       = { for cluster_name, log_group in aws_cloudwatch_log_group.eks : cluster_name => log_group.arn }
}

# Capacity Type Summaries
output "on_demand_node_groups" {
  description = "List of on-demand node groups"
  value = [
    for ng_key, ng_config in local.node_groups : ng_key
    if ng_config.capacity_type == "ON_DEMAND"
  ]
}

output "spot_node_groups" {
  description = "List of spot node groups"
  value = [
    for ng_key, ng_config in local.node_groups : ng_key
    if ng_config.capacity_type == "SPOT"
  ]
}

# AMI Type Summaries
output "linux_node_groups" {
  description = "List of Linux-based node groups"
  value = [
    for ng_key, ng_config in local.node_groups : ng_key
    if can(regex("^AL2_", ng_config.ami_type)) || can(regex("^BOTTLEROCKET_", ng_config.ami_type))
  ]
}

output "windows_node_groups" {
  description = "List of Windows-based node groups"
  value = [
    for ng_key, ng_config in local.node_groups : ng_key
    if can(regex("^WINDOWS_", ng_config.ami_type))
  ]
}

# Kubernetes Configuration
output "kubeconfig_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value = {
    for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.certificate_authority[0].data
  }
}

output "kubeconfig" {
  description = "kubectl configuration for connecting to EKS clusters"
  value = {
    for cluster_name, cluster in aws_eks_cluster.this : cluster_name => {
      apiVersion      = "v1"
      kind           = "Config"
      current_context = cluster.name
      contexts = [
        {
          name = cluster.name
          context = {
            cluster = cluster.name
            user    = cluster.name
          }
        }
      ]
      clusters = [
        {
          name = cluster.name
          cluster = {
            server                     = cluster.endpoint
            certificate_authority_data = cluster.certificate_authority[0].data
          }
        }
      ]
      users = [
        {
          name = cluster.name
          user = {
            exec = {
              apiVersion = "client.authentication.k8s.io/v1beta1"
              command    = "aws"
              args = [
                "eks",
                "get-token",
                "--cluster-name",
                cluster.name
              ]
            }
          }
        }
      ]
    }
  }
}

# Summary Statistics
output "total_clusters" {
  description = "Total number of EKS clusters"
  value       = length(aws_eks_cluster.this)
}

output "total_node_groups" {
  description = "Total number of EKS node groups"
  value       = length(aws_eks_node_group.this)
}

output "total_fargate_profiles" {
  description = "Total number of EKS Fargate profiles"
  value       = length(aws_eks_fargate_profile.this)
}

output "total_addons" {
  description = "Total number of EKS add-ons"
  value       = length(aws_eks_addon.this)
}

# Security Group Information
output "cluster_primary_security_groups" {
  description = "EKS cluster primary security group IDs"
  value = {
    for cluster_name, cluster in aws_eks_cluster.this : cluster_name => cluster.vpc_config[0].cluster_security_group_id
  }
}

# Module Information
output "module_info" {
  description = "EKS module information"
  value = {
    module_name       = "eks"
    module_version    = "1.0.0"
    created_at        = timestamp()
    provider_version  = "~> 5.0"
    terraform_version = ">= 1.9.0"
  }
}