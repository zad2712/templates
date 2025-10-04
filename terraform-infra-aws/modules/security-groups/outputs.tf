# Security Groups Module - Outputs
# Author: Diego A. Zarate

# Web Tier Security Group Outputs
output "web_sg_id" {
  description = "ID of the web tier security group"
  value       = var.create_web_sg ? aws_security_group.web[0].id : null
}

output "web_sg_arn" {
  description = "ARN of the web tier security group"
  value       = var.create_web_sg ? aws_security_group.web[0].arn : null
}

output "web_sg_name" {
  description = "Name of the web tier security group"
  value       = var.create_web_sg ? aws_security_group.web[0].name : null
}

# Application Tier Security Group Outputs
output "app_sg_id" {
  description = "ID of the application tier security group"
  value       = var.create_app_sg ? aws_security_group.app[0].id : null
}

output "app_sg_arn" {
  description = "ARN of the application tier security group"
  value       = var.create_app_sg ? aws_security_group.app[0].arn : null
}

output "app_sg_name" {
  description = "Name of the application tier security group"
  value       = var.create_app_sg ? aws_security_group.app[0].name : null
}

# Database Tier Security Group Outputs
output "db_sg_id" {
  description = "ID of the database tier security group"
  value       = var.create_db_sg ? aws_security_group.db[0].id : null
}

output "db_sg_arn" {
  description = "ARN of the database tier security group"
  value       = var.create_db_sg ? aws_security_group.db[0].arn : null
}

output "db_sg_name" {
  description = "Name of the database tier security group"
  value       = var.create_db_sg ? aws_security_group.db[0].name : null
}

# Cache Tier Security Group Outputs
output "cache_sg_id" {
  description = "ID of the cache tier security group"
  value       = var.create_cache_sg ? aws_security_group.cache[0].id : null
}

output "cache_sg_arn" {
  description = "ARN of the cache tier security group"
  value       = var.create_cache_sg ? aws_security_group.cache[0].arn : null
}

output "cache_sg_name" {
  description = "Name of the cache tier security group"
  value       = var.create_cache_sg ? aws_security_group.cache[0].name : null
}

# Management/Bastion Security Group Outputs
output "management_sg_id" {
  description = "ID of the management/bastion security group"
  value       = var.create_management_sg ? aws_security_group.management[0].id : null
}

output "management_sg_arn" {
  description = "ARN of the management/bastion security group"
  value       = var.create_management_sg ? aws_security_group.management[0].arn : null
}

output "management_sg_name" {
  description = "Name of the management/bastion security group"
  value       = var.create_management_sg ? aws_security_group.management[0].name : null
}

# Lambda Security Group Outputs
output "lambda_sg_id" {
  description = "ID of the Lambda security group"
  value       = var.create_lambda_sg ? aws_security_group.lambda[0].id : null
}

output "lambda_sg_arn" {
  description = "ARN of the Lambda security group"
  value       = var.create_lambda_sg ? aws_security_group.lambda[0].arn : null
}

output "lambda_sg_name" {
  description = "Name of the Lambda security group"
  value       = var.create_lambda_sg ? aws_security_group.lambda[0].name : null
}

# EKS Cluster Security Group Outputs
output "eks_cluster_sg_id" {
  description = "ID of the EKS cluster security group"
  value       = var.create_eks_cluster_sg ? aws_security_group.eks_cluster[0].id : null
}

output "eks_cluster_sg_arn" {
  description = "ARN of the EKS cluster security group"
  value       = var.create_eks_cluster_sg ? aws_security_group.eks_cluster[0].arn : null
}

output "eks_cluster_sg_name" {
  description = "Name of the EKS cluster security group"
  value       = var.create_eks_cluster_sg ? aws_security_group.eks_cluster[0].name : null
}

# EKS Worker Nodes Security Group Outputs
output "eks_workers_sg_id" {
  description = "ID of the EKS worker nodes security group"
  value       = var.create_eks_workers_sg ? aws_security_group.eks_workers[0].id : null
}

