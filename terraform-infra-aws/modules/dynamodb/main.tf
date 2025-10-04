# DynamoDB Module Configuration
locals {
  # Common tags
  common_tags = merge(var.common_tags, {
    Module = "dynamodb"
    ManagedBy = "terraform"
  })
  
  # Flatten tables for easier processing
  tables = {
    for table_key, table in var.tables : table_key => merge(table, {
      table_key = table_key
      name = "${var.name_prefix}-${table_key}"
      
      # Set defaults
      billing_mode = lookup(table, "billing_mode", "PAY_PER_REQUEST")
      hash_key = table.hash_key
      range_key = lookup(table, "range_key", null)
      
      # Encryption configuration
      server_side_encryption = lookup(table, "server_side_encryption", {
        enabled = true
        kms_key_id = null
      })
      
      # Point-in-time recovery
      point_in_time_recovery_enabled = lookup(table, "point_in_time_recovery_enabled", true)
      
      # DynamoDB Streams
      stream_enabled = lookup(table, "stream_enabled", false)
      stream_view_type = lookup(table, "stream_view_type", "NEW_AND_OLD_IMAGES")
      
      # Table class
      table_class = lookup(table, "table_class", "STANDARD")
      
      # Deletion protection
      deletion_protection_enabled = lookup(table, "deletion_protection_enabled", true)
      
      # TTL configuration
      ttl = lookup(table, "ttl", null)
    })
  }
  
  # Global tables configuration
  global_tables = {
    for gt_key, gt in var.global_tables : gt_key => merge(gt, {
      global_table_key = gt_key
      name = "${var.name_prefix}-global-${gt_key}"
      
      # Replicas configuration with defaults
      replicas = [
        for replica in gt.replicas : merge(replica, {
          region_name = replica.region_name
          
          # Point-in-time recovery for replica
          point_in_time_recovery_enabled = lookup(replica, "point_in_time_recovery_enabled", true)
          
          # Table class for replica
          table_class = lookup(replica, "table_class", "STANDARD")
          
          # Global secondary indexes for replica
          global_secondary_indexes = lookup(replica, "global_secondary_indexes", [])
        })
      ]
    })
  }
  
  # Backup configurations
  backup_policies = {
    for table_key, table in local.tables : table_key => lookup(table, "backup", {
      continuous_backups_enabled = true
      point_in_time_recovery_enabled = true
    })
  }
}

# DynamoDB Tables
resource "aws_dynamodb_table" "tables" {
  for_each = local.tables
  
  name           = each.value.name
  billing_mode   = each.value.billing_mode
  hash_key       = each.value.hash_key
  range_key      = each.value.range_key
  table_class    = each.value.table_class
  
  # Read/Write capacity (only for PROVISIONED billing mode)
  read_capacity  = each.value.billing_mode == "PROVISIONED" ? lookup(each.value, "read_capacity", 5) : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? lookup(each.value, "write_capacity", 5) : null
  
  # Stream configuration
  stream_enabled   = each.value.stream_enabled
  stream_view_type = each.value.stream_enabled ? each.value.stream_view_type : null
  
  # Deletion protection
  deletion_protection_enabled = each.value.deletion_protection_enabled
  
  # Attributes
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }
  
  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = lookup(each.value, "global_secondary_indexes", [])
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
      
      # Capacity for provisioned billing mode
      read_capacity  = each.value.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "read_capacity", 5) : null
      write_capacity = each.value.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "write_capacity", 5) : null
    }
  }
  
  # Local Secondary Indexes
  dynamic "local_secondary_index" {
    for_each = lookup(each.value, "local_secondary_indexes", [])
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }
  
  # TTL configuration
  dynamic "ttl" {
    for_each = each.value.ttl != null ? [each.value.ttl] : []
    content {
      attribute_name = ttl.value.attribute_name
      enabled        = lookup(ttl.value, "enabled", true)
    }
  }
  
  # Point-in-time recovery
  point_in_time_recovery {
    enabled = each.value.point_in_time_recovery_enabled
  }
  
  # Server-side encryption
  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption.enabled ? [each.value.server_side_encryption] : []
    content {
      enabled     = server_side_encryption.value.enabled
      kms_key_id  = server_side_encryption.value.kms_key_id
    }
  }
  
  # Import configuration for existing tables
  dynamic "import_table" {
    for_each = lookup(each.value, "import_table", null) != null ? [each.value.import_table] : []
    content {
      bucket_name    = import_table.value.bucket_name
      bucket_key_prefix = lookup(import_table.value, "bucket_key_prefix", null)
      compression_type = lookup(import_table.value, "compression_type", null)
      
      input_format_options {
        csv {
          delimiter    = lookup(import_table.value.input_format_options.csv, "delimiter", ",")
          header_list  = lookup(import_table.value.input_format_options.csv, "header_list", null)
        }
      }
    }
  }
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.name
    TableKey = each.key
    BillingMode = each.value.billing_mode
    StreamEnabled = each.value.stream_enabled
  })
  
  # Lifecycle rules
  lifecycle {
    ignore_changes = [
      # Ignore changes to these attributes to prevent issues during updates
      read_capacity,
      write_capacity,
    ]
  }
}

