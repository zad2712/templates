# S3 Module - Outputs
# Author: Diego A. Zarate

# S3 Bucket Outputs
output "s3_buckets" {
  description = "Map of S3 bucket information"
  value = {
    for bucket_name, bucket in aws_s3_bucket.this : bucket_name => {
      arn                    = bucket.arn
      bucket                = bucket.bucket
      bucket_domain_name     = bucket.bucket_domain_name
      bucket_regional_domain_name = bucket.bucket_regional_domain_name
      hosted_zone_id         = bucket.hosted_zone_id
      id                     = bucket.id
      region                 = bucket.region
      tags                   = bucket.tags_all
    }
  }
}

output "bucket_arns" {
  description = "ARNs of the created S3 buckets"
  value       = { for bucket_name, bucket in aws_s3_bucket.this : bucket_name => bucket.arn }
}

output "bucket_ids" {
  description = "IDs of the created S3 buckets"
  value       = { for bucket_name, bucket in aws_s3_bucket.this : bucket_name => bucket.id }
}

output "bucket_domain_names" {
  description = "Domain names of the created S3 buckets"
  value       = { for bucket_name, bucket in aws_s3_bucket.this : bucket_name => bucket.bucket_domain_name }
}

output "bucket_regional_domain_names" {
  description = "Regional domain names of the created S3 buckets"
  value       = { for bucket_name, bucket in aws_s3_bucket.this : bucket_name => bucket.bucket_regional_domain_name }
}

output "bucket_hosted_zone_ids" {
  description = "Hosted zone IDs of the created S3 buckets"
  value       = { for bucket_name, bucket in aws_s3_bucket.this : bucket_name => bucket.hosted_zone_id }
}

# Bucket Policy Outputs
output "bucket_policies" {
  description = "Map of S3 bucket policies"
  value = {
    for bucket_name, policy in aws_s3_bucket_policy.this : bucket_name => {
      bucket = policy.bucket
      policy = policy.policy
    }
  }
  sensitive = true
}

# Versioning Configuration Outputs
output "bucket_versioning_configurations" {
  description = "Map of S3 bucket versioning configurations"
  value = {
    for bucket_name, versioning in aws_s3_bucket_versioning.this : bucket_name => {
      bucket = versioning.bucket
      status = versioning.versioning_configuration[0].status
    }
  }
}

# Encryption Configuration Outputs
output "bucket_encryption_configurations" {
  description = "Map of S3 bucket encryption configurations"
  value = {
    for bucket_name, encryption in aws_s3_bucket_server_side_encryption_configuration.this : bucket_name => {
      bucket = encryption.bucket
      algorithm = encryption.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
      kms_master_key_id = try(encryption.rule[0].apply_server_side_encryption_by_default[0].kms_master_key_id, null)
    }
  }
}

# Public Access Block Outputs
output "bucket_public_access_blocks" {
  description = "Map of S3 bucket public access block configurations"
  value = {
    for bucket_name, pab in aws_s3_bucket_public_access_block.this : bucket_name => {
      bucket                  = pab.bucket
      block_public_acls       = pab.block_public_acls
      block_public_policy     = pab.block_public_policy
      ignore_public_acls      = pab.ignore_public_acls
      restrict_public_buckets = pab.restrict_public_buckets
    }
  }
}

# Lifecycle Configuration Outputs
output "bucket_lifecycle_configurations" {
  description = "Map of S3 bucket lifecycle configurations"
  value = {
    for bucket_name, lifecycle in aws_s3_bucket_lifecycle_configuration.this : bucket_name => {
      bucket = lifecycle.bucket
      rules  = lifecycle.rule
    }
  }
}

# Logging Configuration Outputs
output "bucket_logging_configurations" {
  description = "Map of S3 bucket logging configurations"
  value = {
    for bucket_name, logging in aws_s3_bucket_logging.this : bucket_name => {
      bucket        = logging.bucket
      target_bucket = logging.target_bucket
      target_prefix = logging.target_prefix
    }
  }
}

# Notification Configuration Outputs
output "bucket_notification_configurations" {
  description = "Map of S3 bucket notification configurations"
  value = {
    for bucket_name, notification in aws_s3_bucket_notification.this : bucket_name => {
      bucket           = notification.bucket
      lambda_functions = try(notification.lambda_function, [])
      sns_topics      = try(notification.topic, [])
      sqs_queues      = try(notification.queue, [])
    }
  }
}

# CORS Configuration Outputs
output "bucket_cors_configurations" {
  description = "Map of S3 bucket CORS configurations"
  value = {
    for bucket_name, cors in aws_s3_bucket_cors_configuration.this : bucket_name => {
      bucket = cors.bucket
      rules  = cors.cors_rule
    }
  }
}

# Website Configuration Outputs
output "bucket_website_configurations" {
  description = "Map of S3 bucket website configurations"
  value = {
    for bucket_name, website in aws_s3_bucket_website_configuration.this : bucket_name => {
      bucket          = website.bucket
      website_domain  = website.website_domain
      website_endpoint = website.website_endpoint
    }
  }
}

# Replication Configuration Outputs
output "bucket_replication_configurations" {
  description = "Map of S3 bucket replication configurations"
  value = {
    for bucket_name, replication in aws_s3_bucket_replication_configuration.this : bucket_name => {
      bucket = replication.bucket
      role   = replication.role
      rules  = replication.rule
    }
  }
  sensitive = true
}

# Bucket Types
output "application_buckets" {
  description = "List of application buckets"
  value = [
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.bucket_type == "application"
  ]
}

output "logging_buckets" {
  description = "List of logging buckets"
  value = [
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.bucket_type == "logging"
  ]
}

output "static_website_buckets" {
  description = "List of static website buckets"
  value = [
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.bucket_type == "static-website"
  ]
}

output "backup_buckets" {
  description = "List of backup buckets"
  value = [
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.bucket_type == "backup"
  ]
}

output "data_lake_buckets" {
  description = "List of data lake buckets"
  value = [
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.bucket_type == "data-lake"
  ]
}

# Summary Outputs
output "bucket_count" {
  description = "Total number of S3 buckets created"
  value       = length(aws_s3_bucket.this)
}

output "encrypted_bucket_count" {
  description = "Number of encrypted S3 buckets"
  value = length([
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.encryption != null
  ])
}

output "versioned_bucket_count" {
  description = "Number of versioned S3 buckets"
  value = length([
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.versioning_enabled
  ])
}

output "replicated_bucket_count" {
  description = "Number of S3 buckets with replication enabled"
  value = length([
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.replication != null
  ])
}

output "website_enabled_bucket_count" {
  description = "Number of S3 buckets with website hosting enabled"
  value = length([
    for bucket_name, bucket_config in var.s3_buckets : bucket_name
    if bucket_config.website != null
  ])
}

# Module Information
output "module_info" {
  description = "S3 module information"
  value = {
    module_name    = "s3"
    module_version = "1.0.0"
    created_at     = timestamp()
    provider_version = "~> 5.0"
    terraform_version = ">= 1.9.0"
  }
}