# Local values for DynamoDB module
locals {
  # Table configuration
  table_name_formatted = replace(lower(var.table_name), "_", "-")
  
  # Determine if we need to create auto scaling policies
  create_read_autoscaling  = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled
  create_write_autoscaling = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled
  
  # GSI configurations
  gsi_names = [for gsi in var.global_secondary_indexes : gsi.name]
  lsi_names = [for lsi in var.local_secondary_indexes : lsi.name]
  
  # Stream configuration
  stream_specification = var.stream_enabled ? {
    enabled   = var.stream_enabled
    view_type = var.stream_view_type
  } : null
  
  # Encryption configuration
  encryption_config = var.server_side_encryption_enabled ? {
    enabled     = var.server_side_encryption_enabled
    kms_key_arn = var.server_side_encryption_kms_key_id
  } : null
  
  # TTL configuration
  ttl_config = var.ttl_enabled ? {
    attribute_name = var.ttl_attribute_name
    enabled        = var.ttl_enabled
  } : null
  
  # Point-in-time recovery config
  pitr_config = {
    enabled = var.point_in_time_recovery_enabled
  }
  
  # Default tags
  default_tags = {
    Environment   = "production"
    ManagedBy     = "terraform"
    Service       = "dynamodb"
    TableName     = var.table_name
    BillingMode   = var.billing_mode
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Merged tags
  tags = merge(local.default_tags, var.tags)
  
  # CloudWatch alarm configuration
  alarm_config = {
    create_alarms              = var.enable_cloudwatch_alarms
    read_throttle_threshold    = var.read_throttled_requests_threshold
    write_throttle_threshold   = var.write_throttled_requests_threshold
    read_capacity_threshold    = var.consumed_read_capacity_threshold
    write_capacity_threshold   = var.consumed_write_capacity_threshold
    alarm_actions              = var.cloudwatch_alarm_actions
  }
  
  # Autoscaling configuration
  autoscaling_config = {
    enabled = var.autoscaling_enabled
    read = {
      max_capacity       = var.autoscaling_read.max_capacity
      min_capacity       = var.autoscaling_read.min_capacity
      target_value       = var.autoscaling_read.target_value
      scale_in_cooldown  = var.autoscaling_read.scale_in_cooldown
      scale_out_cooldown = var.autoscaling_read.scale_out_cooldown
    }
    write = {
      max_capacity       = var.autoscaling_write.max_capacity
      min_capacity       = var.autoscaling_write.min_capacity
      target_value       = var.autoscaling_write.target_value
      scale_in_cooldown  = var.autoscaling_write.scale_in_cooldown
      scale_out_cooldown = var.autoscaling_write.scale_out_cooldown
    }
  }
  
  # Kinesis Firehose configuration
  firehose_config = var.enable_kinesis_firehose ? {
    enabled            = var.enable_kinesis_firehose
    role_arn           = var.kinesis_firehose_role_arn
    s3_bucket_arn      = var.kinesis_firehose_s3_bucket_arn
    lambda_arn         = var.kinesis_firehose_lambda_arn
    glue_database      = var.kinesis_firehose_glue_database
    glue_table         = var.kinesis_firehose_glue_table
  } : null
  
  # Validation flags
  validation = {
    # Ensure attributes are defined for keys
    hash_key_in_attributes = contains([for attr in var.attributes : attr.name], var.hash_key)
    range_key_in_attributes = var.range_key != null ? contains([for attr in var.attributes : attr.name], var.range_key) : true
    
    # Validate GSI keys are in attributes
    gsi_keys_valid = length(var.global_secondary_indexes) == 0 ? true : alltrue([
      for gsi in var.global_secondary_indexes :
      contains([for attr in var.attributes : attr.name], gsi.hash_key) &&
      (gsi.range_key == null || contains([for attr in var.attributes : attr.name], gsi.range_key))
    ])
    
    # Validate LSI keys are in attributes  
    lsi_keys_valid = length(var.local_secondary_indexes) == 0 ? true : alltrue([
      for lsi in var.local_secondary_indexes :
      contains([for attr in var.attributes : attr.name], lsi.range_key)
    ])
  }
}
