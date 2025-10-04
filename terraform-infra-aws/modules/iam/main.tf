# IAM Module - Main Configuration
# Author: Diego A. Zarate
# This module creates IAM resources following AWS best practices and least privilege principles

# Data sources for AWS managed policies
data "aws_iam_policy_document" "assume_role_policy" {
  for_each = var.iam_roles

  statement {
    effect = "Allow"
    
    principals {
      type        = each.value.principal_type
      identifiers = each.value.principal_identifiers
    }
    
    actions = ["sts:AssumeRole"]
    
    dynamic "condition" {
      for_each = lookup(each.value, "assume_role_conditions", [])
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

# IAM Roles
resource "aws_iam_role" "this" {
  for_each = var.iam_roles

  name                  = "${var.name_prefix}-${each.key}-role"
  description           = each.value.description
  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy[each.key].json
  max_session_duration  = lookup(each.value, "max_session_duration", 3600)
  path                  = lookup(each.value, "path", "/")
  permissions_boundary  = lookup(each.value, "permissions_boundary", null)
  force_detach_policies = lookup(each.value, "force_detach_policies", true)

  dynamic "inline_policy" {
    for_each = lookup(each.value, "inline_policies", [])
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}-role"
  })
}

# Attach AWS managed policies to roles
resource "aws_iam_role_policy_attachment" "aws_managed" {
  for_each = local.role_aws_managed_policies_map

  role       = aws_iam_role.this[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

# Attach custom managed policies to roles
resource "aws_iam_role_policy_attachment" "custom_managed" {
  for_each = local.role_custom_managed_policies_map

  role       = aws_iam_role.this[each.value.role_name].name
  policy_arn = aws_iam_policy.this[each.value.policy_name].arn

  depends_on = [aws_iam_policy.this]
}

# Custom IAM Policies
resource "aws_iam_policy" "this" {
  for_each = var.iam_policies

  name        = "${var.name_prefix}-${each.key}-policy"
  description = each.value.description
  path        = lookup(each.value, "path", "/")
  policy      = each.value.policy_document

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}-policy"
  })
}

# IAM Groups
resource "aws_iam_group" "this" {
  for_each = var.iam_groups

  name = "${var.name_prefix}-${each.key}-group"
  path = lookup(each.value, "path", "/")
}

# Attach AWS managed policies to groups
resource "aws_iam_group_policy_attachment" "aws_managed" {
  for_each = local.group_aws_managed_policies_map

  group      = aws_iam_group.this[each.value.group_name].name
  policy_arn = each.value.policy_arn
}

# Attach custom managed policies to groups
resource "aws_iam_group_policy_attachment" "custom_managed" {
  for_each = local.group_custom_managed_policies_map

  group      = aws_iam_group.this[each.value.group_name].name
  policy_arn = aws_iam_policy.this[each.value.policy_name].arn

  depends_on = [aws_iam_policy.this]
}

# IAM Users
resource "aws_iam_user" "this" {
  for_each = var.create_users ? var.iam_users : {}

  name                 = "${var.name_prefix}-${each.key}"
  path                 = lookup(each.value, "path", "/")
  permissions_boundary = lookup(each.value, "permissions_boundary", null)
  force_destroy        = lookup(each.value, "force_destroy", false)

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}"
  })
}

# Add users to groups
resource "aws_iam_group_membership" "this" {
  for_each = local.group_memberships

  name  = "${var.name_prefix}-${each.key}-membership"
  group = aws_iam_group.this[each.value.group_name].name
  users = [for user in each.value.users : aws_iam_user.this[user].name]

  depends_on = [aws_iam_user.this, aws_iam_group.this]
}

# IAM Access Keys (only if explicitly enabled)
resource "aws_iam_access_key" "this" {
  for_each = var.create_access_keys ? var.user_access_keys : {}

  user   = aws_iam_user.this[each.key].name
  status = lookup(each.value, "status", "Active")

  depends_on = [aws_iam_user.this]
}

# Service-Linked Roles
resource "aws_iam_service_linked_role" "this" {
  for_each = var.service_linked_roles

  aws_service_name = each.value.aws_service_name
  description      = lookup(each.value, "description", "Service-linked role for ${each.value.aws_service_name}")
  custom_suffix    = lookup(each.value, "custom_suffix", null)

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}-service-role"
  })
}

# Instance Profile for EC2 roles
resource "aws_iam_instance_profile" "this" {
  for_each = local.ec2_roles

  name = "${var.name_prefix}-${each.key}-instance-profile"
  role = aws_iam_role.this[each.key].name
  path = lookup(var.iam_roles[each.key], "path", "/")

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}-instance-profile"
  })
}

# OIDC Identity Providers
resource "aws_iam_openid_connect_provider" "this" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}-oidc"
  })
}

# SAML Identity Providers
resource "aws_iam_saml_provider" "this" {
  for_each = var.saml_providers

  name                   = "${var.name_prefix}-${each.key}-saml"
  saml_metadata_document = each.value.saml_metadata_document

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}-saml"
  })
}

# Password Policy
resource "aws_iam_account_password_policy" "this" {
  count = var.create_account_password_policy ? 1 : 0

  minimum_password_length        = var.password_policy.minimum_password_length
  require_lowercase_characters   = var.password_policy.require_lowercase_characters
  require_numbers               = var.password_policy.require_numbers
  require_uppercase_characters   = var.password_policy.require_uppercase_characters
  require_symbols               = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_users_to_change_password
  hard_expiry                   = var.password_policy.hard_expiry
  max_password_age              = var.password_policy.max_password_age
  password_reuse_prevention     = var.password_policy.password_reuse_prevention
}

# Account Alias
resource "aws_iam_account_alias" "this" {
  count = var.account_alias != null ? 1 : 0

  account_alias = var.account_alias
}