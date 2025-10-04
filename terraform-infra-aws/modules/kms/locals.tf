# KMS Module - Local Values
# Author: Diego A. Zarate
# Local values for processing complex data structures

locals {
  # Flatten KMS grants for for_each iteration
  kms_grants_flattened = merge([
    for key_name, key_config in local.all_kms_keys : {
      for grant_name, grant_config in lookup(key_config, "grants", {}) :
      "${key_name}-${grant_name}" => merge(grant_config, {
        key_name = key_name
        name     = grant_name
      })
    }
  ]...)

  # Process replica keys configuration
  replica_keys = merge([
    for key_name, key_config in local.all_kms_keys : {
      for region in lookup(key_config, "replica_regions", []) :
      "${key_name}-${region}" => {
        key_name = key_name
        region   = region
      }
    }
    if lookup(key_config, "multi_region", false) == true
  ]...)

  # Generate standard service keys if enabled
  standard_service_keys = var.create_standard_keys ? {
    s3 = {
      description = "KMS key for S3 bucket encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["s3"]
      enable_key_rotation = true
    }
    
    ebs = {
      description = "KMS key for EBS volume encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["ec2"]
      enable_key_rotation = true
    }
    
    rds = {
      description = "KMS key for RDS encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["rds"]
      enable_key_rotation = true
    }
    
    lambda = {
      description = "KMS key for Lambda environment variables"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["lambda"]
      enable_key_rotation = true
    }
    
    secrets_manager = {
      description = "KMS key for Secrets Manager"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["secretsmanager"]
      enable_key_rotation = true
    }
    
    ssm = {
      description = "KMS key for Systems Manager Parameter Store"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["ssm"]
      enable_key_rotation = true
    }
    
    cloudtrail = {
      description = "KMS key for CloudTrail log encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["cloudtrail"]
      enable_key_rotation = true
    }
    
    cloudwatch = {
      description = "KMS key for CloudWatch Logs encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["logs"]
      enable_key_rotation = true
    }
    
    kinesis = {
      description = "KMS key for Kinesis Data Streams"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["kinesis"]
      enable_key_rotation = true
    }
    
    sns = {
      description = "KMS key for SNS topic encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["sns"]
      enable_key_rotation = true
    }
    
    sqs = {
      description = "KMS key for SQS queue encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["sqs"]
      enable_key_rotation = true
    }
    
    dynamodb = {
      description = "KMS key for DynamoDB table encryption"
      key_usage   = "ENCRYPT_DECRYPT"
      service_principals = ["dynamodb"]
      enable_key_rotation = true
    }
  } : {}

  # Merge standard keys with custom keys
  all_kms_keys = merge(local.standard_service_keys, var.kms_keys)
}