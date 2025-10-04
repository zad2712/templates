# =============================================================================
# SECURITY LAYER OUTPUTS
# =============================================================================

# KMS Keys
output "kms_keys" {
  description = "Map of KMS keys"
  value       = module.kms.keys
}

output "kms_key_arns" {
  description = "Map of KMS key ARNs"
  value       = module.kms.key_arns
}

# IAM Roles
output "application_roles" {
  description = "Map of application IAM roles"
  value       = module.iam.application_roles
}

output "service_roles" {
  description = "Map of service IAM roles"
  value       = module.iam.service_roles
}

# Security Groups
output "security_groups" {
  description = "Map of security groups"
  value       = module.security_groups.security_groups
}

output "security_group_ids" {
  description = "Map of security group IDs"
  value       = module.security_groups.security_group_ids
}

# WAF
output "waf_web_acl_id" {
  description = "The ID of the WAF WebACL"
  value       = var.enable_waf ? module.waf[0].web_acl_id : null
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF WebACL"
  value       = var.enable_waf ? module.waf[0].web_acl_arn : null
}

# Secrets Manager
output "secrets" {
  description = "Map of secrets"
  value       = length(var.secrets) > 0 ? module.secrets[0].secrets : {}
  sensitive   = true
}


