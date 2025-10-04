# =============================================================================
# AWS Lambda Module Outputs
# =============================================================================
# This file defines all the outputs from the Lambda module to expose
# important resource information for use in other modules or root configurations
# =============================================================================

# =============================================================================
# Lambda Function Outputs
# =============================================================================

output "lambda_functions" {
  description = "Map of all Lambda functions with their detailed information"
  value = {
    for name, function in aws_lambda_function.functions : name => {
      function_name        = function.function_name
      function_arn        = function.arn
      qualified_arn       = function.qualified_arn
      qualified_invoke_arn = function.qualified_invoke_arn
      invoke_arn          = function.invoke_arn
      version             = function.version
      last_modified       = function.last_modified
      source_code_hash    = function.source_code_hash
      source_code_size    = function.source_code_size
      runtime             = function.runtime
      handler             = function.handler
      timeout             = function.timeout
      memory_size         = function.memory_size
      reserved_concurrent_executions = function.reserved_concurrent_executions
      package_type        = function.package_type
      architectures       = function.architectures
      code_sha256         = function.code_sha256
      kms_key_arn         = function.kms_key_arn
      signing_job_arn     = function.signing_job_arn
      signing_profile_version_arn = function.signing_profile_version_arn
      tracing_config      = function.tracing_config
      vpc_config          = function.vpc_config
      dead_letter_config  = function.dead_letter_config
      environment         = function.environment
      ephemeral_storage   = function.ephemeral_storage
      file_system_config  = function.file_system_config
      image_config        = function.image_config
      logging_config      = function.logging_config
      snap_start          = function.snap_start
      role_arn           = function.role
      layers             = function.layers
    }
  }
}

output "function_arns" {
  description = "Map of function names to their ARNs"
  value = {
    for name, function in aws_lambda_function.functions : name => function.arn
  }
}

output "function_names" {
  description = "Map of logical names to actual function names"
  value = {
    for name, function in aws_lambda_function.functions : name => function.function_name
  }
}

output "function_invoke_arns" {
  description = "Map of function names to their invoke ARNs (for API Gateway integration)"
  value = {
    for name, function in aws_lambda_function.functions : name => function.invoke_arn
  }
}

output "function_qualified_arns" {
  description = "Map of function names to their qualified ARNs (with version)"
  value = {
    for name, function in aws_lambda_function.functions : name => function.qualified_arn
  }
}

output "function_versions" {
  description = "Map of function names to their current versions"
  value = {
    for name, function in aws_lambda_function.functions : name => function.version
  }
}

# =============================================================================
# IAM Role Outputs
# =============================================================================

output "execution_roles" {
  description = "Map of Lambda execution roles with their details"
  value = {
    for name, role in aws_iam_role.lambda_execution_role : name => {
      role_name = role.name
      role_arn  = role.arn
      role_id   = role.id
      unique_id = role.unique_id
    }
  }
}

output "execution_role_arns" {
  description = "Map of function names to their execution role ARNs"
  value = {
    for name, role in aws_iam_role.lambda_execution_role : name => role.arn
  }
}

output "execution_role_names" {
  description = "Map of function names to their execution role names"
  value = {
    for name, role in aws_iam_role.lambda_execution_role : name => role.name
  }
}

# =============================================================================
# CloudWatch Log Group Outputs
# =============================================================================

output "log_groups" {
  description = "Map of CloudWatch log groups for Lambda functions"
  value = {
    for name, log_group in aws_cloudwatch_log_group.function_logs : name => {
      log_group_name = log_group.name
      log_group_arn  = log_group.arn
      retention_in_days = log_group.retention_in_days
      kms_key_id = log_group.kms_key_id
    }
  }
}

output "log_group_names" {
  description = "Map of function names to their CloudWatch log group names"
  value = {
    for name, log_group in aws_cloudwatch_log_group.function_logs : name => log_group.name
  }
}

output "log_group_arns" {
  description = "Map of function names to their CloudWatch log group ARNs"
  value = {
    for name, log_group in aws_cloudwatch_log_group.function_logs : name => log_group.arn
  }
}

# =============================================================================
# Function URL Outputs
# =============================================================================

output "function_urls" {
  description = "Map of Lambda function URLs with their details"
  value = {
    for name, url in aws_lambda_function_url.function_urls : name => {
      function_url = url.function_url
      url_id       = url.url_id
      creation_time = url.creation_time
      authorization_type = url.authorization_type
      cors = url.cors
    }
  }
}

output "function_url_endpoints" {
  description = "Map of function names to their HTTP endpoints"
  value = {
    for name, url in aws_lambda_function_url.function_urls : name => url.function_url
  }
}

# =============================================================================
# Event Source Mapping Outputs
# =============================================================================