# Auto Scaling for Provisioned Tables
resource "aws_appautoscaling_target" "read_capacity" {
  for_each = {
    for table_key, table in local.tables : table_key => table
    if table.billing_mode == "PROVISIONED" && lookup(table, "autoscaling", {}) != {}
  }
  
  max_capacity       = lookup(each.value.autoscaling.read_capacity, "max", 100)
  min_capacity       = lookup(each.value.autoscaling.read_capacity, "min", 5)
  resource_id        = "table/${aws_dynamodb_table.tables[each.key].name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  
  tags = local.common_tags
}

resource "aws_appautoscaling_target" "write_capacity" {
  for_each = {
    for table_key, table in local.tables : table_key => table
    if table.billing_mode == "PROVISIONED" && lookup(table, "autoscaling", {}) != {}
  }
  
  max_capacity       = lookup(each.value.autoscaling.write_capacity, "max", 100)
  min_capacity       = lookup(each.value.autoscaling.write_capacity, "min", 5)
  resource_id        = "table/${aws_dynamodb_table.tables[each.key].name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  
  tags = local.common_tags
}

# Auto Scaling Policies
resource "aws_appautoscaling_policy" "read_capacity_policy" {
  for_each = {
    for table_key, table in local.tables : table_key => table
    if table.billing_mode == "PROVISIONED" && lookup(table, "autoscaling", {}) != {}
  }
  
  name               = "${each.value.name}-read-capacity-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_capacity[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.read_capacity[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_capacity[each.key].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    
    target_value       = lookup(each.value.autoscaling.read_capacity, "target_utilization", 70.0)
    scale_in_cooldown  = lookup(each.value.autoscaling.read_capacity, "scale_in_cooldown", 60)
    scale_out_cooldown = lookup(each.value.autoscaling.read_capacity, "scale_out_cooldown", 60)
  }
}

resource "aws_appautoscaling_policy" "write_capacity_policy" {
  for_each = {
    for table_key, table in local.tables : table_key => table
    if table.billing_mode == "PROVISIONED" && lookup(table, "autoscaling", {}) != {}
  }
  
  name               = "${each.value.name}-write-capacity-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_capacity[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.write_capacity[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_capacity[each.key].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    
    target_value       = lookup(each.value.autoscaling.write_capacity, "target_utilization", 70.0)
    scale_in_cooldown  = lookup(each.value.autoscaling.write_capacity, "scale_in_cooldown", 60)
    scale_out_cooldown = lookup(each.value.autoscaling.write_capacity, "scale_out_cooldown", 60)
  }
}

# Global Tables (DynamoDB Global Tables V2)
resource "aws_dynamodb_table" "global_tables" {
  for_each = local.global_tables
  
  name         = each.value.name
  billing_mode = "PAY_PER_REQUEST"  # Global tables must use PAY_PER_REQUEST
  hash_key     = each.value.hash_key
  range_key    = lookup(each.value, "range_key", null)
  
  # Stream is required for global tables
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  # Attributes
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }
  
  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = lookup(each.value, "global_secondary_indexes", [])
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
    }
  }
  
  # TTL configuration
  dynamic "ttl" {
    for_each = lookup(each.value, "ttl", null) != null ? [each.value.ttl] : []
    content {
      attribute_name = ttl.value.attribute_name
      enabled        = lookup(ttl.value, "enabled", true)
    }
  }
  
  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }
  
  # Server-side encryption
  server_side_encryption {
    enabled    = true
    kms_key_id = lookup(each.value, "kms_key_id", null)
  }
  
  # Replicas
  dynamic "replica" {
    for_each = each.value.replicas
    content {
      region_name = replica.value.region_name
      
      # Point-in-time recovery for replica
      point_in_time_recovery = replica.value.point_in_time_recovery_enabled
      
      # Table class for replica
      table_class = replica.value.table_class
      
      # KMS encryption for replica
      kms_key_id = lookup(replica.value, "kms_key_id", null)
      
      # Global secondary indexes for replica
      dynamic "global_secondary_index" {
        for_each = replica.value.global_secondary_indexes
        content {
          name               = global_secondary_index.value.name
          projection_type    = global_secondary_index.value.projection_type
          non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
        }
      }
      
      # Tags for replica
      tags = merge(local.common_tags, lookup(replica.value, "tags", {}), {
        ReplicaRegion = replica.value.region_name
      })
    }
  }
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.name
    GlobalTable = "true"
    Replicas = join(",", [for r in each.value.replicas : r.region_name])
  })
}

