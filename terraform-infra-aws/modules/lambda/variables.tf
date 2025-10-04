# =============================================================================
# AWS Lambda Module Variables
# =============================================================================
# This file defines all the variables used in the Lambda module with
# comprehensive validation rules and detailed descriptions
# =============================================================================

# =============================================================================
# General Configuration
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names to ensure uniqueness and organization"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name_prefix))
    error_message = "Name prefix must start with a letter, contain only alphanumeric characters and hyphens, and end with an alphanumeric character."
  }

  validation {
    condition     = length(var.name_prefix) >= 2 && length(var.name_prefix) <= 30
    error_message = "Name prefix must be between 2 and 30 characters long."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources created by this module"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.common_tags : 
      can(regex("^[\\w\\s\\-\\.\\:\\/\\=\\+\\@]+$", tag_key)) &&
      can(regex("^[\\w\\s\\-\\.\\:\\/\\=\\+\\@]*$", tag_value)) &&
      length(tag_key) <= 128 &&
      length(tag_value) <= 256
    ])
    error_message = "Tag keys and values must contain only valid characters and be within AWS limits (key: 128 chars, value: 256 chars)."
  }
}

variable "global_environment_variables" {
  description = "Global environment variables to be added to all Lambda functions"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "default_kms_key_arn" {
  description = "Default KMS key ARN for encrypting environment variables when not specified per function"
  type        = string
  default     = null

  validation {
    condition = var.default_kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.default_kms_key_arn))
    error_message = "Default KMS key ARN must be a valid AWS KMS key ARN."
  }
}

# =============================================================================
# Lambda Functions Configuration
# =============================================================================

