# IAM Module - Local Values
# Author: Diego A. Zarate
# Local values for processing complex data structures and relationships

locals {
  # Process role AWS managed policy attachments
  role_aws_managed_policies = flatten([
    for role_name, role_config in var.iam_roles : [
      for policy_arn in lookup(role_config, "aws_managed_policies", []) : {
        role_name  = role_name
        policy_arn = policy_arn
      }
    ]
  ])

  # Process role custom managed policy attachments
  role_custom_managed_policies = flatten([
    for role_name, role_config in var.iam_roles : [
      for policy_name in lookup(role_config, "custom_managed_policies", []) : {
        role_name    = role_name
        policy_name  = policy_name
      }
    ]
  ])

  # Process group AWS managed policy attachments
  group_aws_managed_policies = flatten([
    for group_name, group_config in var.iam_groups : [
      for policy_arn in lookup(group_config, "aws_managed_policies", []) : {
        group_name = group_name
        policy_arn = policy_arn
      }
    ]
  ])

  # Process group custom managed policy attachments
  group_custom_managed_policies = flatten([
    for group_name, group_config in var.iam_groups : [
      for policy_name in lookup(group_config, "custom_managed_policies", []) : {
        group_name  = group_name
        policy_name = policy_name
      }
    ]
  ])

  # Process group memberships
  group_memberships = {
    for group_name, group_config in var.iam_groups :
    group_name => {
      group_name = group_name
      users      = lookup(group_config, "users", [])
    }
    if length(lookup(group_config, "users", [])) > 0
  }

  # Identify EC2 roles for instance profiles
  ec2_roles = {
    for role_name, role_config in var.iam_roles :
    role_name => role_config
    if role_config.principal_type == "Service" && 
       contains(role_config.principal_identifiers, "ec2.amazonaws.com")
  }

  # Convert role AWS managed policies list to map for for_each
  role_aws_managed_policies_map = {
    for item in local.role_aws_managed_policies :
    "${item.role_name}-${replace(item.policy_arn, "/", "-")}" => item
  }

  # Convert role custom managed policies list to map for for_each
  role_custom_managed_policies_map = {
    for item in local.role_custom_managed_policies :
    "${item.role_name}-${item.policy_name}" => item
  }

  # Convert group AWS managed policies list to map for for_each
  group_aws_managed_policies_map = {
    for item in local.group_aws_managed_policies :
    "${item.group_name}-${replace(item.policy_arn, "/", "-")}" => item
  }

  # Convert group custom managed policies list to map for for_each
  group_custom_managed_policies_map = {
    for item in local.group_custom_managed_policies :
    "${item.group_name}-${item.policy_name}" => item
  }
}

# Update the main.tf to use the map versions
# This fixes the "for_each set includes values that cannot be determined until apply" error