# DynamoDB Backup Vault (for continuous backups)
resource "aws_dynamodb_backup_vault" "backup_vault" {
  count = var.enable_backup_vault ? 1 : 0
  
  name         = "${var.name_prefix}-dynamodb-backup-vault"
  kms_key_arn  = var.backup_vault_kms_key_arn
  
  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-dynamodb-backup-vault"
    Purpose = "DynamoDB Backups"
  })
}

# Backup plans for DynamoDB tables
resource "aws_backup_plan" "dynamodb_backup" {
  count = var.enable_backup_vault && length(var.backup_plan_rules) > 0 ? 1 : 0
  
  name = "${var.name_prefix}-dynamodb-backup-plan"
  
  dynamic "rule" {
    for_each = var.backup_plan_rules
    content {
      rule_name                = rule.value.rule_name
      target_vault_name        = aws_dynamodb_backup_vault.backup_vault[0].name
      schedule                 = rule.value.schedule
      start_window            = lookup(rule.value, "start_window", null)
      completion_window       = lookup(rule.value, "completion_window", null)
      enable_continuous_backup = lookup(rule.value, "enable_continuous_backup", false)
      
      dynamic "lifecycle" {
        for_each = lookup(rule.value, "lifecycle", null) != null ? [rule.value.lifecycle] : []
        content {
          cold_storage_after = lookup(lifecycle.value, "cold_storage_after", null)
          delete_after      = lookup(lifecycle.value, "delete_after", null)
        }
      }
      
      dynamic "recovery_point_tags" {
        for_each = lookup(rule.value, "recovery_point_tags", {})
        content {
          key   = recovery_point_tags.key
          value = recovery_point_tags.value
        }
      }
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-dynamodb-backup-plan"
    Service = "DynamoDB"
  })
}

