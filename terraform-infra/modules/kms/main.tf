# =============================================================================
# KMS MODULE
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# KMS KEY
# =============================================================================

resource "aws_kms_key" "main" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  key_usage              = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  
  policy = var.policy != null ? var.policy : jsonencode({
    Version = "2012-10-17"
    Id      = "kms-key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = var.key_administrators
        }
        Action = [
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
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = var.key_users
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = var.key_name
  })
}

# =============================================================================
# KMS ALIAS
# =============================================================================

resource "aws_kms_alias" "main" {
  count = var.create_alias ? 1 : 0
  
  name          = var.alias_name != null ? var.alias_name : "alias/${var.key_name}"
  target_key_id = aws_kms_key.main.key_id
}

# =============================================================================
# KMS GRANTS
# =============================================================================

resource "aws_kms_grant" "grants" {
  for_each = var.grants

  name              = each.key
  key_id           = aws_kms_key.main.key_id
  grantee_principal = each.value.grantee_principal
  operations       = each.value.operations

  dynamic "constraints" {
    for_each = lookup(each.value, "constraints", [])
    content {
      encryption_context_equals = lookup(constraints.value, "encryption_context_equals", null)
      encryption_context_subset = lookup(constraints.value, "encryption_context_subset", null)
    }
  }

  retire_on_delete = lookup(each.value, "retire_on_delete", true)
  token           = lookup(each.value, "token", null)
}