output "event_source_mappings" {
  description = "Map of event source mappings with their details"
  value = {
    for mapping_key, mapping in aws_lambda_event_source_mapping.event_source_mappings : mapping_key => {
      uuid = mapping.uuid
      event_source_arn = mapping.event_source_arn
      function_name = mapping.function_name
      batch_size = mapping.batch_size
      maximum_batching_window_in_seconds = mapping.maximum_batching_window_in_seconds
      starting_position = mapping.starting_position
      starting_position_timestamp = mapping.starting_position_timestamp
      parallelization_factor = mapping.parallelization_factor
      maximum_record_age_in_seconds = mapping.maximum_record_age_in_seconds
      bisect_batch_on_function_error = mapping.bisect_batch_on_function_error
      maximum_retry_attempts = mapping.maximum_retry_attempts
      tumbling_window_in_seconds = mapping.tumbling_window_in_seconds
      state = mapping.state
      state_transition_reason = mapping.state_transition_reason
      last_modified = mapping.last_modified
      last_processing_result = mapping.last_processing_result
    }
  }
}

# =============================================================================
# Lambda Layer Outputs
# =============================================================================

output "lambda_layers" {
  description = "Map of Lambda layers with their details"
  value = {
    for name, layer in aws_lambda_layer_version.layers : name => {
      layer_name = layer.layer_name
      layer_arn = layer.arn
      version = layer.version
      created_date = layer.created_date
      source_code_hash = layer.source_code_hash
      source_code_size = layer.source_code_size
      compatible_runtimes = layer.compatible_runtimes
      compatible_architectures = layer.compatible_architectures
      description = layer.description
      license_info = layer.license_info
      signing_job_arn = layer.signing_job_arn
      signing_profile_version_arn = layer.signing_profile_version_arn
    }
  }
}

output "layer_arns" {
  description = "Map of layer names to their ARNs"
  value = {
    for name, layer in aws_lambda_layer_version.layers : name => layer.arn
  }
}

output "layer_versions" {
  description = "Map of layer names to their versions"
  value = {
    for name, layer in aws_lambda_layer_version.layers : name => layer.version
  }
}

# =============================================================================
# Provisioned Concurrency Outputs
# =============================================================================

output "provisioned_concurrency_configs" {
  description = "Map of provisioned concurrency configurations"
  value = {
    for name, config in aws_lambda_provisioned_concurrency_config.provisioned_concurrency : name => {
      function_name = config.function_name
      provisioned_concurrent_executions = config.provisioned_concurrent_executions
      qualifier = config.qualifier
      allocated_provisioned_concurrent_executions = config.allocated_provisioned_concurrent_executions
      available_provisioned_concurrent_executions = config.available_provisioned_concurrent_executions
      status = config.status
      status_reason = config.status_reason
      last_modified = config.last_modified
    }
  }
}

# =============================================================================
# Lambda Aliases Outputs
# =============================================================================

output "function_aliases" {
  description = "Map of Lambda function aliases with their details"
  value = {
    for name, alias in aws_lambda_alias.function_aliases : name => {
      name = alias.name
      arn = alias.arn
      function_name = alias.function_name
      function_version = alias.function_version
      description = alias.description
      routing_config = alias.routing_config
      invoke_arn = alias.invoke_arn
    }
  }
}

# =============================================================================
# Security and Access Outputs
# =============================================================================

output "security_summary" {
  description = "Security configuration summary for Lambda functions"
  value = {
    functions_with_vpc = [
      for name, function in aws_lambda_function.functions : name
      if length(function.vpc_config) > 0 && function.vpc_config[0].subnet_ids != null
    ]
    functions_with_kms = [
      for name, function in aws_lambda_function.functions : name
      if function.kms_key_arn != null && function.kms_key_arn != ""
    ]
    functions_with_tracing = [
      for name, function in aws_lambda_function.functions : name
      if length(function.tracing_config) > 0 && function.tracing_config[0].mode == "Active"
    ]
    functions_with_dlq = [
      for name, function in aws_lambda_function.functions : name
      if length(function.dead_letter_config) > 0 && function.dead_letter_config[0].target_arn != null
    ]
    functions_with_reserved_concurrency = [
      for name, function in aws_lambda_function.functions : name
      if function.reserved_concurrent_executions != null
    ]
    functions_with_code_signing = [
      for name, function in aws_lambda_function.functions : name
      if function.signing_job_arn != null && function.signing_job_arn != ""
    ]
  }
}

# =============================================================================
# Performance and Monitoring Outputs
# =============================================================================

