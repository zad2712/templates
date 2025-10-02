# =============================================================================
# SECURITY GROUPS MODULE OUTPUTS
# =============================================================================

output "security_groups" {
  description = "Map of security groups created"
  value = {
    for k, v in aws_security_group.security_groups : k => {
      id          = v.id
      arn         = v.arn
      name        = v.name
      description = v.description
      vpc_id      = v.vpc_id
      owner_id    = v.owner_id
    }
  }
}

output "security_group_ids" {
  description = "Map of security group IDs"
  value       = { for k, v in aws_security_group.security_groups : k => v.id }
}

output "security_group_arns" {
  description = "Map of security group ARNs"
  value       = { for k, v in aws_security_group.security_groups : k => v.arn }
}
