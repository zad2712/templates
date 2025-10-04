# S3 Module - Variables
# Author: Diego A. Zarate

# General Configuration
variable "name_prefix" {
  description = "Name prefix for S3 resources"
  type        = string
  default     = "app"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "Name prefix must be between 1 and 32 characters."
  }
}

variable "tags" {
  description = "A map of tags to assign to S3 resources"
  type        = map(string)
  default     = {}
}

# S3 Buckets Configuration
variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    # Basic Configuration
    force_destroy = optional(bool, false)
    bucket_type   = optional(string, "application")
    
    # Versioning Configuration
    versioning_enabled = optional(bool, true)
    mfa_delete        = optional(bool, false)
    
    # Encryption Configuration
    encryption = optional(object({
      sse_algorithm      = optional(string, "aws:kms")
      kms_master_key_id  = optional(string, null)
      bucket_key_enabled = optional(bool, true)
    }), {
      sse_algorithm      = "aws:kms"
      bucket_key_enabled = true
    })
    
    # Public Access Block Configuration
    public_access_block = optional(object({
      block_public_acls       = optional(bool, true)
      block_public_policy     = optional(bool, true)
      ignore_public_acls      = optional(bool, true)
      restrict_public_buckets = optional(bool, true)
    }), {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    })
    
    # Lifecycle Rules
    lifecycle_rules = optional(list(object({
      id     = string
      status = string
      filter = optional(object({
        prefix = optional(string, null)
        tags   = optional(map(string), {})
      }), null)
      expiration = optional(object({
        days                         = optional(number, null)
        date                         = optional(string, null)
        expired_object_delete_marker = optional(bool, null)
      }), null)
      noncurrent_version_expiration = optional(object({
        noncurrent_days           = optional(number, null)
        newer_noncurrent_versions = optional(number, null)
      }), null)
      transitions = optional(list(object({
        days          = optional(number, null)
        date          = optional(string, null)
        storage_class = string
      })), [])
      noncurrent_version_transitions = optional(list(object({
        noncurrent_days           = optional(number, null)
        newer_noncurrent_versions = optional(number, null)
        storage_class             = string
      })), [])
      abort_incomplete_multipart_upload = optional(object({
        days_after_initiation = number
      }), null)
    })), [])
    
    # Bucket Policy
    bucket_policy        = optional(string, null)
    enable_default_policy = optional(bool, false)
    allowed_principals   = optional(list(string), [])
    allowed_actions      = optional(list(string), [])
    
    # Logging Configuration
    logging = optional(object({
      target_bucket = string
      target_prefix = optional(string, "access-logs/")
      target_grants = optional(list(object({
        grantee = object({
          type          = string
          id            = optional(string, null)
          uri           = optional(string, null)
          email_address = optional(string, null)
        })
        permission = string
      })), [])
    }), null)
    
    # Notification Configuration
    notifications = optional(object({
      lambda_functions = optional(list(object({
        lambda_function_arn = string
        events             = list(string)
        filter_prefix      = optional(string, null)
        filter_suffix      = optional(string, null)
      })), [])
      sns_topics = optional(list(object({
        topic_arn     = string
        events        = list(string)
        filter_prefix = optional(string, null)
        filter_suffix = optional(string, null)
      })), [])
      sqs_queues = optional(list(object({
        queue_arn     = string
        events        = list(string)
        filter_prefix = optional(string, null)
        filter_suffix = optional(string, null)
      })), [])
    }), null)
    
    # CORS Configuration
    cors_rules = optional(list(object({
      id              = optional(string, null)
      allowed_headers = optional(list(string), null)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = optional(list(string), null)
      max_age_seconds = optional(number, null)
    })), null)
    
    # Website Configuration
    website = optional(object({
      index_document = optional(string, null)
      error_document = optional(string, null)
      redirect_all_requests_to = optional(object({
        host_name = string
        protocol  = optional(string, null)
      }), null)
      routing_rules = optional(list(object({
        condition = object({
          http_error_code_returned_equals = optional(string, null)
          key_prefix_equals              = optional(string, null)
        })
        redirect = object({
          host_name               = optional(string, null)
          http_redirect_code      = optional(string, null)
          protocol                = optional(string, null)
          replace_key_prefix_with = optional(string, null)
          replace_key_with        = optional(string, null)
        })
      })), [])
    }), null)
    
    # Replication Configuration
    replication = optional(object({
      role_arn = string
      rules = list(object({
        id       = string
        status   = string
        priority = optional(number, null)
        filter = optional(object({
          prefix = optional(string, null)
          tags   = optional(map(string), {})
        }), null)
        destination = object({
          bucket             = string
          storage_class      = optional(string, null)
          replica_kms_key_id = optional(string, null)
          account_id         = optional(string, null)
          access_control_translation = optional(object({
            owner = string
          }), null)
        })
        delete_marker_replication = optional(object({
          status = string
        }), null)
      }))
    }), null)
    
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for bucket_name, bucket_config in var.s3_buckets : 
      can(regex("^[a-z0-9.-]+$", bucket_name)) && length(bucket_name) >= 3 && length(bucket_name) <= 63
    ])
    error_message = "Bucket names must be between 3 and 63 characters, contain only lowercase letters, numbers, periods, and hyphens."
  }

  validation {
    condition = alltrue([
      for bucket_name, bucket_config in var.s3_buckets : 
      contains(["AES256", "aws:kms", "aws:kms:dsse"], lookup(bucket_config.encryption, "sse_algorithm", "aws:kms"))
    ])
    error_message = "SSE algorithm must be one of: AES256, aws:kms, aws:kms:dsse."
  }

  validation {
    condition = alltrue([
      for bucket_name, bucket_config in var.s3_buckets : 
      alltrue([
        for rule in bucket_config.lifecycle_rules : 
        contains(["Enabled", "Disabled"], rule.status)
      ])
    ])
    error_message = "Lifecycle rule status must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for bucket_name, bucket_config in var.s3_buckets : 
      alltrue([
        for rule in bucket_config.lifecycle_rules : 
        alltrue([
          for transition in rule.transitions : 
          contains([
            "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", 
            "GLACIER", "DEEP_ARCHIVE", "GLACIER_IR"
          ], transition.storage_class)
        ])
      ])
    ])
    error_message = "Invalid storage class in lifecycle transitions."
  }
}