output "eks_workers_sg_arn" {
  description = "ARN of the EKS worker nodes security group"
  value       = var.create_eks_workers_sg ? aws_security_group.eks_workers[0].arn : null
}

output "eks_workers_sg_name" {
  description = "Name of the EKS worker nodes security group"
  value       = var.create_eks_workers_sg ? aws_security_group.eks_workers[0].name : null
}

# Custom Security Groups Outputs
output "custom_sg_ids" {
  description = "Map of custom security group names to their IDs"
  value = {
    for k, v in aws_security_group.custom : k => v.id
  }
}

output "custom_sg_arns" {
  description = "Map of custom security group names to their ARNs"
  value = {
    for k, v in aws_security_group.custom : k => v.arn
  }
}

output "custom_sg_names" {
  description = "Map of custom security group names to their names"
  value = {
    for k, v in aws_security_group.custom : k => v.name
  }
}

# Consolidated Outputs for Easy Reference
output "all_sg_ids" {
  description = "Map of all security group types to their IDs"
  value = {
    web         = var.create_web_sg ? aws_security_group.web[0].id : null
    app         = var.create_app_sg ? aws_security_group.app[0].id : null
    db          = var.create_db_sg ? aws_security_group.db[0].id : null
    cache       = var.create_cache_sg ? aws_security_group.cache[0].id : null
    management  = var.create_management_sg ? aws_security_group.management[0].id : null
    lambda      = var.create_lambda_sg ? aws_security_group.lambda[0].id : null
    eks_cluster = var.create_eks_cluster_sg ? aws_security_group.eks_cluster[0].id : null
    eks_workers = var.create_eks_workers_sg ? aws_security_group.eks_workers[0].id : null
  }
}

output "all_sg_arns" {
  description = "Map of all security group types to their ARNs"
  value = {
    web         = var.create_web_sg ? aws_security_group.web[0].arn : null
    app         = var.create_app_sg ? aws_security_group.app[0].arn : null
    db          = var.create_db_sg ? aws_security_group.db[0].arn : null
    cache       = var.create_cache_sg ? aws_security_group.cache[0].arn : null
    management  = var.create_management_sg ? aws_security_group.management[0].arn : null
    lambda      = var.create_lambda_sg ? aws_security_group.lambda[0].arn : null
    eks_cluster = var.create_eks_cluster_sg ? aws_security_group.eks_cluster[0].arn : null
    eks_workers = var.create_eks_workers_sg ? aws_security_group.eks_workers[0].arn : null
  }
}

# Security Group Creation Status
output "security_groups_created" {
  description = "Map showing which security groups were created"
  value = {
    web         = var.create_web_sg
    app         = var.create_app_sg
    db          = var.create_db_sg
    cache       = var.create_cache_sg
    management  = var.create_management_sg
    lambda      = var.create_lambda_sg
    eks_cluster = var.create_eks_cluster_sg
    eks_workers = var.create_eks_workers_sg
    custom      = length(var.custom_security_groups) > 0
  }
}

# Tier-Specific Collections for Integration
output "web_tier_sg_ids" {
  description = "List of security group IDs for web tier components"
  value = compact([
    var.create_web_sg ? aws_security_group.web[0].id : null
  ])
}

output "app_tier_sg_ids" {
  description = "List of security group IDs for application tier components"
  value = compact([
    var.create_app_sg ? aws_security_group.app[0].id : null,
    var.create_lambda_sg ? aws_security_group.lambda[0].id : null,
    var.create_eks_workers_sg ? aws_security_group.eks_workers[0].id : null
  ])
}

output "data_tier_sg_ids" {
  description = "List of security group IDs for data tier components"
  value = compact([
    var.create_db_sg ? aws_security_group.db[0].id : null,
    var.create_cache_sg ? aws_security_group.cache[0].id : null
  ])
}

output "management_tier_sg_ids" {
  description = "List of security group IDs for management components"
  value = compact([
    var.create_management_sg ? aws_security_group.management[0].id : null,
    var.create_eks_cluster_sg ? aws_security_group.eks_cluster[0].id : null
  ])
}