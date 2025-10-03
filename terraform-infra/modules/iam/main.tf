# =============================================================================
# IAM MODULE
# =============================================================================

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

# =============================================================================
# IAM ROLES
# =============================================================================

resource "aws_iam_role" "roles" {
  for_each = var.roles

  name                = each.key
  assume_role_policy  = each.value.assume_role_policy
  description         = lookup(each.value, "description", null)
  force_detach_policies = lookup(each.value, "force_detach_policies", false)
  max_session_duration = lookup(each.value, "max_session_duration", 3600)
  path                = lookup(each.value, "path", "/")
  permissions_boundary = lookup(each.value, "permissions_boundary", null)

  dynamic "inline_policy" {
    for_each = lookup(each.value, "inline_policies", {})
    content {
      name   = inline_policy.key
      policy = inline_policy.value
    }
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# =============================================================================
# IAM ROLE POLICY ATTACHMENTS
# =============================================================================

resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each = local.role_policy_attachments

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = each.value.policy_arn
}

locals {
  role_policy_attachments = merge([
    for role_name, role_config in var.roles : {
      for policy_arn in lookup(role_config, "policy_arns", []) : "${role_name}-${policy_arn}" => {
        role       = role_name
        policy_arn = policy_arn
      }
    }
  ]...)
}

# =============================================================================
# IAM POLICIES
# =============================================================================

resource "aws_iam_policy" "policies" {
  for_each = var.policies

  name        = each.key
  policy      = each.value.policy_document
  description = lookup(each.value, "description", null)
  path        = lookup(each.value, "path", "/")

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# =============================================================================
# IAM GROUPS
# =============================================================================

resource "aws_iam_group" "groups" {
  for_each = var.groups

  name = each.key
  path = lookup(each.value, "path", "/")
}

# =============================================================================
# IAM GROUP POLICY ATTACHMENTS
# =============================================================================

resource "aws_iam_group_policy_attachment" "group_policy_attachments" {
  for_each = local.group_policy_attachments

  group      = aws_iam_group.groups[each.value.group].name
  policy_arn = each.value.policy_arn
}

locals {
  group_policy_attachments = merge([
    for group_name, group_config in var.groups : {
      for policy_arn in lookup(group_config, "policy_arns", []) : "${group_name}-${policy_arn}" => {
        group      = group_name
        policy_arn = policy_arn
      }
    }
  ]...)
}

# =============================================================================
# IAM USERS
# =============================================================================

resource "aws_iam_user" "users" {
  for_each = var.users

  name                 = each.key
  path                 = lookup(each.value, "path", "/")
  permissions_boundary = lookup(each.value, "permissions_boundary", null)
  force_destroy       = lookup(each.value, "force_destroy", false)

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# =============================================================================
# IAM USER POLICY ATTACHMENTS
# =============================================================================

resource "aws_iam_user_policy_attachment" "user_policy_attachments" {
  for_each = local.user_policy_attachments

  user       = aws_iam_user.users[each.value.user].name
  policy_arn = each.value.policy_arn
}

locals {
  user_policy_attachments = merge([
    for user_name, user_config in var.users : {
      for policy_arn in lookup(user_config, "policy_arns", []) : "${user_name}-${policy_arn}" => {
        user       = user_name
        policy_arn = policy_arn
      }
    }
  ]...)
}

# =============================================================================
# IAM USER GROUP MEMBERSHIPS
# =============================================================================

resource "aws_iam_user_group_membership" "user_group_memberships" {
  for_each = local.user_group_memberships

  user   = aws_iam_user.users[each.value.user].name
  groups = each.value.groups
}

locals {
  user_group_memberships = {
    for user_name, user_config in var.users : user_name => {
      user   = user_name
      groups = [for group in lookup(user_config, "groups", []) : aws_iam_group.groups[group].name]
    }
    if length(lookup(user_config, "groups", [])) > 0
  }
}

# =============================================================================
# IAM INSTANCE PROFILES
# =============================================================================

resource "aws_iam_instance_profile" "instance_profiles" {
  for_each = var.instance_profiles

  name = each.key
  role = aws_iam_role.roles[each.value.role].name
  path = lookup(each.value, "path", "/")

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}
