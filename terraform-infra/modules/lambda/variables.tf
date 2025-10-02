# Lambda Module Variables

# Basic Configuration
variable "create_function" {
  description = "Controls if Lambda function should be created"
  type        = bool
  default     = true
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Function entrypoint in your code"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.11"
  validation {
    condition = contains([
      "nodejs18.x", "nodejs20.x",
      "python3.8", "python3.9", "python3.10", "python3.11", "python3.12",
      "ruby3.2", "ruby3.3",
      "java8", "java11", "java17", "java21",
      "go1.x",
      "dotnet6", "dotnet8",
      "provided", "provided.al2", "provided.al2023"
    ], var.runtime)
    error_message = "Runtime must be a supported AWS Lambda runtime."
  }
}

variable "architectures" {
  description = "Instruction set architecture for Lambda function"
  type        = list(string)
  default     = ["x86_64"]
  validation {
    condition = alltrue([
      for arch in var.architectures : contains(["x86_64", "arm64"], arch)
    ])
    error_message = "Architectures must be x86_64 or arm64."
  }
}

variable "package_type" {
  description = "Lambda deployment package type"
  type        = string
  default     = "Zip"
  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "Package type must be either Zip or Image."
  }
}

# Function Configuration
variable "timeout" {
  description = "Amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 3
  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 128
  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function"
  type        = number
  default     = null
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Amazon Resource Name (ARN) of the AWS KMS Key"
  type        = string
  default     = null
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach to your Lambda Function"
  type        = list(string)
  default     = []
}

# Code Deployment
variable "filename" {
  description = "Path to the function's deployment package within the local filesystem"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket location containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of an object containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Object version containing the function's deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI containing the function's deployment package"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Virtual attribute used to trigger updates"
  type        = string
  default     = null
}

# Environment Configuration
variable "environment_variables" {
  description = "Map of environment variables"
  type        = map(string)
  default     = {}
}

# VPC Configuration
variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# Dead Letter Configuration
variable "dead_letter_config" {
  description = "Dead letter queue configuration"
  type = object({
    target_arn = string
  })
  default = null
}

# File System Configuration (EFS)
variable "file_system_config" {
  description = "Connection settings for an EFS file system"
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null
}

# Image Configuration (for container images)
variable "image_config" {
  description = "Configuration for the Lambda function's container image"
  type = object({
    entry_point       = optional(list(string))
    command          = optional(list(string))
    working_directory = optional(string)
  })
  default = null
}

# Tracing Configuration
variable "tracing_config" {
  description = "Tracing configuration for the Lambda function"
  type = object({
    mode = string
  })
  default = null
  validation {
    condition = var.tracing_config == null ? true : contains([
      "Active", "PassThrough"
    ], var.tracing_config.mode)
    error_message = "Tracing mode must be Active or PassThrough."
  }
}

# Ephemeral Storage
variable "ephemeral_storage" {
  description = "Configuration for the Lambda function's ephemeral storage"
  type = object({
    size = number
  })
  default = null
  validation {
    condition = var.ephemeral_storage == null ? true : (
      var.ephemeral_storage.size >= 512 && var.ephemeral_storage.size <= 10240
    )
    error_message = "Ephemeral storage size must be between 512 and 10240 MB."
  }
}

# Snap Start (for Java)
variable "snap_start" {
  description = "Snap start settings for low-latency startups"
  type = object({
    apply_on = string
  })
  default = null
  validation {
    condition = var.snap_start == null ? true : contains([
      "PublishedVersions", "None"
    ], var.snap_start.apply_on)
    error_message = "Snap start apply_on must be PublishedVersions or None."
  }
}

# Logging Configuration
variable "logging_config" {
  description = "Advanced logging controls"
  type = object({
    log_format            = optional(string)
    application_log_level = optional(string)
    system_log_level     = optional(string)
    log_group            = optional(string)
  })
  default = null
}

# IAM Configuration
variable "create_role" {
  description = "Controls whether IAM role should be created"
  type        = bool
  default     = true
}

variable "lambda_role" {
  description = "IAM role attached to the Lambda Function (if create_role is false)"
  type        = string
  default     = ""
}

variable "policy_statements" {
  description = "Map of IAM policy statements to attach to Lambda role"
  type        = map(any)
  default     = {}
}

variable "attach_policy_arns" {
  description = "List of IAM policy ARNs to attach to Lambda role"
  type        = list(string)
  default     = []
}

# Function URL Configuration
variable "create_function_url" {
  description = "Whether to create a Lambda Function URL"
  type        = bool
  default     = false
}

