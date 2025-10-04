# IAM Module - Outputs
# Author: Diego A. Zarate

# Role Outputs
output "role_arns" {
  description = "Map of role names to their ARNs"
  value = {
    for k, v in aws_iam_role.this : k => v.arn
  }
}

output "role_names" {
  description = "Map of role names to their names"
  value = {
    for k, v in aws_iam_role.this : k => v.name
  }
}

output "role_ids" {
  description = "Map of role names to their unique IDs"
  value = {
    for k, v in aws_iam_role.this : k => v.unique_id
  }
}

# Policy Outputs
output "policy_arns" {
  description = "Map of policy names to their ARNs"
  value = {
    for k, v in aws_iam_policy.this : k => v.arn
  }
}

output "policy_names" {
  description = "Map of policy names to their names"
  value = {
    for k, v in aws_iam_policy.this : k => v.name
  }
}

output "policy_ids" {
  description = "Map of policy names to their IDs"
  value = {
    for k, v in aws_iam_policy.this : k => v.policy_id
  }
}

# Group Outputs
output "group_arns" {
  description = "Map of group names to their ARNs"
  value = {
    for k, v in aws_iam_group.this : k => v.arn
  }
}

output "group_names" {
  description = "Map of group names to their names"
  value = {
    for k, v in aws_iam_group.this : k => v.name
  }
}

output "group_ids" {
  description = "Map of group names to their unique IDs"
  value = {
    for k, v in aws_iam_group.this : k => v.unique_id
  }
}

# User Outputs (only if users are created)
output "user_arns" {
  description = "Map of user names to their ARNs"
  value = var.create_users ? {
    for k, v in aws_iam_user.this : k => v.arn
  } : {}
}

output "user_names" {
  description = "Map of user names to their names"
  value = var.create_users ? {
    for k, v in aws_iam_user.this : k => v.name
  } : {}
}

output "user_ids" {
  description = "Map of user names to their unique IDs"
  value = var.create_users ? {
    for k, v in aws_iam_user.this : k => v.unique_id
  } : {}
}

# Access Key Outputs (sensitive)
output "access_key_ids" {
  description = "Map of user names to their access key IDs"
  value = var.create_access_keys ? {
    for k, v in aws_iam_access_key.this : k => v.id
  } : {}
}

output "secret_access_keys" {
  description = "Map of user names to their secret access keys"
  value = var.create_access_keys ? {
    for k, v in aws_iam_access_key.this : k => v.secret
  } : {}
  sensitive = true
}

# Instance Profile Outputs
output "instance_profile_arns" {
  description = "Map of instance profile names to their ARNs"
  value = {
    for k, v in aws_iam_instance_profile.this : k => v.arn
  }
}

output "instance_profile_names" {
  description = "Map of instance profile names to their names"
  value = {
    for k, v in aws_iam_instance_profile.this : k => v.name
  }
}

# Service-Linked Role Outputs
output "service_linked_role_arns" {
  description = "Map of service-linked role names to their ARNs"
  value = {
    for k, v in aws_iam_service_linked_role.this : k => v.arn
  }
}

output "service_linked_role_names" {
  description = "Map of service-linked role names to their names"
  value = {
    for k, v in aws_iam_service_linked_role.this : k => v.name
  }
}

# Identity Provider Outputs
output "oidc_provider_arns" {
  description = "Map of OIDC provider names to their ARNs"
  value = {
    for k, v in aws_iam_openid_connect_provider.this : k => v.arn
  }
}

output "saml_provider_arns" {
  description = "Map of SAML provider names to their ARNs"
  value = {
    for k, v in aws_iam_saml_provider.this : k => v.arn
  }
}

# Account Configuration Outputs
output "account_alias" {
  description = "The account alias"
  value       = var.account_alias
}

output "password_policy_enabled" {
  description = "Whether password policy is enabled"
  value       = var.create_account_password_policy
}

# Consolidated Outputs for Easy Reference
output "all_roles" {
  description = "Complete information about all created roles"
  value = {
    for k, v in aws_iam_role.this : k => {
      arn                  = v.arn
      name                 = v.name
      unique_id           = v.unique_id
      assume_role_policy  = v.assume_role_policy
      max_session_duration = v.max_session_duration
      path                = v.path
      permissions_boundary = v.permissions_boundary
      tags                = v.tags
    }
  }
}

output "all_policies" {
  description = "Complete information about all created policies"
  value = {
    for k, v in aws_iam_policy.this : k => {
      arn         = v.arn
      name        = v.name
      policy_id   = v.policy_id
      description = v.description
      path        = v.path
      tags        = v.tags
    }
  }
}

# Common Service Role ARNs (for easy reference)
output "common_service_roles" {
  description = "ARNs of commonly used service roles"
  value = {
    ec2_roles    = [for k, v in aws_iam_role.this : v.arn if contains(lookup(var.iam_roles[k], "principal_identifiers", []), "ec2.amazonaws.com")]
    lambda_roles = [for k, v in aws_iam_role.this : v.arn if contains(lookup(var.iam_roles[k], "principal_identifiers", []), "lambda.amazonaws.com")]
    eks_roles    = [for k, v in aws_iam_role.this : v.arn if contains(lookup(var.iam_roles[k], "principal_identifiers", []), "eks.amazonaws.com")]
    ecs_roles    = [for k, v in aws_iam_role.this : v.arn if contains(lookup(var.iam_roles[k], "principal_identifiers", []), "ecs-tasks.amazonaws.com")]
  }
}

# Security and Compliance Information
output "security_summary" {
  description = "Summary of IAM security configuration"
  value = {
    total_roles                = length(aws_iam_role.this)
    total_policies            = length(aws_iam_policy.this)
    total_groups              = length(aws_iam_group.this)
    total_users               = length(aws_iam_user.this)
    users_created             = var.create_users
    access_keys_created       = var.create_access_keys
    password_policy_enabled   = var.create_account_password_policy
    account_alias_set         = var.account_alias != null
    instance_profiles_created = length(aws_iam_instance_profile.this)
    service_linked_roles      = length(aws_iam_service_linked_role.this)
    oidc_providers           = length(aws_iam_openid_connect_provider.this)
    saml_providers           = length(aws_iam_saml_provider.this)
  }
}