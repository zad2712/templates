# =============================================================================
# AWS Lambda Module
# =============================================================================
# This module creates AWS Lambda functions with comprehensive configuration
# including VPC integration, IAM roles, environment variables, and monitoring
# Features:
# - Lambda functions with multiple runtime support
# - VPC configuration for secure networking
# - IAM role and policy management
# - Environment variables and encryption
# - Dead letter queues and error handling
# - Layer management and versioning
# - Event source mappings
# - Monitoring and logging integration
# - Performance and concurrency settings
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.9.0"
}

# Local values for computed configurations
locals {
  # Common tags for all resources
  common_tags = merge(
    var.common_tags,
    {
      Module = "lambda"
    }
  )

  # Function configuration
  function_configs = {
    for name, config in var.lambda_functions : name => {
      function_name    = "${var.name_prefix}-${name}"
      runtime         = config.runtime
      handler         = config.handler
      filename        = config.filename
      s3_bucket       = config.s3_bucket
      s3_key          = config.s3_key
      s3_object_version = config.s3_object_version
      source_code_hash = config.source_code_hash
      description     = config.description
      timeout         = config.timeout
      memory_size     = config.memory_size
      reserved_concurrent_executions = config.reserved_concurrent_executions
      provisioned_concurrency_config = config.provisioned_concurrency_config
      publish         = config.publish
      
      # Environment configuration
      environment = config.environment_variables != null ? {
        variables = merge(
          config.environment_variables,
          var.global_environment_variables
        )
      } : null

      # VPC configuration
      vpc_config = config.vpc_config != null ? {
        subnet_ids         = config.vpc_config.subnet_ids
        security_group_ids = config.vpc_config.security_group_ids
      } : null

      # Dead letter queue configuration
      dead_letter_config = config.dead_letter_config != null ? {
        target_arn = config.dead_letter_config.target_arn
      } : null

      # Tracing configuration
      tracing_config = {
        mode = config.tracing_mode
      }

      # Image configuration (for container images)
      image_config = config.image_config != null ? {
        entry_point       = config.image_config.entry_point
        command          = config.image_config.command
        working_directory = config.image_config.working_directory
      } : null

      # Ephemeral storage configuration
      ephemeral_storage = config.ephemeral_storage_size != null ? {
        size = config.ephemeral_storage_size
      } : null

      # File system configuration
      file_system_config = config.file_system_configs != null ? [
        for fs_config in config.file_system_configs : {
          arn              = fs_config.arn
          local_mount_path = fs_config.local_mount_path
        }
      ] : []

      # Logging configuration
      logging_config = config.logging_config != null ? {
        log_format                = config.logging_config.log_format
        application_log_level     = config.logging_config.application_log_level
        system_log_level         = config.logging_config.system_log_level
        log_group               = config.logging_config.log_group
      } : null

      # Snap start configuration
      snap_start = config.snap_start_apply_on != null ? {
        apply_on = config.snap_start_apply_on
      } : null

      # Layers
      layers = config.layers

      # Code signing configuration
      code_signing_config_arn = config.code_signing_config_arn

      # Architecture
      architectures = config.architectures

      # Package type
      package_type = config.package_type

      # Image URI (for container images)
      image_uri = config.image_uri

      # KMS key for environment variables encryption
      kms_key_arn = config.kms_key_arn != null ? config.kms_key_arn : var.default_kms_key_arn

      # Tags
      tags = merge(local.common_tags, config.tags)
    }
  }

  # Event source mapping configurations
  event_source_mappings = flatten([
    for func_name, func_config in var.lambda_functions : [
      for mapping_name, mapping_config in coalesce(func_config.event_source_mappings, {}) : {
        function_name    = "${var.name_prefix}-${func_name}"
        mapping_name     = mapping_name
        event_source_arn = mapping_config.event_source_arn
        batch_size       = mapping_config.batch_size
        maximum_batching_window_in_seconds = mapping_config.maximum_batching_window_in_seconds
        starting_position = mapping_config.starting_position
        starting_position_timestamp = mapping_config.starting_position_timestamp
        parallelization_factor = mapping_config.parallelization_factor
        maximum_record_age_in_seconds = mapping_config.maximum_record_age_in_seconds
        bisect_batch_on_function_error = mapping_config.bisect_batch_on_function_error
        maximum_retry_attempts = mapping_config.maximum_retry_attempts
        tumbling_window_in_seconds = mapping_config.tumbling_window_in_seconds
        topics = mapping_config.topics
        queues = mapping_config.queues
        source_access_configurations = mapping_config.source_access_configurations
        self_managed_event_source = mapping_config.self_managed_event_source
        self_managed_kafka_event_source_config = mapping_config.self_managed_kafka_event_source_config
        amazon_managed_kafka_event_source_config = mapping_config.amazon_managed_kafka_event_source_config
        document_db_event_source_config = mapping_config.document_db_event_source_config
        filter_criteria = mapping_config.filter_criteria
        function_response_types = mapping_config.function_response_types
        scaling_config = mapping_config.scaling_config
        destination_config = mapping_config.destination_config
      }
    ]
  ])

  # Function URL configurations
  function_urls = {
    for func_name, func_config in var.lambda_functions : func_name => func_config.function_url_config
    if func_config.function_url_config != null
  }

  # Permission configurations
  function_permissions = flatten([
    for func_name, func_config in var.lambda_functions : [
      for perm_name, perm_config in coalesce(func_config.permissions, {}) : {
        function_name = "${var.name_prefix}-${func_name}"
        permission_name = perm_name
        statement_id = perm_config.statement_id
        action = perm_config.action
        principal = perm_config.principal
        source_arn = perm_config.source_arn
        source_account = perm_config.source_account
        event_source_token = perm_config.event_source_token
        qualifier = perm_config.qualifier
        principal_org_id = perm_config.principal_org_id
        function_url_auth_type = perm_config.function_url_auth_type
      }
    ]
  ])
}