# IAM role for backup service
resource "aws_iam_role" "backup_service_role" {
  count = var.enable_backup_vault ? 1 : 0
  
  name = "${var.name_prefix}-dynamodb-backup-service-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach AWS managed policy for DynamoDB backup
resource "aws_iam_role_policy_attachment" "backup_service_policy" {
  count = var.enable_backup_vault ? 1 : 0
  
  role       = aws_iam_role.backup_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Backup selection for DynamoDB tables
resource "aws_backup_selection" "dynamodb_backup_selection" {
  count = var.enable_backup_vault && length(var.backup_plan_rules) > 0 ? 1 : 0
  
  iam_role_arn = aws_iam_role.backup_service_role[0].arn
  name         = "${var.name_prefix}-dynamodb-backup-selection"
  plan_id      = aws_backup_plan.dynamodb_backup[0].id
  
  # Include all DynamoDB tables created by this module
  dynamic "resources" {
    for_each = aws_dynamodb_table.tables
    content {
      arn = resources.value.arn
    }
  }
  
  # Include global tables as well
  dynamic "resources" {
    for_each = aws_dynamodb_table.global_tables
    content {
      arn = resources.value.arn
    }
  }
  
  # Condition to include tables with specific tags
  dynamic "condition" {
    for_each = var.backup_selection_conditions
    content {
      string_equals = condition.value.string_equals
      string_like   = condition.value.string_like
      string_not_equals = condition.value.string_not_equals
      string_not_like   = condition.value.string_not_like
    }
  }
}

# CloudWatch alarms for DynamoDB monitoring
resource "aws_cloudwatch_metric_alarm" "read_throttled_requests" {
  for_each = var.enable_cloudwatch_alarms ? local.tables : {}
  
  alarm_name          = "${each.value.name}-read-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB read throttled requests"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    TableName = aws_dynamodb_table.tables[each.key].name
  }
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "write_throttled_requests" {
  for_each = var.enable_cloudwatch_alarms ? local.tables : {}
  
  alarm_name          = "${each.value.name}-write-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB write throttled requests"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    TableName = aws_dynamodb_table.tables[each.key].name
  }
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "system_errors" {
  for_each = var.enable_cloudwatch_alarms ? local.tables : {}
  
  alarm_name          = "${each.value.name}-system-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB system errors"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    TableName = aws_dynamodb_table.tables[each.key].name
  }
  
  tags = local.common_tags
}

# DynamoDB Contributor Insights
resource "aws_dynamodb_contributor_insights" "table_insights" {
  for_each = var.enable_contributor_insights ? local.tables : {}
  
  table_name = aws_dynamodb_table.tables[each.key].name
  
  tags = merge(local.common_tags, {
    TableName = aws_dynamodb_table.tables[each.key].name
    Service = "DynamoDB"
  })
}

# Lambda function for DynamoDB Stream processing (optional)
data "aws_iam_policy_document" "stream_processor_assume_role" {
  count = length(var.stream_processor_functions) > 0 ? 1 : 0
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "stream_processor_role" {
  count = length(var.stream_processor_functions) > 0 ? 1 : 0
  
  name               = "${var.name_prefix}-dynamodb-stream-processor-role"
  assume_role_policy = data.aws_iam_policy_document.stream_processor_assume_role[0].json
  
  tags = local.common_tags
}

# IAM policy for DynamoDB Stream processing
data "aws_iam_policy_document" "stream_processor_policy" {
  count = length(var.stream_processor_functions) > 0 ? 1 : 0
  
  statement {
    effect = "Allow"
    
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams"
    ]
    
    resources = [
      for table_key, table in local.tables : "${aws_dynamodb_table.tables[table_key].arn}/stream/*"
      if table.stream_enabled
    ]
  }
  
  statement {
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "stream_processor_policy" {
  count = length(var.stream_processor_functions) > 0 ? 1 : 0
  
  name        = "${var.name_prefix}-dynamodb-stream-processor-policy"
  description = "IAM policy for DynamoDB stream processing Lambda function"
  policy      = data.aws_iam_policy_document.stream_processor_policy[0].json
  
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "stream_processor_policy_attachment" {
  count = length(var.stream_processor_functions) > 0 ? 1 : 0
  
  role       = aws_iam_role.stream_processor_role[0].name
  policy_arn = aws_iam_policy.stream_processor_policy[0].arn
}

# Event source mappings for DynamoDB Streams
resource "aws_lambda_event_source_mapping" "dynamodb_stream_mapping" {
  for_each = var.stream_processor_functions
  
  event_source_arn                   = aws_dynamodb_table.tables[each.value.table_key].stream_arn
  function_name                      = each.value.lambda_function_name
  starting_position                  = lookup(each.value, "starting_position", "LATEST")
  batch_size                        = lookup(each.value, "batch_size", 10)
  maximum_batching_window_in_seconds = lookup(each.value, "maximum_batching_window_in_seconds", null)
  parallelization_factor            = lookup(each.value, "parallelization_factor", null)
  maximum_record_age_in_seconds     = lookup(each.value, "maximum_record_age_in_seconds", null)
  bisect_batch_on_function_error    = lookup(each.value, "bisect_batch_on_function_error", false)
  maximum_retry_attempts            = lookup(each.value, "maximum_retry_attempts", null)
  tumbling_window_in_seconds        = lookup(each.value, "tumbling_window_in_seconds", null)
  
  # Destination configuration for failed records
  dynamic "destination_config" {
    for_each = lookup(each.value, "destination_config", null) != null ? [each.value.destination_config] : []
    content {
      dynamic "on_failure" {
        for_each = lookup(destination_config.value, "on_failure", null) != null ? [destination_config.value.on_failure] : []
        content {
          destination_arn = on_failure.value.destination_arn
        }
      }
    }
  }
  
  # Filter criteria
  dynamic "filter_criteria" {
    for_each = lookup(each.value, "filter_criteria", null) != null ? [each.value.filter_criteria] : []
    content {
      dynamic "filter" {
        for_each = filter_criteria.value.filters
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.stream_processor_policy_attachment
  ]
}

# Data source for current AWS partition and region
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}