variable "lambda_functions" {
  description = "Map of Lambda functions to create with their configurations"
  type = map(object({
    # Basic function configuration
    runtime     = optional(string, "python3.11")
    handler     = optional(string)
    filename    = optional(string)
    s3_bucket   = optional(string)
    s3_key      = optional(string)
    s3_object_version = optional(string)
    source_code_hash = optional(string)
    description = optional(string, "Lambda function managed by Terraform")
    timeout     = optional(number, 30)
    memory_size = optional(number, 128)
    reserved_concurrent_executions = optional(number)
    publish     = optional(bool, false)
    
    # Package configuration
    package_type = optional(string, "Zip")
    image_uri    = optional(string)
    architectures = optional(list(string), ["x86_64"])
    
    # Layer configuration
    layers = optional(list(string), [])
    
    # Environment variables
    environment_variables = optional(map(string))
    kms_key_arn          = optional(string)
    
    # VPC configuration
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
    
    # Dead letter queue configuration
    dead_letter_config = optional(object({
      target_arn = string
    }))
    
    # Tracing configuration
    tracing_mode = optional(string, "PassThrough")
    
    # Image configuration (for container images)
    image_config = optional(object({
      entry_point       = optional(list(string))
      command          = optional(list(string))
      working_directory = optional(string)
    }))
    
    # Ephemeral storage configuration
    ephemeral_storage_size = optional(number)
    
    # File system configuration
    file_system_configs = optional(list(object({
      arn              = string
      local_mount_path = string
    })))
    
    # Logging configuration
    logging_config = optional(object({
      log_format                = optional(string, "Text")
      application_log_level     = optional(string, "INFO")
      system_log_level         = optional(string, "INFO")
      log_group               = optional(string)
    }))
    
    # Snap start configuration
    snap_start_apply_on = optional(string)
    
    # Code signing configuration
    code_signing_config_arn = optional(string)
    
    # Provisioned concurrency configuration
    provisioned_concurrency_config = optional(object({
      provisioned_concurrent_executions = number
      qualifier                        = optional(string, "$LATEST")
    }))
    
    # Function URL configuration
    function_url_config = optional(object({
      authorization_type = string
      cors = optional(object({
        allow_credentials = optional(bool, false)
        allow_headers     = optional(list(string))
        allow_methods     = optional(list(string))
        allow_origins     = optional(list(string))
        expose_headers    = optional(list(string))
        max_age          = optional(number)
      }))
    }))
    
    # Event source mappings
    event_source_mappings = optional(map(object({
      event_source_arn                      = string
      batch_size                            = optional(number)
      maximum_batching_window_in_seconds     = optional(number)
      starting_position                     = optional(string)
      starting_position_timestamp           = optional(string)
      parallelization_factor                = optional(number)
      maximum_record_age_in_seconds         = optional(number)
      bisect_batch_on_function_error        = optional(bool)
      maximum_retry_attempts                = optional(number)
      tumbling_window_in_seconds            = optional(number)
      topics                               = optional(list(string))
      queues                               = optional(list(string))
      source_access_configurations         = optional(list(object({
        type = string
        uri  = string
      })))
      self_managed_event_source = optional(object({
        endpoints = map(string)
      }))
      self_managed_kafka_event_source_config = optional(object({
        consumer_group_id = string
      }))
      amazon_managed_kafka_event_source_config = optional(object({
        consumer_group_id = string
      }))
      document_db_event_source_config = optional(object({
        collection_name = string
        database_name   = string
        full_document   = optional(string)
      }))
      filter_criteria = optional(object({
        filters = list(object({
          pattern = string
        }))
      }))
      function_response_types = optional(list(string))
      scaling_config = optional(object({
        maximum_concurrency = number
      }))
      destination_config = optional(object({
        on_failure = optional(object({
          destination_arn = string
        }))
      }))
    })))
    
    # Lambda permissions
    permissions = optional(map(object({
      statement_id           = string
      action                = string
      principal             = string
      source_arn            = optional(string)
      source_account        = optional(string)
      event_source_token    = optional(string)
      qualifier             = optional(string)
      principal_org_id      = optional(string)
      function_url_auth_type = optional(string)
    })))
    
    # IAM configuration
    custom_iam_policy       = optional(string)
    additional_iam_policies = optional(list(string), [])
    
    # Aliases
    aliases = optional(object({
      name        = string
      description = optional(string)
      routing_config = optional(object({
        additional_version_weights = map(number)
      }))
    }))
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      length(name) >= 1 && length(name) <= 64
    ])
    error_message = "Lambda function names must be between 1 and 64 characters long."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      can(regex("^[a-zA-Z0-9-_]+$", name))
    ])
    error_message = "Lambda function names must contain only alphanumeric characters, hyphens, and underscores."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.package_type == "Image" || config.runtime != null
    ])
    error_message = "Runtime must be specified when package_type is 'Zip'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.package_type == "Image" || config.handler != null
    ])
    error_message = "Handler must be specified when package_type is 'Zip'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.package_type == "Zip" || config.image_uri != null
    ])
    error_message = "Image URI must be specified when package_type is 'Image'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.timeout >= 1 && config.timeout <= 900
    ])
    error_message = "Lambda function timeout must be between 1 and 900 seconds."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.memory_size >= 128 && config.memory_size <= 10240
    ])
    error_message = "Lambda function memory size must be between 128 MB and 10,240 MB."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.memory_size % 64 == 0
    ])
    error_message = "Lambda function memory size must be a multiple of 64 MB."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.reserved_concurrent_executions == null || 
      (config.reserved_concurrent_executions >= 0 && config.reserved_concurrent_executions <= 1000)
    ])
    error_message = "Reserved concurrent executions must be between 0 and 1000."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      contains(["Zip", "Image"], config.package_type)
    ])
    error_message = "Package type must be either 'Zip' or 'Image'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      alltrue([
        for arch in config.architectures : 
        contains(["x86_64", "arm64"], arch)
      ])
    ])
    error_message = "Architectures must be either 'x86_64' or 'arm64'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      contains(["PassThrough", "Active"], config.tracing_mode)
    ])
    error_message = "Tracing mode must be either 'PassThrough' or 'Active'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.ephemeral_storage_size == null || 
      (config.ephemeral_storage_size >= 512 && config.ephemeral_storage_size <= 10240)
    ])
    error_message = "Ephemeral storage size must be between 512 MB and 10,240 MB."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.logging_config == null || 
      contains(["JSON", "Text"], config.logging_config.log_format)
    ])
    error_message = "Log format must be either 'JSON' or 'Text'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.logging_config == null || 
      contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"], config.logging_config.application_log_level)
    ])
    error_message = "Application log level must be one of: TRACE, DEBUG, INFO, WARN, ERROR, FATAL."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.logging_config == null || 
      contains(["DEBUG", "INFO", "WARN"], config.logging_config.system_log_level)
    ])
    error_message = "System log level must be one of: DEBUG, INFO, WARN."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.snap_start_apply_on == null || 
      contains(["PublishedVersions", "None"], config.snap_start_apply_on)
    ])
    error_message = "Snap start apply_on must be either 'PublishedVersions' or 'None'."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.function_url_config == null || 
      contains(["AWS_IAM", "NONE"], config.function_url_config.authorization_type)
    ])
    error_message = "Function URL authorization type must be either 'AWS_IAM' or 'NONE'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for mapping_name, mapping in coalesce(config.event_source_mappings, {}) : 
        mapping.starting_position == null || 
        contains(["TRIM_HORIZON", "LATEST", "AT_TIMESTAMP"], mapping.starting_position)
      ]
    ]))
    error_message = "Event source mapping starting position must be one of: TRIM_HORIZON, LATEST, AT_TIMESTAMP."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for mapping_name, mapping in coalesce(config.event_source_mappings, {}) : 
        mapping.batch_size == null || 
        (mapping.batch_size >= 1 && mapping.batch_size <= 10000)
      ]
    ]))
    error_message = "Event source mapping batch size must be between 1 and 10,000."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for mapping_name, mapping in coalesce(config.event_source_mappings, {}) : 
        mapping.maximum_batching_window_in_seconds == null || 
        (mapping.maximum_batching_window_in_seconds >= 0 && mapping.maximum_batching_window_in_seconds <= 300)
      ]
    ]))
    error_message = "Maximum batching window must be between 0 and 300 seconds."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for mapping_name, mapping in coalesce(config.event_source_mappings, {}) : 
        mapping.parallelization_factor == null || 
        (mapping.parallelization_factor >= 1 && mapping.parallelization_factor <= 10)
      ]
    ]))
    error_message = "Parallelization factor must be between 1 and 10."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for mapping_name, mapping in coalesce(config.event_source_mappings, {}) : 
        mapping.maximum_record_age_in_seconds == null || 
        (mapping.maximum_record_age_in_seconds >= -1 && mapping.maximum_record_age_in_seconds <= 604800)
      ]
    ]))
    error_message = "Maximum record age must be between -1 and 604,800 seconds (7 days)."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for mapping_name, mapping in coalesce(config.event_source_mappings, {}) : 
        mapping.maximum_retry_attempts == null || 
        (mapping.maximum_retry_attempts >= -1 && mapping.maximum_retry_attempts <= 10000)
      ]
    ]))
    error_message = "Maximum retry attempts must be between -1 and 10,000."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for mapping_name, mapping in coalesce(config.event_source_mappings, {}) : 
        mapping.tumbling_window_in_seconds == null || 
        (mapping.tumbling_window_in_seconds >= 0 && mapping.tumbling_window_in_seconds <= 900)
      ]
    ]))
    error_message = "Tumbling window must be between 0 and 900 seconds."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for perm_name, permission in coalesce(config.permissions, {}) : 
        contains([
          "lambda:InvokeFunction", 
          "lambda:GetFunction", 
          "lambda:GetLayerVersion"
        ], permission.action)
      ]
    ]))
    error_message = "Permission action must be a valid Lambda action."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for policy in coalesce(config.additional_iam_policies, []) : 
        can(regex("^arn:aws:iam::(aws|[0-9]{12}):policy/", policy))
      ]
    ]))
    error_message = "Additional IAM policies must be valid AWS managed policy ARNs or customer managed policy ARNs."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.kms_key_arn == null || 
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", config.kms_key_arn))
    ])
    error_message = "KMS key ARN must be a valid AWS KMS key ARN."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.code_signing_config_arn == null || 
      can(regex("^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:code-signing-config:", config.code_signing_config_arn))
    ])
    error_message = "Code signing config ARN must be a valid AWS Lambda code signing config ARN."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_functions : 
      config.provisioned_concurrency_config == null || 
      config.provisioned_concurrency_config.provisioned_concurrent_executions >= 1
    ])
    error_message = "Provisioned concurrent executions must be at least 1."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for fs_config in coalesce(config.file_system_configs, []) : 
        can(regex("^arn:aws:elasticfilesystem:[a-z0-9-]+:[0-9]{12}:access-point/", fs_config.arn))
      ]
    ]))
    error_message = "File system ARN must be a valid EFS access point ARN."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_functions : [
        for fs_config in coalesce(config.file_system_configs, []) : 
        can(regex("^/mnt/[a-zA-Z0-9-_]+$", fs_config.local_mount_path))
      ]
    ]))
    error_message = "File system local mount path must start with /mnt/ and contain only valid characters."
  }
}

