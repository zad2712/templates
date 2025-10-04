# =============================================================================
# IAM MODULE OUTPUTS
# =============================================================================

output "roles" {
  description = "Map of IAM roles created"
  value = {
    for k, v in aws_iam_role.roles : k => {
      arn  = v.arn
      name = v.name
      id   = v.id
    }
  }
}

output "role_arns" {
  description = "Map of IAM role ARNs"
  value       = { for k, v in aws_iam_role.roles : k => v.arn }
}

output "role_names" {
  description = "Map of IAM role names"
  value       = { for k, v in aws_iam_role.roles : k => v.name }
}

output "policies" {
  description = "Map of IAM policies created"
  value = {
    for k, v in aws_iam_policy.policies : k => {
      arn = v.arn
      id  = v.id
    }
  }
}

output "policy_arns" {
  description = "Map of IAM policy ARNs"
  value       = { for k, v in aws_iam_policy.policies : k => v.arn }
}

output "groups" {
  description = "Map of IAM groups created"
  value = {
    for k, v in aws_iam_group.groups : k => {
      arn  = v.arn
      name = v.name
      id   = v.id
    }
  }
}

output "users" {
  description = "Map of IAM users created"
  value = {
    for k, v in aws_iam_user.users : k => {
      arn  = v.arn
      name = v.name
      id   = v.id
    }
  }
}

output "instance_profiles" {
  description = "Map of IAM instance profiles created"
  value = {
    for k, v in aws_iam_instance_profile.instance_profiles : k => {
      arn  = v.arn
      name = v.name
      id   = v.id
    }
  }
}