variable "function_url_config" {
  description = "Lambda Function URL configuration"
  type = object({
    authorization_type = string
    invoke_mode       = optional(string, "BUFFERED")
    qualifier         = optional(string)
    cors = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_origins     = optional(list(string))
      expose_headers    = optional(list(string))
      max_age          = optional(number)
    }))
  })
  default = {
    authorization_type = "AWS_IAM"
  }
}

# Aliases
variable "aliases" {
  description = "Map of aliases to create"
  type = map(object({
    description      = optional(string)
    function_version = optional(string, "$LATEST")
    routing_config = optional(object({
      additional_version_weights = map(number)
    }))
  }))
  default = {}
}

# Provisioned Concurrency
variable "provisioned_concurrency_config" {
  description = "Map of provisioned concurrency configs"
  type = map(object({
    provisioned_concurrent_executions = number
    qualifier                        = string
  }))
  default = {}
}

# Event Source Mappings
variable "event_source_mappings" {
  description = "Map of event source mapping configurations"
  type = map(object({
    event_source_arn                   = string
    starting_position                  = optional(string)
    starting_position_timestamp        = optional(string)
    batch_size                        = optional(number)
    maximum_batching_window_in_seconds = optional(number)
    enabled                           = optional(bool, true)
    parallelization_factor            = optional(number)
    maximum_record_age_in_seconds     = optional(number)
    bisect_batch_on_function_error    = optional(bool)
    maximum_retry_attempts            = optional(number)
    tumbling_window_in_seconds        = optional(number)
    topics                           = optional(list(string))
    queues                           = optional(list(string))
    function_response_types          = optional(list(string))
    
    amazon_managed_kafka_event_source_config = optional(object({
      consumer_group_id = optional(string)
    }))
    
    self_managed_kafka_event_source_config = optional(object({
      consumer_group_id = optional(string)
    }))
    
    destination_config = optional(object({
      on_failure = optional(object({
        destination_arn = string
      }))
    }))
    
    source_access_configuration = optional(list(object({
      type = string
      uri  = string
    })))
    
    filter_criteria = optional(object({
      filters = list(object({
        pattern = optional(string)
      }))
    }))
    
    scaling_config = optional(object({
      maximum_concurrency = optional(number)
    }))
    
    document_db_event_source_config = optional(object({
      database_name   = string
      collection_name = optional(string)
      full_document   = optional(string)
    }))
  }))
  default = {}
}

# Lambda Permissions
variable "lambda_permissions" {
  description = "Map of Lambda permissions"
  type = map(object({
    principal             = string
    source_arn           = optional(string)
    source_account       = optional(string)
    qualifier            = optional(string)
    event_source_token   = optional(string)
    principal_org_id     = optional(string)
    function_url_auth_type = optional(string)
  }))
  default = {}
}

# Lambda Layers
variable "lambda_layers" {
  description = "Map of Lambda layer configurations"
  type = map(object({
    filename                = optional(string)
    s3_bucket              = optional(string)
    s3_key                 = optional(string)
    s3_object_version      = optional(string)
    source_code_hash       = optional(string)
    compatible_runtimes    = optional(list(string))
    compatible_architectures = optional(list(string))
    description            = optional(string)
    license_info          = optional(string)
    skip_destroy          = optional(bool, false)
  }))
  default = {}
}

# CloudWatch Configuration
variable "create_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Specifies the number of days you want to retain log events"
  type        = number
  default     = 14
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_logs_retention_in_days)
    error_message = "Retention period must be a valid CloudWatch Logs retention value."
  }
}

variable "cloudwatch_logs_kms_key_id" {
  description = "KMS Key ID to use for CloudWatch logs encryption"
  type        = string
  default     = null
}

variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms"
  type        = bool
  default     = false
}

variable "cloudwatch_alarms_config" {
  description = "CloudWatch alarms configuration"
  type = object({
    duration = optional(object({
      evaluation_periods = optional(number, 2)
      period            = optional(number, 60)
      statistic         = optional(string, "Average")
      threshold         = optional(number, 10000)
    }), {})
    errors = optional(object({
      evaluation_periods = optional(number, 2)
      period            = optional(number, 60)
      statistic         = optional(string, "Sum")
      threshold         = optional(number, 1)
    }), {})
    throttles = optional(object({
      evaluation_periods = optional(number, 2)
      period            = optional(number, 60)
      statistic         = optional(string, "Sum")
      threshold         = optional(number, 1)
    }), {})
    concurrent_executions = optional(object({
      evaluation_periods = optional(number, 2)
      period            = optional(number, 60)
      statistic         = optional(string, "Maximum")
      threshold         = optional(number, 100)
    }), {})
  })
  default = {}
}

variable "cloudwatch_alarm_actions" {
  description = "List of actions to take when CloudWatch alarms are triggered"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
