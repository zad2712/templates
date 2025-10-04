# KMS Module - Main Configuration
# Author: Diego A. Zarate
# This module creates KMS keys with policies, aliases, and grants following AWS encryption best practices

# Data source for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS Keys
resource "aws_kms_key" "this" {
  for_each = local.all_kms_keys

  description                        = each.value.description
  key_usage                         = lookup(each.value, "key_usage", "ENCRYPT_DECRYPT")
  key_spec                          = lookup(each.value, "key_spec", "SYMMETRIC_DEFAULT")
  customer_master_key_spec          = lookup(each.value, "customer_master_key_spec", null)
  policy                            = lookup(each.value, "policy", null) != null ? each.value.policy : data.aws_iam_policy_document.kms_key_policy[each.key].json
  deletion_window_in_days           = lookup(each.value, "deletion_window_in_days", 30)
  is_enabled                        = lookup(each.value, "is_enabled", true)
  enable_key_rotation               = lookup(each.value, "enable_key_rotation", true)
  rotation_period_in_days           = lookup(each.value, "rotation_period_in_days", 365)
  multi_region                      = lookup(each.value, "multi_region", false)
  bypass_policy_lockout_safety_check = lookup(each.value, "bypass_policy_lockout_safety_check", false)

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}-kms-key"
  })
}

# Default KMS Key Policy (if not provided)
data "aws_iam_policy_document" "kms_key_policy" {
  for_each = {
    for k, v in local.all_kms_keys : k => v
    if lookup(v, "policy", null) == null
  }

  # Enable IAM User Permissions
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow key administrators (if specified)
  dynamic "statement" {
    for_each = length(lookup(local.all_kms_keys[each.key], "key_administrators", [])) > 0 ? [1] : []
    content {
      sid    = "Allow key administrators"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = local.all_kms_keys[each.key].key_administrators
      }
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:RotateKeyOnDemand"
      ]
      resources = ["*"]
    }
  }

  # Allow key users (if specified)
  dynamic "statement" {
    for_each = length(lookup(local.all_kms_keys[each.key], "key_users", [])) > 0 ? [1] : []
    content {
      sid    = "Allow key users"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = local.all_kms_keys[each.key].key_users
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
    }
  }

  # Allow service usage (if specified)
  dynamic "statement" {
    for_each = length(lookup(local.all_kms_keys[each.key], "service_principals", [])) > 0 ? [1] : []
    content {
      sid    = "Allow AWS services"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = local.all_kms_keys[each.key].service_principals
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values = [
          for service in local.all_kms_keys[each.key].service_principals :
          "${service}.${data.aws_region.current.name}.amazonaws.com"
        ]
      }
    }
  }

  # Cross-account access (if specified)
  dynamic "statement" {
    for_each = length(lookup(local.all_kms_keys[each.key], "external_accounts", [])) > 0 ? [1] : []
    content {
      sid    = "Allow external accounts"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          for account in local.all_kms_keys[each.key].external_accounts :
          "arn:aws:iam::${account}:root"
        ]
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
    }
  }
}

# KMS Key Aliases
resource "aws_kms_alias" "this" {
  for_each = local.all_kms_keys

  name          = "alias/${var.name_prefix}-${each.key}"
  target_key_id = aws_kms_key.this[each.key].key_id
}

# KMS Grants
resource "aws_kms_grant" "this" {
  for_each = local.kms_grants_flattened

  name              = each.value.name
  key_id            = aws_kms_key.this[each.value.key_name].key_id
  grantee_principal = each.value.grantee_principal
  operations        = each.value.operations

  dynamic "constraints" {
    for_each = lookup(each.value, "constraints", null) != null ? [each.value.constraints] : []
    content {
      dynamic "encryption_context_equals" {
        for_each = lookup(constraints.value, "encryption_context_equals", null) != null ? [constraints.value.encryption_context_equals] : []
        content {
          for k, v in encryption_context_equals.value : k => v
        }
      }
      dynamic "encryption_context_subset" {
        for_each = lookup(constraints.value, "encryption_context_subset", null) != null ? [constraints.value.encryption_context_subset] : []
        content {
          for k, v in encryption_context_subset.value : k => v
        }
      }
    }
  }

  retiring_principal    = lookup(each.value, "retiring_principal", null)
  grant_creation_tokens = lookup(each.value, "grant_creation_tokens", null)

  depends_on = [aws_kms_key.this]
}

# KMS Key Replica (for multi-region keys)
resource "aws_kms_replica_key" "this" {
  for_each = local.replica_keys

  description                = "Replica of ${var.name_prefix}-${each.value.key_name} in ${each.value.region}"
  primary_key_arn           = aws_kms_key.this[each.value.key_name].arn
  deletion_window_in_days   = lookup(local.all_kms_keys[each.value.key_name], "deletion_window_in_days", 30)
  bypass_policy_lockout_safety_check = lookup(local.all_kms_keys[each.value.key_name], "bypass_policy_lockout_safety_check", false)
  policy                    = lookup(local.all_kms_keys[each.value.key_name], "replica_policy", null)

  provider = aws.replica

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.value.key_name}-replica-${each.value.region}"
    Region = each.value.region
  })

  depends_on = [aws_kms_key.this]
}

# KMS External Key (for BYOK scenarios)
resource "aws_kms_external_key" "this" {
  for_each = var.external_keys

  description                        = each.value.description
  policy                            = lookup(each.value, "policy", null)
  deletion_window_in_days           = lookup(each.value, "deletion_window_in_days", 30)
  enabled                           = lookup(each.value, "enabled", true)
  key_material_base64               = lookup(each.value, "key_material_base64", null)
  valid_to                          = lookup(each.value, "valid_to", null)
  multi_region                      = lookup(each.value, "multi_region", false)
  bypass_policy_lockout_safety_check = lookup(each.value, "bypass_policy_lockout_safety_check", false)

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}-external-key"
  })
}

# External Key Aliases
resource "aws_kms_alias" "external" {
  for_each = var.external_keys

  name          = "alias/${var.name_prefix}-${each.key}-external"
  target_key_id = aws_kms_external_key.this[each.key].key_id
}