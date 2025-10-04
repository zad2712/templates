# S3 Module - Main Configuration
# Author: Diego A. Zarate
# This module creates S3 buckets with comprehensive security, lifecycle, and policy management

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# S3 Buckets
resource "aws_s3_bucket" "this" {
  for_each = var.s3_buckets

  bucket        = "${var.name_prefix}-${each.key}-${random_id.bucket_suffix[each.key].hex}"
  force_destroy = lookup(each.value, "force_destroy", false)

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-${each.key}"
    Type = lookup(each.value, "bucket_type", "application")
  })
}

# Random suffix for bucket names to ensure uniqueness
resource "random_id" "bucket_suffix" {
  for_each = var.s3_buckets

  byte_length = 4
  keepers = {
    bucket_name = "${var.name_prefix}-${each.key}"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "this" {
  for_each = var.s3_buckets

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = lookup(each.value, "versioning_enabled", true) ? "Enabled" : "Suspended"
    mfa_delete = lookup(each.value, "mfa_delete", false) ? "Enabled" : "Disabled"
  }

  depends_on = [aws_s3_bucket.this]
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = var.s3_buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = lookup(each.value.encryption, "sse_algorithm", "aws:kms")
      kms_master_key_id = lookup(each.value.encryption, "kms_master_key_id", null)
    }
    
    bucket_key_enabled = lookup(each.value.encryption, "bucket_key_enabled", true)
  }

  depends_on = [aws_s3_bucket.this]
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "this" {
  for_each = var.s3_buckets

  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = lookup(each.value.public_access_block, "block_public_acls", true)
  block_public_policy     = lookup(each.value.public_access_block, "block_public_policy", true)
  ignore_public_acls      = lookup(each.value.public_access_block, "ignore_public_acls", true)
  restrict_public_buckets = lookup(each.value.public_access_block, "restrict_public_buckets", true)

  depends_on = [aws_s3_bucket.this]
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if length(lookup(v, "lifecycle_rules", [])) > 0
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)
          
          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", null) != null ? [rule.value.expiration] : []
        content {
          days                         = lookup(expiration.value, "days", null)
          date                         = lookup(expiration.value, "date", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days           = lookup(noncurrent_version_expiration.value, "noncurrent_days", null)
          newer_noncurrent_versions = lookup(noncurrent_version_expiration.value, "newer_noncurrent_versions", null)
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = lookup(transition.value, "days", null)
          date          = lookup(transition.value, "date", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transitions", [])
        content {
          noncurrent_days           = lookup(noncurrent_version_transition.value, "noncurrent_days", null)
          newer_noncurrent_versions = lookup(noncurrent_version_transition.value, "newer_noncurrent_versions", null)
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(rule.value, "abort_incomplete_multipart_upload", null) != null ? [rule.value.abort_incomplete_multipart_upload] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }

  depends_on = [aws_s3_bucket.this, aws_s3_bucket_versioning.this]
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "this" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if lookup(v, "bucket_policy", null) != null || lookup(v, "enable_default_policy", false)
  }

  bucket = aws_s3_bucket.this[each.key].id
  policy = lookup(each.value, "bucket_policy", null) != null ? each.value.bucket_policy : data.aws_iam_policy_document.bucket_policy[each.key].json

  depends_on = [aws_s3_bucket.this, aws_s3_bucket_public_access_block.this]
}

# Default bucket policy (if enabled)
data "aws_iam_policy_document" "bucket_policy" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if lookup(v, "enable_default_policy", false) && lookup(v, "bucket_policy", null) == null
  }

  # Deny insecure connections
  statement {
    sid    = "DenyInsecureConnections"
    effect = "Deny"
    
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this[each.key].arn,
      "${aws_s3_bucket.this[each.key].arn}/*"
    ]
    
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Allow specified principals (if configured)
  dynamic "statement" {
    for_each = length(lookup(var.s3_buckets[each.key], "allowed_principals", [])) > 0 ? [1] : []
    content {
      sid    = "AllowSpecifiedPrincipals"
      effect = "Allow"
      
      principals {
        type        = "AWS"
        identifiers = var.s3_buckets[each.key].allowed_principals
      }
      
      actions = lookup(var.s3_buckets[each.key], "allowed_actions", [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ])
      
      resources = [
        aws_s3_bucket.this[each.key].arn,
        "${aws_s3_bucket.this[each.key].arn}/*"
      ]
    }
  }
}

