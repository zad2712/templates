# DynamoDB Table
resource "aws_dynamodb_table" "this" {
  count = var.create_table ? 1 : 0

  name             = var.table_name
  billing_mode     = var.billing_mode
  hash_key         = var.hash_key
  range_key        = var.range_key
  read_capacity    = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity   = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  table_class                     = var.table_class
  deletion_protection_enabled     = var.deletion_protection_enabled
  point_in_time_recovery_enabled = var.point_in_time_recovery_enabled

  # Attributes
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key          = global_secondary_index.value.hash_key
      range_key         = lookup(global_secondary_index.value, "range_key", null)
      projection_type   = global_secondary_index.value.projection_type
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
      read_capacity     = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "read_capacity", null) : null
      write_capacity    = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "write_capacity", null) : null
    }
  }

  # Local Secondary Indexes
  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name               = local_secondary_index.value.name
      range_key         = local_secondary_index.value.range_key
      projection_type   = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }

  # Server-side encryption
  dynamic "server_side_encryption" {
    for_each = var.server_side_encryption_enabled ? [1] : []
    content {
      enabled     = var.server_side_encryption_enabled
      kms_key_arn = var.server_side_encryption_kms_key_id
    }
  }

  # TTL
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      attribute_name = var.ttl_attribute_name
      enabled        = var.ttl_enabled
    }
  }

  # Replica configuration for global tables
  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name                    = replica.value.region_name
      kms_key_arn                   = lookup(replica.value, "kms_key_arn", null)
      point_in_time_recovery        = lookup(replica.value, "point_in_time_recovery", null)
      propagate_tags               = lookup(replica.value, "propagate_tags", null)
    }
  }

  # Import configuration
  dynamic "import_table" {
    for_each = var.import_table != null ? [var.import_table] : []
    content {
      bucket_owner       = lookup(import_table.value, "bucket_owner", null)
      s3_bucket_source {
        bucket             = import_table.value.s3_bucket_source.bucket
        bucket_owner       = lookup(import_table.value.s3_bucket_source, "bucket_owner", null)
        key_prefix         = lookup(import_table.value.s3_bucket_source, "key_prefix", null)
      }
      input_compression_type = lookup(import_table.value, "input_compression_type", null)
      input_format          = import_table.value.input_format
      input_format_options = lookup(import_table.value, "input_format_options", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.table_name
    }
  )

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity,
    ]
  }
}

# Auto Scaling for Read Capacity
resource "aws_appautoscaling_target" "read_target" {
  count = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0

  max_capacity       = var.autoscaling_read.max_capacity
  min_capacity       = var.autoscaling_read.min_capacity
  resource_id        = "table/${aws_dynamodb_table.this[0].name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.this]
}

resource "aws_appautoscaling_policy" "read_policy" {
  count = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0

  name               = "${var.table_name}-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_read.target_value
    scale_in_cooldown  = var.autoscaling_read.scale_in_cooldown
    scale_out_cooldown = var.autoscaling_read.scale_out_cooldown
  }
}

# Auto Scaling for Write Capacity
resource "aws_appautoscaling_target" "write_target" {
  count = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0

  max_capacity       = var.autoscaling_write.max_capacity
  min_capacity       = var.autoscaling_write.min_capacity
  resource_id        = "table/${aws_dynamodb_table.this[0].name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.this]
}

resource "aws_appautoscaling_policy" "write_policy" {
  count = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? 1 : 0

  name               = "${var.table_name}-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_write.target_value
    scale_in_cooldown  = var.autoscaling_write.scale_in_cooldown
    scale_out_cooldown = var.autoscaling_write.scale_out_cooldown
  }
}

# Auto Scaling for GSI Read Capacity
resource "aws_appautoscaling_target" "gsi_read_target" {
  for_each = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? var.gsi_autoscaling : {}

  max_capacity       = each.value.read.max_capacity
  min_capacity       = each.value.read.min_capacity
  resource_id        = "table/${aws_dynamodb_table.this[0].name}/index/${each.key}"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.this]
}

