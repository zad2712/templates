# Lambda Function
resource "aws_lambda_function" "this" {
  count = var.create_function ? 1 : 0

  function_name                      = var.function_name
  role                              = var.create_role ? aws_iam_role.lambda_role[0].arn : var.lambda_role
  handler                           = var.handler
  runtime                           = var.runtime
  timeout                           = var.timeout
  memory_size                       = var.memory_size
  reserved_concurrent_executions    = var.reserved_concurrent_executions
  publish                           = var.publish
  description                       = var.description
  kms_key_arn                      = var.kms_key_arn
  layers                           = var.layers
  architectures                    = var.architectures
  package_type                     = var.package_type
  image_uri                        = var.image_uri
  source_code_hash                 = var.source_code_hash
  
  # Code deployment - mutually exclusive options
  filename         = var.package_type == "Zip" ? var.filename : null
  s3_bucket        = var.package_type == "Zip" && var.s3_bucket != null ? var.s3_bucket : null
  s3_key           = var.package_type == "Zip" && var.s3_key != null ? var.s3_key : null
  s3_object_version = var.package_type == "Zip" && var.s3_object_version != null ? var.s3_object_version : null

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [var.environment_variables] : []
    content {
      variables = environment.value
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead letter config
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # File system config (EFS)
  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  # Image config (for container images)
  dynamic "image_config" {
    for_each = var.package_type == "Image" && var.image_config != null ? [var.image_config] : []
    content {
      entry_point       = lookup(image_config.value, "entry_point", null)
      command          = lookup(image_config.value, "command", null)
      working_directory = lookup(image_config.value, "working_directory", null)
    }
  }

  # Tracing config
  dynamic "tracing_config" {
    for_each = var.tracing_config != null ? [var.tracing_config] : []
    content {
      mode = tracing_config.value.mode
    }
  }

  # Ephemeral storage
  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage != null ? [var.ephemeral_storage] : []
    content {
      size = ephemeral_storage.value.size
    }
  }

  # Snap start (for Java)
  dynamic "snap_start" {
    for_each = var.snap_start != null ? [var.snap_start] : []
    content {
      apply_on = snap_start.value.apply_on
    }
  }

  # Logging config
  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []
    content {
      log_format                = lookup(logging_config.value, "log_format", null)
      application_log_level     = lookup(logging_config.value, "application_log_level", null)
      system_log_level         = lookup(logging_config.value, "system_log_level", null)
      log_group                = lookup(logging_config.value, "log_group", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.function_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.this,
  ]

  lifecycle {
    ignore_changes = [
      source_code_hash,
      last_modified,
    ]
  }
}

# Lambda Function URL (if enabled)
resource "aws_lambda_function_url" "this" {
  count = var.create_function && var.create_function_url ? 1 : 0

  function_name      = aws_lambda_function.this[0].function_name
  authorization_type = var.function_url_config.authorization_type
  invoke_mode       = lookup(var.function_url_config, "invoke_mode", "BUFFERED")

  dynamic "cors" {
    for_each = lookup(var.function_url_config, "cors", null) != null ? [var.function_url_config.cors] : []
    content {
      allow_credentials = lookup(cors.value, "allow_credentials", false)
      allow_headers     = lookup(cors.value, "allow_headers", null)
      allow_methods     = lookup(cors.value, "allow_methods", null)
      allow_origins     = lookup(cors.value, "allow_origins", null)
      expose_headers    = lookup(cors.value, "expose_headers", null)
      max_age          = lookup(cors.value, "max_age", null)
    }
  }

  # Optional qualifier for versioned functions
  qualifier = var.function_url_config.qualifier
}

# Lambda Alias
resource "aws_lambda_alias" "this" {
  for_each = var.aliases

  name             = each.key
  description      = lookup(each.value, "description", null)
  function_name    = aws_lambda_function.this[0].function_name
  function_version = lookup(each.value, "function_version", "$LATEST")

  # Routing configuration for weighted alias
  dynamic "routing_config" {
    for_each = lookup(each.value, "routing_config", null) != null ? [each.value.routing_config] : []
    content {
      additional_version_weights = routing_config.value.additional_version_weights
    }
  }
}

# Lambda Provisioned Concurrency
resource "aws_lambda_provisioned_concurrency_config" "this" {
  for_each = var.provisioned_concurrency_config

  function_name                     = aws_lambda_function.this[0].function_name
  provisioned_concurrent_executions = each.value.provisioned_concurrent_executions
  qualifier                        = each.value.qualifier

  depends_on = [aws_lambda_alias.this]
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  count = var.create_function && var.create_role ? 1 : 0

  name               = "${var.function_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  count = var.create_function && var.create_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.create_function && var.create_role ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC execution policy (if VPC config is provided)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count = var.create_function && var.create_role && var.vpc_config != null ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom IAM policies
resource "aws_iam_role_policy" "lambda_custom_policy" {
  for_each = var.create_function && var.create_role ? var.policy_statements : {}

  name   = each.key
  role   = aws_iam_role.lambda_role[0].id
  policy = jsonencode(each.value)
}

# Attach existing policies
resource "aws_iam_role_policy_attachment" "lambda_policy_attachments" {
  for_each = var.create_function && var.create_role ? toset(var.attach_policy_arns) : toset([])

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = each.value
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_function && var.create_cloudwatch_log_group ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = var.cloudwatch_logs_kms_key_id

  tags = var.tags
}

# CloudWatch Log Group policy
resource "aws_iam_role_policy" "lambda_logs" {
  count = var.create_function && var.create_role && var.create_cloudwatch_log_group ? 1 : 0

  name = "${var.function_name}-lambda-logs"
  role = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  count = var.create_function && var.create_role && var.create_cloudwatch_log_group ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Event Source Mappings
resource "aws_lambda_event_source_mapping" "this" {
  for_each = var.event_source_mappings

  event_source_arn                   = each.value.event_source_arn
  function_name                      = aws_lambda_function.this[0].arn
  starting_position                  = lookup(each.value, "starting_position", null)
  starting_position_timestamp        = lookup(each.value, "starting_position_timestamp", null)
  batch_size                        = lookup(each.value, "batch_size", null)
  maximum_batching_window_in_seconds = lookup(each.value, "maximum_batching_window_in_seconds", null)
  enabled                           = lookup(each.value, "enabled", true)
  parallelization_factor            = lookup(each.value, "parallelization_factor", null)
  maximum_record_age_in_seconds     = lookup(each.value, "maximum_record_age_in_seconds", null)
  bisect_batch_on_function_error    = lookup(each.value, "bisect_batch_on_function_error", null)
  maximum_retry_attempts            = lookup(each.value, "maximum_retry_attempts", null)
  tumbling_window_in_seconds        = lookup(each.value, "tumbling_window_in_seconds", null)
  topics                           = lookup(each.value, "topics", null)
  queues                           = lookup(each.value, "queues", null)
  function_response_types          = lookup(each.value, "function_response_types", null)

  dynamic "amazon_managed_kafka_event_source_config" {
    for_each = lookup(each.value, "amazon_managed_kafka_event_source_config", null) != null ? [each.value.amazon_managed_kafka_event_source_config] : []
    content {
      consumer_group_id = lookup(amazon_managed_kafka_event_source_config.value, "consumer_group_id", null)
    }
  }

  dynamic "self_managed_kafka_event_source_config" {
    for_each = lookup(each.value, "self_managed_kafka_event_source_config", null) != null ? [each.value.self_managed_kafka_event_source_config] : []
    content {
      consumer_group_id = lookup(self_managed_kafka_event_source_config.value, "consumer_group_id", null)
    }
  }

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

  dynamic "source_access_configuration" {
    for_each = lookup(each.value, "source_access_configuration", [])
    content {
      type = source_access_configuration.value.type
      uri  = source_access_configuration.value.uri
    }
  }

  dynamic "filter_criteria" {
    for_each = lookup(each.value, "filter_criteria", null) != null ? [each.value.filter_criteria] : []
    content {
      dynamic "filter" {
        for_each = filter_criteria.value.filters
        content {
          pattern = lookup(filter.value, "pattern", null)
        }
      }
    }
  }

  dynamic "scaling_config" {
    for_each = lookup(each.value, "scaling_config", null) != null ? [each.value.scaling_config] : []
    content {
      maximum_concurrency = lookup(scaling_config.value, "maximum_concurrency", null)
    }
  }

  dynamic "document_db_event_source_config" {
    for_each = lookup(each.value, "document_db_event_source_config", null) != null ? [each.value.document_db_event_source_config] : []
    content {
      database_name   = document_db_event_source_config.value.database_name
      collection_name = lookup(document_db_event_source_config.value, "collection_name", null)
      full_document   = lookup(document_db_event_source_config.value, "full_document", null)
    }
  }
}

# Lambda Permissions
resource "aws_lambda_permission" "this" {
  for_each = var.lambda_permissions

  statement_id  = each.key
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = each.value.principal
  source_arn    = lookup(each.value, "source_arn", null)
  source_account = lookup(each.value, "source_account", null)
  qualifier     = lookup(each.value, "qualifier", null)
  event_source_token = lookup(each.value, "event_source_token", null)
  principal_org_id   = lookup(each.value, "principal_org_id", null)
  function_url_auth_type = lookup(each.value, "function_url_auth_type", null)
}

# Lambda Layers
resource "aws_lambda_layer_version" "this" {
  for_each = var.lambda_layers

  layer_name               = each.key
  filename                = lookup(each.value, "filename", null)
  s3_bucket              = lookup(each.value, "s3_bucket", null)
  s3_key                 = lookup(each.value, "s3_key", null)
  s3_object_version      = lookup(each.value, "s3_object_version", null)
  source_code_hash       = lookup(each.value, "source_code_hash", null)
  compatible_runtimes    = lookup(each.value, "compatible_runtimes", [])
  compatible_architectures = lookup(each.value, "compatible_architectures", null)
  description            = lookup(each.value, "description", null)
  license_info          = lookup(each.value, "license_info", null)
  skip_destroy          = lookup(each.value, "skip_destroy", false)

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "duration" {
  count = var.create_function && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarms_config.duration.evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = var.cloudwatch_alarms_config.duration.period
  statistic           = var.cloudwatch_alarms_config.duration.statistic
  threshold           = var.cloudwatch_alarms_config.duration.threshold
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this[0].function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  count = var.create_function && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarms_config.errors.evaluation_periods
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.cloudwatch_alarms_config.errors.period
  statistic           = var.cloudwatch_alarms_config.errors.statistic
  threshold           = var.cloudwatch_alarms_config.errors.threshold
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this[0].function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  count = var.create_function && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarms_config.throttles.evaluation_periods
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = var.cloudwatch_alarms_config.throttles.period
  statistic           = var.cloudwatch_alarms_config.throttles.statistic
  threshold           = var.cloudwatch_alarms_config.throttles.threshold
  alarm_description   = "This metric monitors lambda throttles"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this[0].function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "concurrent_executions" {
  count = var.create_function && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-concurrent-executions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarms_config.concurrent_executions.evaluation_periods
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = var.cloudwatch_alarms_config.concurrent_executions.period
  statistic           = var.cloudwatch_alarms_config.concurrent_executions.statistic
  threshold           = var.cloudwatch_alarms_config.concurrent_executions.threshold
  alarm_description   = "This metric monitors lambda concurrent executions"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this[0].function_name
  }

  tags = var.tags
}