output "performance_summary" {
  description = "Performance configuration summary for Lambda functions"
  value = {
    total_functions = length(aws_lambda_function.functions)
    memory_distribution = {
      for name, function in aws_lambda_function.functions : function.memory_size => length([
        for f in values(aws_lambda_function.functions) : f.function_name
        if f.memory_size == function.memory_size
      ])...
    }
    timeout_distribution = {
      for name, function in aws_lambda_function.functions : function.timeout => length([
        for f in values(aws_lambda_function.functions) : f.function_name
        if f.timeout == function.timeout
      ])...
    }
    runtime_distribution = {
      for name, function in aws_lambda_function.functions : function.runtime => length([
        for f in values(aws_lambda_function.functions) : f.function_name
        if f.runtime == function.runtime
      ])...
    }
    architecture_distribution = {
      for name, function in aws_lambda_function.functions : join(",", function.architectures) => length([
        for f in values(aws_lambda_function.functions) : f.function_name
        if join(",", f.architectures) == join(",", function.architectures)
      ])...
    }
    functions_with_layers = [
      for name, function in aws_lambda_function.functions : name
      if length(function.layers) > 0
    ]
    functions_with_provisioned_concurrency = [
      for name, config in aws_lambda_provisioned_concurrency_config.provisioned_concurrency : name
    ]
    functions_with_function_urls = [
      for name, url in aws_lambda_function_url.function_urls : name
    ]
    functions_with_event_source_mappings = distinct([
      for mapping_key, mapping in aws_lambda_event_source_mapping.event_source_mappings : 
      split("-", mapping_key)[0]
    ])
  }
}

# =============================================================================
# Cost Optimization Outputs
# =============================================================================

output "cost_optimization_summary" {
  description = "Cost optimization information for Lambda functions"
  value = {
    functions_by_memory_tier = {
      small = [
        for name, function in aws_lambda_function.functions : name
        if function.memory_size <= 512
      ]
      medium = [
        for name, function in aws_lambda_function.functions : name
        if function.memory_size > 512 && function.memory_size <= 1024
      ]
      large = [
        for name, function in aws_lambda_function.functions : name
        if function.memory_size > 1024 && function.memory_size <= 3008
      ]
      xlarge = [
        for name, function in aws_lambda_function.functions : name
        if function.memory_size > 3008
      ]
    }
    arm64_functions = [
      for name, function in aws_lambda_function.functions : name
      if contains(function.architectures, "arm64")
    ]
    functions_with_ephemeral_storage = [
      for name, function in aws_lambda_function.functions : name
      if length(function.ephemeral_storage) > 0 && function.ephemeral_storage[0].size > 512
    ]
    estimated_monthly_invocations_supported = {
      for name, function in aws_lambda_function.functions : name => {
        max_concurrent = function.reserved_concurrent_executions != null ? function.reserved_concurrent_executions : 1000
        invocations_per_second = max_concurrent / function.timeout
        monthly_invocations = invocations_per_second * 60 * 60 * 24 * 30
      }
    }
  }
}

# =============================================================================
# Integration Outputs
# =============================================================================

output "integration_endpoints" {
  description = "Integration endpoints for external services"
  value = {
    api_gateway_integrations = {
      for name, function in aws_lambda_function.functions : name => {
        invoke_arn = function.invoke_arn
        function_name = function.function_name
      }
    }
    eventbridge_targets = {
      for name, function in aws_lambda_function.functions : name => {
        arn = function.arn
        function_name = function.function_name
      }
    }
    cloudwatch_alarms = {
      for name, function in aws_lambda_function.functions : name => {
        function_name = function.function_name
        log_group_name = aws_cloudwatch_log_group.function_logs[name].name
      }
    }
  }
}

# =============================================================================
# Comprehensive Function Details
# =============================================================================

output "function_details" {
  description = "Comprehensive details for all Lambda functions"
  value = {
    for name, function in aws_lambda_function.functions : name => {
      # Basic information
      function_name = function.function_name
      function_arn = function.arn
      invoke_arn = function.invoke_arn
      
      # Configuration
      runtime = function.runtime
      handler = function.handler
      memory_size = function.memory_size
      timeout = function.timeout
      package_type = function.package_type
      architectures = function.architectures
      
      # Security
      execution_role_arn = aws_iam_role.lambda_execution_role[name].arn
      kms_key_arn = function.kms_key_arn
      vpc_configured = length(function.vpc_config) > 0 && function.vpc_config[0].subnet_ids != null
      tracing_enabled = length(function.tracing_config) > 0 && function.tracing_config[0].mode == "Active"
      
      # Monitoring
      log_group_name = aws_cloudwatch_log_group.function_logs[name].name
      log_group_arn = aws_cloudwatch_log_group.function_logs[name].arn
      
      # URLs and access
      function_url = try(aws_lambda_function_url.function_urls[name].function_url, null)
      
      # Performance
      reserved_concurrency = function.reserved_concurrent_executions
      provisioned_concurrency = try(
        aws_lambda_provisioned_concurrency_config.provisioned_concurrency[name].provisioned_concurrent_executions,
        null
      )
      
      # Integration
      has_event_source_mappings = contains([
        for mapping_key in keys(aws_lambda_event_source_mapping.event_source_mappings) :
        split("-", mapping_key)[0]
      ], name)
      
      # Code information
      source_code_hash = function.source_code_hash
      source_code_size = function.source_code_size
      version = function.version
      last_modified = function.last_modified
    }
  }
}