resource "aws_appautoscaling_policy" "gsi_read_policy" {
  for_each = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? var.gsi_autoscaling : {}

  name               = "${var.table_name}-${each.key}-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.gsi_read_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_read_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.gsi_read_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = each.value.read.target_value
    scale_in_cooldown  = each.value.read.scale_in_cooldown
    scale_out_cooldown = each.value.read.scale_out_cooldown
  }
}

# Auto Scaling for GSI Write Capacity
resource "aws_appautoscaling_target" "gsi_write_target" {
  for_each = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? var.gsi_autoscaling : {}

  max_capacity       = each.value.write.max_capacity
  min_capacity       = each.value.write.min_capacity
  resource_id        = "table/${aws_dynamodb_table.this[0].name}/index/${each.key}"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.this]
}

resource "aws_appautoscaling_policy" "gsi_write_policy" {
  for_each = var.billing_mode == "PROVISIONED" && var.autoscaling_enabled ? var.gsi_autoscaling : {}

  name               = "${var.table_name}-${each.key}-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.gsi_write_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_write_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.gsi_write_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = each.value.write.target_value
    scale_in_cooldown  = each.value.write.scale_in_cooldown
    scale_out_cooldown = each.value.write.scale_out_cooldown
  }
}

# CloudWatch Contributor Insights
resource "aws_dynamodb_contributor_insights" "this" {
  count      = var.enable_contributor_insights ? 1 : 0
  table_name = aws_dynamodb_table.this[0].name

  depends_on = [aws_dynamodb_table.this]
}

resource "aws_dynamodb_contributor_insights" "gsi" {
  for_each = var.enable_contributor_insights ? toset([for gsi in var.global_secondary_indexes : gsi.name]) : []

  table_name = aws_dynamodb_table.this[0].name
  index_name = each.value

  depends_on = [aws_dynamodb_table.this]
}

# Kinesis Data Firehose for DynamoDB Streams (if enabled)
resource "aws_kinesis_firehose_delivery_stream" "dynamodb_stream" {
  count       = var.stream_enabled && var.enable_kinesis_firehose ? 1 : 0
  name        = "${var.table_name}-stream-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = var.kinesis_firehose_role_arn
    bucket_arn = var.kinesis_firehose_s3_bucket_arn

    prefix              = "dynamodb-streams/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/"
    buffer_size         = 5
    buffer_interval     = 300
    compression_format  = "GZIP"

    dynamic_partitioning {
      enabled = true
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.kinesis_firehose_lambda_arn
        }
      }
    }

    data_format_conversion_configuration {
      enabled = true

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = var.kinesis_firehose_glue_database
        table_name    = var.kinesis_firehose_glue_table
        role_arn      = var.kinesis_firehose_role_arn
      }
    }
  }

  tags = var.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "read_throttled_requests" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.table_name}-read-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.read_throttled_requests_threshold
  alarm_description   = "This metric monitors DynamoDB read throttled requests"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    TableName = aws_dynamodb_table.this[0].name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "write_throttled_requests" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.table_name}-write-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.write_throttled_requests_threshold
  alarm_description   = "This metric monitors DynamoDB write throttled requests"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    TableName = aws_dynamodb_table.this[0].name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "consumed_read_capacity" {
  count = var.billing_mode == "PROVISIONED" && var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.table_name}-consumed-read-capacity-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.consumed_read_capacity_threshold
  alarm_description   = "This metric monitors DynamoDB consumed read capacity"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    TableName = aws_dynamodb_table.this[0].name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "consumed_write_capacity" {
  count = var.billing_mode == "PROVISIONED" && var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.table_name}-consumed-write-capacity-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConsumedWriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.consumed_write_capacity_threshold
  alarm_description   = "This metric monitors DynamoDB consumed write capacity"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    TableName = aws_dynamodb_table.this[0].name
  }

  tags = var.tags
}
