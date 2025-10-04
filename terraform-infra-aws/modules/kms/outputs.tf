# KMS Module - Outputs
# Author: Diego A. Zarate

# KMS Key Outputs
output "key_ids" {
  description = "Map of key names to their IDs"
  value = {
    for k, v in aws_kms_key.this : k => v.key_id
  }
}

output "key_arns" {
  description = "Map of key names to their ARNs"
  value = {
    for k, v in aws_kms_key.this : k => v.arn
  }
}

output "key_policies" {
  description = "Map of key names to their policies"
  value = {
    for k, v in aws_kms_key.this : k => v.policy
  }
}

output "key_usage" {
  description = "Map of key names to their usage types"
  value = {
    for k, v in aws_kms_key.this : k => v.key_usage
  }
}

# KMS Alias Outputs
output "alias_names" {
  description = "Map of key names to their alias names"
  value = {
    for k, v in aws_kms_alias.this : k => v.name
  }
}

output "alias_arns" {
  description = "Map of key names to their alias ARNs"
  value = {
    for k, v in aws_kms_alias.this : k => v.arn
  }
}

# Grant Outputs
output "grant_ids" {
  description = "Map of grant names to their IDs"
  value = {
    for k, v in aws_kms_grant.this : k => v.key_id
  }
}

output "grant_tokens" {
  description = "Map of grant names to their tokens"
  value = {
    for k, v in aws_kms_grant.this : k => v.token
  }
}

# External Key Outputs
output "external_key_ids" {
  description = "Map of external key names to their IDs"
  value = {
    for k, v in aws_kms_external_key.this : k => v.key_id
  }
}

output "external_key_arns" {
  description = "Map of external key names to their ARNs"
  value = {
    for k, v in aws_kms_external_key.this : k => v.arn
  }
}

output "external_alias_names" {
  description = "Map of external key names to their alias names"
  value = {
    for k, v in aws_kms_alias.external : k => v.name
  }
}

# Service-Specific Key Outputs (for easy reference)
output "service_key_ids" {
  description = "Map of AWS service names to their KMS key IDs"
  value = {
    for service in ["s3", "ebs", "rds", "lambda", "secrets_manager", "ssm", "cloudtrail", "cloudwatch", "kinesis", "sns", "sqs", "dynamodb"] :
    service => contains(keys(aws_kms_key.this), service) ? aws_kms_key.this[service].key_id : null
  }
}

output "service_key_arns" {
  description = "Map of AWS service names to their KMS key ARNs"
  value = {
    for service in ["s3", "ebs", "rds", "lambda", "secrets_manager", "ssm", "cloudtrail", "cloudwatch", "kinesis", "sns", "sqs", "dynamodb"] :
    service => contains(keys(aws_kms_key.this), service) ? aws_kms_key.this[service].arn : null
  }
}

output "service_alias_names" {
  description = "Map of AWS service names to their KMS key alias names"
  value = {
    for service in ["s3", "ebs", "rds", "lambda", "secrets_manager", "ssm", "cloudtrail", "cloudwatch", "kinesis", "sns", "sqs", "dynamodb"] :
    service => contains(keys(aws_kms_alias.this), service) ? aws_kms_alias.this[service].name : null
  }
}

# Replica Key Outputs (for multi-region keys)
output "replica_key_ids" {
  description = "Map of replica key names to their IDs"
  value = {
    for k, v in aws_kms_replica_key.this : k => v.key_id
  }
}

output "replica_key_arns" {
  description = "Map of replica key names to their ARNs"
  value = {
    for k, v in aws_kms_replica_key.this : k => v.arn
  }
}

# Consolidated Outputs
output "all_keys" {
  description = "Complete information about all KMS keys"
  value = {
    for k, v in aws_kms_key.this : k => {
      key_id                  = v.key_id
      arn                     = v.arn
      policy                  = v.policy
      description             = v.description
      key_usage              = v.key_usage
      key_spec               = v.key_spec
      enabled                = v.is_enabled
      rotation_enabled       = v.enable_key_rotation
      multi_region           = v.multi_region
      deletion_window        = v.deletion_window_in_days
      alias_name             = aws_kms_alias.this[k].name
      alias_arn              = aws_kms_alias.this[k].arn
    }
  }
}

output "encryption_configuration" {
  description = "Encryption configuration for use in other modules"
  value = {
    # Most commonly used keys for reference
    s3_key_id              = contains(keys(aws_kms_key.this), "s3") ? aws_kms_key.this["s3"].key_id : null
    s3_key_arn             = contains(keys(aws_kms_key.this), "s3") ? aws_kms_key.this["s3"].arn : null
    ebs_key_id             = contains(keys(aws_kms_key.this), "ebs") ? aws_kms_key.this["ebs"].key_id : null
    ebs_key_arn            = contains(keys(aws_kms_key.this), "ebs") ? aws_kms_key.this["ebs"].arn : null
    rds_key_id             = contains(keys(aws_kms_key.this), "rds") ? aws_kms_key.this["rds"].key_id : null
    rds_key_arn            = contains(keys(aws_kms_key.this), "rds") ? aws_kms_key.this["rds"].arn : null
    lambda_key_id          = contains(keys(aws_kms_key.this), "lambda") ? aws_kms_key.this["lambda"].key_id : null
    lambda_key_arn         = contains(keys(aws_kms_key.this), "lambda") ? aws_kms_key.this["lambda"].arn : null
    secrets_manager_key_id = contains(keys(aws_kms_key.this), "secrets_manager") ? aws_kms_key.this["secrets_manager"].key_id : null
    secrets_manager_key_arn = contains(keys(aws_kms_key.this), "secrets_manager") ? aws_kms_key.this["secrets_manager"].arn : null
    
    # All key mappings for dynamic use
    all_key_ids = {
      for k, v in aws_kms_key.this : k => v.key_id
    }
    all_key_arns = {
      for k, v in aws_kms_key.this : k => v.arn
    }
    all_alias_names = {
      for k, v in aws_kms_alias.this : k => v.name
    }
  }
}

# Security and Compliance Information
output "security_summary" {
  description = "Summary of KMS security configuration"
  value = {
    total_keys                = length(aws_kms_key.this)
    total_external_keys       = length(aws_kms_external_key.this)
    total_grants              = length(aws_kms_grant.this)
    total_aliases             = length(aws_kms_alias.this) + length(aws_kms_alias.external)
    rotation_enabled_keys     = length([for k, v in aws_kms_key.this : k if v.enable_key_rotation])
    multi_region_keys         = length([for k, v in aws_kms_key.this : k if v.multi_region])
    replica_keys              = length(aws_kms_replica_key.this)
    standard_keys_created     = var.create_standard_keys
    custom_keys_created       = length(var.kms_keys) > 0
    external_keys_created     = length(var.external_keys) > 0
  }
}