# =============================================================================
# IAM Role and Policies for Lambda Functions
# =============================================================================

# Lambda execution role
resource "aws_iam_role" "lambda_execution_role" {
  for_each = { for name, config in local.function_configs : name => config }

  name = "${each.value.function_name}-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = each.value.tags
}

# Basic Lambda execution policy attachment
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  for_each = { for name, config in local.function_configs : name => config }

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role[each.key].name
}

# VPC execution policy attachment (if VPC is configured)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  for_each = { for name, config in local.function_configs : name => config if config.vpc_config != null }

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_execution_role[each.key].name
}

# X-Ray tracing policy attachment (if tracing is enabled)
resource "aws_iam_role_policy_attachment" "lambda_xray_execution" {
  for_each = { 
    for name, config in local.function_configs : name => config 
    if config.tracing_config.mode == "Active"
  }

  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.lambda_execution_role[each.key].name
}

# Custom inline policies for Lambda functions
resource "aws_iam_role_policy" "lambda_custom_policy" {
  for_each = { 
    for name, config in var.lambda_functions : name => config 
    if config.custom_iam_policy != null 
  }

  name = "${var.name_prefix}-${each.key}-custom-policy"
  role = aws_iam_role.lambda_execution_role[each.key].id

  policy = each.value.custom_iam_policy
}

# KMS key access policy for environment variables encryption
resource "aws_iam_role_policy" "lambda_kms_policy" {
  for_each = { 
    for name, config in local.function_configs : name => config 
    if config.kms_key_arn != null 
  }

  name = "${each.value.function_name}-kms-policy"
  role = aws_iam_role.lambda_execution_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = each.value.kms_key_arn
      }
    ]
  })
}

# Additional managed policy attachments
resource "aws_iam_role_policy_attachment" "lambda_additional_policies" {
  for_each = { 
    for item in flatten([
      for func_name, func_config in var.lambda_functions : [
        for policy in coalesce(func_config.additional_iam_policies, []) : {
          function_name = func_name
          policy_arn = policy
          key = "${func_name}-${replace(policy, "/[^a-zA-Z0-9]/", "-")}"
        }
      ]
    ]) : item.key => item
  }

  policy_arn = each.value.policy_arn
  role       = aws_iam_role.lambda_execution_role[each.value.function_name].name
}

# =============================================================================
# Lambda Functions
# =============================================================================

