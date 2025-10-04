# Security Layer Outputs

# IAM Outputs
output "iam_role_arns" {
  description = "ARNs of IAM roles"
  value       = module.iam.role_arns
}

output "iam_role_names" {
  description = "Names of IAM roles"
  value       = module.iam.role_names
}

output "iam_policy_arns" {
  description = "ARNs of custom IAM policies"
  value       = module.iam.policy_arns
}

output "iam_group_names" {
  description = "Names of IAM groups"
  value       = module.iam.group_names
}

output "iam_user_names" {
  description = "Names of IAM users"
  value       = module.iam.user_names
}

output "iam_user_access_keys" {
  description = "IAM user access keys"
  value       = module.iam.user_access_keys
  sensitive   = true
}

# KMS Outputs
output "kms_key_ids" {
  description = "KMS key IDs"
  value       = module.kms.key_ids
}

output "kms_key_arns" {
  description = "KMS key ARNs"
  value       = module.kms.key_arns
}

output "kms_alias_names" {
  description = "KMS alias names"
  value       = module.kms.alias_names
}

output "kms_alias_arns" {
  description = "KMS alias ARNs"
  value       = module.kms.alias_arns
}

# Secrets Manager Outputs
output "secret_arns" {
  description = "Secrets Manager secret ARNs"
  value       = module.secrets_manager.secret_arns
}

output "secret_names" {
  description = "Secrets Manager secret names"
  value       = module.secrets_manager.secret_names
}

output "secret_versions" {
  description = "Secrets Manager secret versions"
  value       = module.secrets_manager.secret_versions
}

# WAF Outputs
output "waf_web_acl_ids" {
  description = "WAF Web ACL IDs"
  value       = var.enable_waf ? module.waf[0].web_acl_ids : {}
}

output "waf_web_acl_arns" {
  description = "WAF Web ACL ARNs"
  value       = var.enable_waf ? module.waf[0].web_acl_arns : {}
}

# CloudWatch Outputs
output "cloudwatch_log_group_names" {
  description = "CloudWatch Log Group names"
  value = {
    application = aws_cloudwatch_log_group.application_logs.name
    ecs         = aws_cloudwatch_log_group.ecs_logs.name
    lambda      = aws_cloudwatch_log_group.lambda_logs.name
  }
}

output "cloudwatch_log_group_arns" {
  description = "CloudWatch Log Group ARNs"
  value = {
    application = aws_cloudwatch_log_group.application_logs.arn
    ecs         = aws_cloudwatch_log_group.ecs_logs.arn
    lambda      = aws_cloudwatch_log_group.lambda_logs.arn
  }
}

# SNS Outputs
output "sns_topic_arns" {
  description = "SNS Topic ARNs"
  value = {
    alerts = aws_sns_topic.alerts.arn
  }
}

output "sns_topic_names" {
  description = "SNS Topic names"
  value = {
    alerts = aws_sns_topic.alerts.name
  }
}

# Integration Outputs
output "integration_config" {
  description = "Configuration for integration with other layers"
  value = {
    # ECS Task Execution Role for ECS services
    ecs_task_execution_role_arn = module.iam.role_arns["ecs_task_execution"]
    
    # ECS Task Role for application permissions
    ecs_task_role_arn = module.iam.role_arns["ecs_task"]
    
    # EKS Service Roles
    eks_cluster_role_arn    = module.iam.role_arns["eks_cluster"]
    eks_node_group_role_arn = module.iam.role_arns["eks_node_group"]
    
    # Lambda Execution Role
    lambda_execution_role_arn = module.iam.role_arns["lambda_execution"]
    
    # RDS Monitoring Role
    rds_monitoring_role_arn = module.iam.role_arns["rds_monitoring"]
    
    # API Gateway CloudWatch Role
    api_gateway_cloudwatch_role_arn = module.iam.role_arns["api_gateway_cloudwatch"]
    
    # KMS Keys for different services
    kms_keys = {
      application = module.kms.key_ids["application"]
      rds         = module.kms.key_ids["rds"]
      s3          = module.kms.key_ids["s3"]
      lambda      = module.kms.key_ids["lambda"]
      secrets     = module.kms.key_ids["secrets"]
      logs        = module.kms.key_ids["logs"]
    }
    
    # Secrets for applications
    secrets = {
      rds_master_password_arn = module.secrets_manager.secret_arns["rds_master_password"]
      api_keys_arn           = module.secrets_manager.secret_arns["api_keys"]
      jwt_keys_arn           = module.secrets_manager.secret_arns["jwt_keys"]
    }
    
    # WAF Web ACL ARN for ALB/API Gateway
    waf_web_acl_arn = var.enable_waf ? module.waf[0].web_acl_arns["application"] : null
    
    # SNS Topic for alerts
    alerts_topic_arn = aws_sns_topic.alerts.arn
    
    # CloudWatch Log Groups
    log_groups = {
      application = aws_cloudwatch_log_group.application_logs.name
      ecs         = aws_cloudwatch_log_group.ecs_logs.name
      lambda      = aws_cloudwatch_log_group.lambda_logs.name
    }
  }
}

# Security Summary
output "security_summary" {
  description = "Security configuration summary"
  value = {
    iam_roles_created       = length(module.iam.role_arns)
    kms_keys_created        = length(module.kms.key_ids)
    secrets_created         = length(module.secrets_manager.secret_arns)
    waf_enabled            = var.enable_waf
    log_retention_days     = var.log_retention_days
    secret_rotation_enabled = var.enable_secret_rotation
    cross_region_backup     = var.enable_cross_region_backup
    
    compliance_features = {
      config_enabled       = var.enable_config
      cloudtrail_enabled   = var.enable_cloudtrail
      guardduty_enabled    = var.enable_guardduty
      security_hub_enabled = var.enable_security_hub
    }
  }
}