# =============================================================================
# Lambda Layers Configuration
# =============================================================================

variable "lambda_layers" {
  description = "Map of Lambda layers to create"
  type = map(object({
    filename                 = optional(string)
    s3_bucket               = optional(string)
    s3_key                  = optional(string)
    s3_object_version       = optional(string)
    source_code_hash        = optional(string)
    compatible_runtimes     = list(string)
    compatible_architectures = optional(list(string), ["x86_64"])
    description             = optional(string)
    license_info           = optional(string)
    skip_destroy           = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.lambda_layers : 
      length(name) >= 1 && length(name) <= 140
    ])
    error_message = "Layer names must be between 1 and 140 characters long."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_layers : 
      can(regex("^[a-zA-Z0-9-_]+$", name))
    ])
    error_message = "Layer names must contain only alphanumeric characters, hyphens, and underscores."
  }

  validation {
    condition = alltrue([
      for name, config in var.lambda_layers : 
      length(config.compatible_runtimes) > 0
    ])
    error_message = "At least one compatible runtime must be specified for each layer."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.lambda_layers : [
        for arch in config.compatible_architectures : 
        contains(["x86_64", "arm64"], arch)
      ]
    ]))
    error_message = "Compatible architectures must be either 'x86_64' or 'arm64'."
  }
}

# =============================================================================
# CloudWatch Configuration
# =============================================================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs for Lambda functions"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 
      731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be one of the valid CloudWatch log retention values."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = null

  validation {
    condition = var.log_kms_key_id == null || can(regex("^(arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+|[a-f0-9-]+)$", var.log_kms_key_id))
    error_message = "Log KMS key ID must be a valid KMS key ID or ARN."
  }
}