resource "aws_lambda_function" "functions" {
  for_each = local.function_configs

  function_name                  = each.value.function_name
  role                          = aws_iam_role.lambda_execution_role[each.key].arn
  runtime                       = each.value.package_type == "Image" ? null : each.value.runtime
  handler                       = each.value.package_type == "Image" ? null : each.value.handler
  filename                      = each.value.filename
  s3_bucket                     = each.value.s3_bucket
  s3_key                        = each.value.s3_key
  s3_object_version             = each.value.s3_object_version
  source_code_hash              = each.value.source_code_hash
  description                   = each.value.description
  timeout                       = each.value.timeout
  memory_size                   = each.value.memory_size
  reserved_concurrent_executions = each.value.reserved_concurrent_executions
  publish                       = each.value.publish
  layers                        = each.value.layers
  code_signing_config_arn       = each.value.code_signing_config_arn
  architectures                 = each.value.architectures
  package_type                  = each.value.package_type
  image_uri                     = each.value.image_uri
  kms_key_arn                   = each.value.kms_key_arn

  dynamic "environment" {
    for_each = each.value.environment != null ? [each.value.environment] : []
    content {
      variables = environment.value.variables
    }
  }

  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [each.value.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_config != null ? [each.value.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = [each.value.tracing_config]
    content {
      mode = tracing_config.value.mode
    }
  }

  dynamic "image_config" {
    for_each = each.value.image_config != null ? [each.value.image_config] : []
    content {
      entry_point       = image_config.value.entry_point
      command          = image_config.value.command
      working_directory = image_config.value.working_directory
    }
  }

  dynamic "ephemeral_storage" {
    for_each = each.value.ephemeral_storage != null ? [each.value.ephemeral_storage] : []
    content {
      size = ephemeral_storage.value.size
    }
  }

  dynamic "file_system_config" {
    for_each = each.value.file_system_config
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  dynamic "logging_config" {
    for_each = each.value.logging_config != null ? [each.value.logging_config] : []
    content {
      log_format                = logging_config.value.log_format
      application_log_level     = logging_config.value.application_log_level
      system_log_level         = logging_config.value.system_log_level
      log_group               = logging_config.value.log_group
    }
  }

  dynamic "snap_start" {
    for_each = each.value.snap_start != null ? [each.value.snap_start] : []
    content {
      apply_on = snap_start.value.apply_on
    }
  }

  tags = each.value.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_execution,
    aws_cloudwatch_log_group.function_logs
  ]
}

# =============================================================================
# Provisioned Concurrency Configuration
# =============================================================================

resource "aws_lambda_provisioned_concurrency_config" "provisioned_concurrency" {
  for_each = {
    for name, config in local.function_configs : name => config
    if config.provisioned_concurrency_config != null
  }

  function_name                     = aws_lambda_function.functions[each.key].function_name
  provisioned_concurrent_executions = each.value.provisioned_concurrency_config.provisioned_concurrent_executions
  qualifier                        = each.value.provisioned_concurrency_config.qualifier

  depends_on = [aws_lambda_function.functions]
}

# =============================================================================
# Function URLs
# =============================================================================

resource "aws_lambda_function_url" "function_urls" {
  for_each = local.function_urls

  function_name      = aws_lambda_function.functions[each.key].function_name
  authorization_type = each.value.authorization_type
  
  dynamic "cors" {
    for_each = each.value.cors != null ? [each.value.cors] : []
    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age          = cors.value.max_age
    }
  }

  depends_on = [aws_lambda_function.functions]
}

# =============================================================================
# Event Source Mappings
# =============================================================================

