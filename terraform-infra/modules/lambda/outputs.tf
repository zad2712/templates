# Lambda Function Outputs

# Function Information
output "function_name" {
  description = "Name of the Lambda function"
  value       = try(aws_lambda_function.this[0].function_name, "")
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = try(aws_lambda_function.this[0].arn, "")
}

output "arn" {
  description = "ARN of the Lambda function (alias for function_arn)"
  value       = try(aws_lambda_function.this[0].arn, "")
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = try(aws_lambda_function.this[0].invoke_arn, "")
}

output "qualified_arn" {
  description = "Qualified ARN (ARN with version suffix)"
  value       = try(aws_lambda_function.this[0].qualified_arn, "")
}

output "qualified_invoke_arn" {
  description = "Qualified invoke ARN (invoke ARN with version suffix)"
  value       = try(aws_lambda_function.this[0].qualified_invoke_arn, "")
}

# Function Configuration
output "version" {
  description = "Latest published version of Lambda function"
  value       = try(aws_lambda_function.this[0].version, "")
}

output "last_modified" {
  description = "Date this resource was last modified"
  value       = try(aws_lambda_function.this[0].last_modified, "")
}

output "source_code_hash" {
  description = "SHA256 hash of the function's deployment package"
  value       = try(aws_lambda_function.this[0].source_code_hash, "")
}

output "source_code_size" {
  description = "Size in bytes of the function .zip file"
  value       = try(aws_lambda_function.this[0].source_code_size, null)
}

# Runtime Information
output "runtime" {
  description = "Runtime environment for the Lambda function"
  value       = try(aws_lambda_function.this[0].runtime, "")
}

output "handler" {
  description = "Function entry point in your code"
  value       = try(aws_lambda_function.this[0].handler, "")
}

output "timeout" {
  description = "Function timeout"
  value       = try(aws_lambda_function.this[0].timeout, null)
}

output "memory_size" {
  description = "Amount of memory in MB Lambda Function can use at runtime"
  value       = try(aws_lambda_function.this[0].memory_size, null)
}

output "reserved_concurrent_executions" {
  description = "Reserved concurrent executions"
  value       = try(aws_lambda_function.this[0].reserved_concurrent_executions, null)
}

output "architectures" {
  description = "Instruction set architecture for the function"
  value       = try(aws_lambda_function.this[0].architectures, [])
}

output "package_type" {
  description = "Lambda deployment package type"
  value       = try(aws_lambda_function.this[0].package_type, "")
}

# Security Information
output "kms_key_arn" {
  description = "KMS Key ARN used to encrypt Lambda function's environment variables"
  value       = try(aws_lambda_function.this[0].kms_key_arn, "")
}

output "layers" {
  description = "List of Lambda Layer Version ARNs attached to Lambda Function"
  value       = try(aws_lambda_function.this[0].layers, [])
}

# IAM Role Information
output "role_arn" {
  description = "ARN of the IAM role created for Lambda function"
  value       = try(aws_iam_role.lambda_role[0].arn, "")
}

output "role_name" {
  description = "Name of the IAM role created for Lambda function"
  value       = try(aws_iam_role.lambda_role[0].name, "")
}

# Function URL
output "function_url" {
  description = "Function URL for the Lambda function"
  value       = try(aws_lambda_function_url.this[0].function_url, "")
}

output "function_url_creation_time" {
  description = "The time the Function URL was created"
  value       = try(aws_lambda_function_url.this[0].creation_time, "")
}

# Aliases
output "aliases" {
  description = "Map of aliases created"
  value       = { for k, v in aws_lambda_alias.this : k => v.arn }
}

output "alias_invoke_arns" {
  description = "Map of alias invoke ARNs"
  value       = { for k, v in aws_lambda_alias.this : k => v.invoke_arn }
}

# Provisioned Concurrency
output "provisioned_concurrency_configs" {
  description = "Map of provisioned concurrency configurations"
  value       = { for k, v in aws_lambda_provisioned_concurrency_config.this : k => v.allocated_provisioned_concurrent_executions }
}

# Event Source Mappings
output "event_source_mappings" {
  description = "Map of event source mappings created"
  value       = { for k, v in aws_lambda_event_source_mapping.this : k => v.uuid }
}

output "event_source_mapping_function_arns" {
  description = "Map of event source mapping function ARNs"
  value       = { for k, v in aws_lambda_event_source_mapping.this : k => v.function_arn }
}

# Lambda Layers
output "lambda_layers" {
  description = "Map of Lambda layers created"
  value       = { for k, v in aws_lambda_layer_version.this : k => v.arn }
}

output "layer_version_arns" {
  description = "Map of Lambda layer version ARNs"
  value       = { for k, v in aws_lambda_layer_version.this : k => v.arn }
}

# CloudWatch
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.this[0].name, "")
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.this[0].arn, "")
}

output "cloudwatch_alarms" {
  description = "Map of CloudWatch alarms created"
  value = {
    duration              = try(aws_cloudwatch_metric_alarm.duration[0].arn, "")
    errors               = try(aws_cloudwatch_metric_alarm.errors[0].arn, "")
    throttles            = try(aws_cloudwatch_metric_alarm.throttles[0].arn, "")
    concurrent_executions = try(aws_cloudwatch_metric_alarm.concurrent_executions[0].arn, "")
  }
}

# VPC Configuration
output "vpc_config" {
  description = "VPC configuration of the Lambda function"
  value       = try(aws_lambda_function.this[0].vpc_config, {})
}

# Dead Letter Configuration
output "dead_letter_config" {
  description = "Dead letter configuration of the Lambda function"
  value       = try(aws_lambda_function.this[0].dead_letter_config, {})
}

# File System Configuration
output "file_system_config" {
  description = "File system configuration of the Lambda function"
  value       = try(aws_lambda_function.this[0].file_system_config, {})
}

# Tracing Configuration
output "tracing_config" {
  description = "Tracing configuration of the Lambda function"
  value       = try(aws_lambda_function.this[0].tracing_config, {})
}

# Image Configuration
output "image_config" {
  description = "Container image configuration of the Lambda function"
  value       = try(aws_lambda_function.this[0].image_config, {})
}