# S3 Bucket Logging
resource "aws_s3_bucket_logging" "this" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if lookup(v, "logging", null) != null
  }

  bucket = aws_s3_bucket.this[each.key].id

  target_bucket = each.value.logging.target_bucket
  target_prefix = lookup(each.value.logging, "target_prefix", "access-logs/")

  dynamic "target_grant" {
    for_each = lookup(each.value.logging, "target_grants", [])
    content {
      grantee {
        type          = target_grant.value.grantee.type
        id            = lookup(target_grant.value.grantee, "id", null)
        uri           = lookup(target_grant.value.grantee, "uri", null)
        email_address = lookup(target_grant.value.grantee, "email_address", null)
      }
      permission = target_grant.value.permission
    }
  }

  depends_on = [aws_s3_bucket.this]
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "this" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if lookup(v, "notifications", null) != null
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "lambda_function" {
    for_each = lookup(each.value.notifications, "lambda_functions", [])
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lookup(lambda_function.value, "filter_prefix", null)
      filter_suffix       = lookup(lambda_function.value, "filter_suffix", null)
    }
  }

  dynamic "topic" {
    for_each = lookup(each.value.notifications, "sns_topics", [])
    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = lookup(topic.value, "filter_prefix", null)
      filter_suffix = lookup(topic.value, "filter_suffix", null)
    }
  }

  dynamic "queue" {
    for_each = lookup(each.value.notifications, "sqs_queues", [])
    content {
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = lookup(queue.value, "filter_prefix", null)
      filter_suffix = lookup(queue.value, "filter_suffix", null)
    }
  }

  depends_on = [aws_s3_bucket.this]
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "this" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if lookup(v, "cors_rules", null) != null
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "cors_rule" {
    for_each = each.value.cors_rules
    content {
      id              = lookup(cors_rule.value, "id", null)
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }

  depends_on = [aws_s3_bucket.this]
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "this" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if lookup(v, "website", null) != null
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "index_document" {
    for_each = lookup(each.value.website, "index_document", null) != null ? [each.value.website.index_document] : []
    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = lookup(each.value.website, "error_document", null) != null ? [each.value.website.error_document] : []
    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = lookup(each.value.website, "redirect_all_requests_to", null) != null ? [each.value.website.redirect_all_requests_to] : []
    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = lookup(redirect_all_requests_to.value, "protocol", null)
    }
  }

  dynamic "routing_rule" {
    for_each = lookup(each.value.website, "routing_rules", [])
    content {
      condition {
        http_error_code_returned_equals = lookup(routing_rule.value.condition, "http_error_code_returned_equals", null)
        key_prefix_equals              = lookup(routing_rule.value.condition, "key_prefix_equals", null)
      }

      redirect {
        host_name               = lookup(routing_rule.value.redirect, "host_name", null)
        http_redirect_code      = lookup(routing_rule.value.redirect, "http_redirect_code", null)
        protocol                = lookup(routing_rule.value.redirect, "protocol", null)
        replace_key_prefix_with = lookup(routing_rule.value.redirect, "replace_key_prefix_with", null)
        replace_key_with        = lookup(routing_rule.value.redirect, "replace_key_with", null)
      }
    }
  }

  depends_on = [aws_s3_bucket.this]
}

# S3 Bucket Replication Configuration
resource "aws_s3_bucket_replication_configuration" "this" {
  for_each = {
    for k, v in var.s3_buckets : k => v
    if lookup(v, "replication", null) != null
  }

  role   = each.value.replication.role_arn
  bucket = aws_s3_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value.replication.rules
    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = lookup(rule.value, "priority", null)

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)
          
          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      destination {
        bucket             = rule.value.destination.bucket
        storage_class      = lookup(rule.value.destination, "storage_class", null)
        replica_kms_key_id = lookup(rule.value.destination, "replica_kms_key_id", null)
        account_id         = lookup(rule.value.destination, "account_id", null)

        dynamic "access_control_translation" {
          for_each = lookup(rule.value.destination, "access_control_translation", null) != null ? [rule.value.destination.access_control_translation] : []
          content {
            owner = access_control_translation.value.owner
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = lookup(rule.value, "delete_marker_replication", null) != null ? [rule.value.delete_marker_replication] : []
        content {
          status = delete_marker_replication.value.status
        }
      }
    }
  }

  depends_on = [aws_s3_bucket.this, aws_s3_bucket_versioning.this]
}