resource "aws_lambda_event_source_mapping" "event_source_mappings" {
  for_each = {
    for mapping in local.event_source_mappings : 
    "${mapping.function_name}-${mapping.mapping_name}" => mapping
  }

  function_name                          = each.value.function_name
  event_source_arn                      = each.value.event_source_arn
  batch_size                            = each.value.batch_size
  maximum_batching_window_in_seconds     = each.value.maximum_batching_window_in_seconds
  starting_position                     = each.value.starting_position
  starting_position_timestamp           = each.value.starting_position_timestamp
  parallelization_factor                = each.value.parallelization_factor
  maximum_record_age_in_seconds         = each.value.maximum_record_age_in_seconds
  bisect_batch_on_function_error        = each.value.bisect_batch_on_function_error
  maximum_retry_attempts                = each.value.maximum_retry_attempts
  tumbling_window_in_seconds            = each.value.tumbling_window_in_seconds
  topics                               = each.value.topics
  queues                               = each.value.queues
  function_response_types              = each.value.function_response_types

  dynamic "source_access_configuration" {
    for_each = coalesce(each.value.source_access_configurations, [])
    content {
      type = source_access_configuration.value.type
      uri  = source_access_configuration.value.uri
    }
  }

  dynamic "self_managed_event_source" {
    for_each = each.value.self_managed_event_source != null ? [each.value.self_managed_event_source] : []
    content {
      endpoints = self_managed_event_source.value.endpoints
    }
  }

  dynamic "self_managed_kafka_event_source_config" {
    for_each = each.value.self_managed_kafka_event_source_config != null ? [each.value.self_managed_kafka_event_source_config] : []
    content {
      consumer_group_id = self_managed_kafka_event_source_config.value.consumer_group_id
    }
  }

  dynamic "amazon_managed_kafka_event_source_config" {
    for_each = each.value.amazon_managed_kafka_event_source_config != null ? [each.value.amazon_managed_kafka_event_source_config] : []
    content {
      consumer_group_id = amazon_managed_kafka_event_source_config.value.consumer_group_id
    }
  }

  dynamic "document_db_event_source_config" {
    for_each = each.value.document_db_event_source_config != null ? [each.value.document_db_event_source_config] : []
    content {
      collection_name = document_db_event_source_config.value.collection_name
      database_name   = document_db_event_source_config.value.database_name
      full_document   = document_db_event_source_config.value.full_document
    }
  }

  dynamic "filter_criteria" {
    for_each = each.value.filter_criteria != null ? [each.value.filter_criteria] : []
    content {
      dynamic "filter" {
        for_each = filter_criteria.value.filters
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }

  dynamic "scaling_config" {
    for_each = each.value.scaling_config != null ? [each.value.scaling_config] : []
    content {
      maximum_concurrency = scaling_config.value.maximum_concurrency
    }
  }

  dynamic "destination_config" {
    for_each = each.value.destination_config != null ? [each.value.destination_config] : []
    content {
      dynamic "on_failure" {
        for_each = destination_config.value.on_failure != null ? [destination_config.value.on_failure] : []
        content {
          destination_arn = on_failure.value.destination_arn
        }
      }
    }
  }

  depends_on = [aws_lambda_function.functions]
}

# =============================================================================
# Lambda Permissions
# =============================================================================

resource "aws_lambda_permission" "function_permissions" {
  for_each = {
    for permission in local.function_permissions :
    "${permission.function_name}-${permission.permission_name}" => permission
  }

  statement_id           = each.value.statement_id
  action                = each.value.action
  function_name         = each.value.function_name
  principal             = each.value.principal
  source_arn            = each.value.source_arn
  source_account        = each.value.source_account
  event_source_token    = each.value.event_source_token
  qualifier             = each.value.qualifier
  principal_org_id      = each.value.principal_org_id
  function_url_auth_type = each.value.function_url_auth_type

  depends_on = [aws_lambda_function.functions]
}

# =============================================================================
# CloudWatch Log Groups
# =============================================================================

resource "aws_cloudwatch_log_group" "function_logs" {
  for_each = local.function_configs

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    each.value.tags,
    {
      Purpose = "Lambda function logs"
    }
  )
}

# =============================================================================
# Lambda Aliases (if enabled)
# =============================================================================

resource "aws_lambda_alias" "function_aliases" {
  for_each = {
    for name, config in var.lambda_functions : name => config
    if config.aliases != null
  }

  function_name    = aws_lambda_function.functions[each.key].function_name
  function_version = aws_lambda_function.functions[each.key].version
  name            = each.value.aliases.name
  description     = each.value.aliases.description

  dynamic "routing_config" {
    for_each = each.value.aliases.routing_config != null ? [each.value.aliases.routing_config] : []
    content {
      additional_version_weights = routing_config.value.additional_version_weights
    }
  }

  depends_on = [aws_lambda_function.functions]
}

# =============================================================================
# Lambda Layers (if provided)
# =============================================================================

resource "aws_lambda_layer_version" "layers" {
  for_each = var.lambda_layers

  layer_name               = "${var.name_prefix}-${each.key}"
  filename                = each.value.filename
  s3_bucket              = each.value.s3_bucket
  s3_key                 = each.value.s3_key
  s3_object_version      = each.value.s3_object_version
  source_code_hash       = each.value.source_code_hash
  compatible_runtimes    = each.value.compatible_runtimes
  compatible_architectures = each.value.compatible_architectures
  description            = each.value.description
  license_info           = each.value.license_info
  skip_destroy           = each.value.skip_destroy

  depends_on = [aws_cloudwatch_log_group.function_logs]
}