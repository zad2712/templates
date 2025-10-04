# DynamoDB Module Variables
variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  
  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "Name prefix must be between 1 and 32 characters."
  }
}

variable "tables" {
  description = "Configuration for DynamoDB tables"
  type = map(object({
    # Table basic configuration
    hash_key    = string
    range_key   = optional(string)
    attributes  = list(object({
      name = string
      type = string  # S, N, B
    }))
    
    # Billing and capacity
    billing_mode   = optional(string, "PAY_PER_REQUEST")  # PAY_PER_REQUEST or PROVISIONED
    read_capacity  = optional(number, 5)   # Only for PROVISIONED mode
    write_capacity = optional(number, 5)   # Only for PROVISIONED mode
    
    # Table class and performance
    table_class = optional(string, "STANDARD")  # STANDARD or STANDARD_INFREQUENT_ACCESS
    
    # Auto scaling configuration (only for PROVISIONED mode)
    autoscaling = optional(object({
      read_capacity = optional(object({
        min                = optional(number, 5)
        max                = optional(number, 100)
        target_utilization = optional(number, 70.0)
        scale_in_cooldown  = optional(number, 60)
        scale_out_cooldown = optional(number, 60)
      }))
      write_capacity = optional(object({
        min                = optional(number, 5)
        max                = optional(number, 100)
        target_utilization = optional(number, 70.0)
        scale_in_cooldown  = optional(number, 60)
        scale_out_cooldown = optional(number, 60)
      }))
    }))
    
    # Global Secondary Indexes
    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      range_key          = optional(string)
      projection_type    = string  # ALL, KEYS_ONLY, INCLUDE
      non_key_attributes = optional(list(string))
      read_capacity      = optional(number, 5)   # Only for PROVISIONED mode
      write_capacity     = optional(number, 5)   # Only for PROVISIONED mode
    })), [])
    
    # Local Secondary Indexes
    local_secondary_indexes = optional(list(object({
      name               = string
      range_key          = string
      projection_type    = string  # ALL, KEYS_ONLY, INCLUDE
      non_key_attributes = optional(list(string))
    })), [])
    
    # Stream configuration
    stream_enabled   = optional(bool, false)
    stream_view_type = optional(string, "NEW_AND_OLD_IMAGES")  # KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES
    
    # TTL configuration
    ttl = optional(object({
      attribute_name = string
      enabled        = optional(bool, true)
    }))
    
    # Backup and recovery
    point_in_time_recovery_enabled = optional(bool, true)
    deletion_protection_enabled    = optional(bool, true)
    
    # Encryption
    server_side_encryption = optional(object({
      enabled    = optional(bool, true)
      kms_key_id = optional(string)
    }), {
      enabled = true
      kms_key_id = null
    })
    
    # Import configuration for existing data
    import_table = optional(object({
      bucket_name    = string
      bucket_key_prefix = optional(string)
      compression_type  = optional(string)  # GZIP, ZSTD, NONE
      input_format_options = optional(object({
        csv = optional(object({
          delimiter   = optional(string, ",")
          header_list = optional(list(string))
        }))
      }))
    }))
    
    # Backup configuration
    backup = optional(object({
      continuous_backups_enabled     = optional(bool, true)
      point_in_time_recovery_enabled = optional(bool, true)
    }), {
      continuous_backups_enabled = true
      point_in_time_recovery_enabled = true
    })
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for table_key, table in var.tables : contains(["PAY_PER_REQUEST", "PROVISIONED"], table.billing_mode)
    ])
    error_message = "Billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
  
  validation {
    condition = alltrue([
      for table_key, table in var.tables : contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], table.table_class)
    ])
    error_message = "Table class must be either STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
  
  validation {
    condition = alltrue([
      for table_key, table in var.tables : table.stream_enabled == false || contains([
        "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"
      ], table.stream_view_type)
    ])
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
  
  validation {
    condition = alltrue([
      for table_key, table in var.tables : alltrue([
        for attr in table.attributes : contains(["S", "N", "B"], attr.type)
      ])
    ])
    error_message = "Attribute type must be S (String), N (Number), or B (Binary)."
  }
  
  validation {
    condition = alltrue([
      for table_key, table in var.tables : alltrue([
        for gsi in table.global_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], gsi.projection_type)
      ])
    ])
    error_message = "GSI projection type must be ALL, KEYS_ONLY, or INCLUDE."
  }
  
  validation {
    condition = alltrue([
      for table_key, table in var.tables : alltrue([
        for lsi in table.local_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], lsi.projection_type)
      ])
    ])
    error_message = "LSI projection type must be ALL, KEYS_ONLY, or INCLUDE."
  }
}

variable "global_tables" {
  description = "Configuration for DynamoDB Global Tables"
  type = map(object({
    # Table basic configuration
    hash_key   = string
    range_key  = optional(string)
    attributes = list(object({
      name = string
      type = string  # S, N, B
    }))
    
    # Global Secondary Indexes
    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      range_key          = optional(string)
      projection_type    = string  # ALL, KEYS_ONLY, INCLUDE
      non_key_attributes = optional(list(string))
    })), [])
    
    # TTL configuration
    ttl = optional(object({
      attribute_name = string
      enabled        = optional(bool, true)
    }))
    
    # Encryption key (can be different per replica)
    kms_key_id = optional(string)
    
    # Replicas configuration
    replicas = list(object({
      region_name = string
      
      # Per-replica configuration
      point_in_time_recovery_enabled = optional(bool, true)
      table_class                   = optional(string, "STANDARD")
      kms_key_id                    = optional(string)
      
      # Per-replica GSI configuration
      global_secondary_indexes = optional(list(object({
        name               = string
        projection_type    = string
        non_key_attributes = optional(list(string))
      })), [])
      
      # Per-replica tags
      tags = optional(map(string), {})
    }))
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for gt_key, gt in var.global_tables : length(gt.replicas) >= 1 && length(gt.replicas) <= 10
    ])
    error_message = "Global tables must have between 1 and 10 replicas."
  }
  
  validation {
    condition = alltrue([
      for gt_key, gt in var.global_tables : alltrue([
        for replica in gt.replicas : contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], replica.table_class)
      ])
    ])
    error_message = "Replica table class must be either STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
  
  validation {
    condition = alltrue([
      for gt_key, gt in var.global_tables : alltrue([
        for attr in gt.attributes : contains(["S", "N", "B"], attr.type)
      ])
    ])
    error_message = "Attribute type must be S (String), N (Number), or B (Binary)."
  }
}

variable "enable_backup_vault" {
  description = "Enable AWS Backup vault for DynamoDB tables"
  type        = bool
  default     = false
}

variable "backup_vault_kms_key_arn" {
  description = "KMS key ARN for backup vault encryption"
  type        = string
  default     = null
}

variable "backup_plan_rules" {
  description = "Backup plan rules for DynamoDB tables"
  type = list(object({
    rule_name                = string
    schedule                 = string  # Cron expression
    start_window            = optional(number, 60)     # Minutes
    completion_window       = optional(number, 120)    # Minutes
    enable_continuous_backup = optional(bool, false)
    
    lifecycle = optional(object({
      cold_storage_after = optional(number)  # Days
      delete_after      = optional(number)   # Days
    }))
    
    recovery_point_tags = optional(map(string), {})
  }))
  default = []
  
  validation {
    condition = alltrue([
      for rule in var.backup_plan_rules : can(regex("^cron\\(.*\\)$|^rate\\(.*\\)$", rule.schedule))
    ])
    error_message = "Schedule must be a valid cron expression or rate expression."
  }
}

variable "backup_selection_conditions" {
  description = "Conditions for backup selection"
  type = list(object({
    string_equals     = optional(map(string), {})
    string_like       = optional(map(string), {})
    string_not_equals = optional(map(string), {})
    string_not_like   = optional(map(string), {})
  }))
  default = []
}

variable "stream_processor_functions" {
  description = "Lambda functions to process DynamoDB streams"
  type = map(object({
    table_key                          = string
    lambda_function_name               = string
    starting_position                  = optional(string, "LATEST")  # LATEST, TRIM_HORIZON, AT_TIMESTAMP
    batch_size                        = optional(number, 10)
    maximum_batching_window_in_seconds = optional(number)
    parallelization_factor            = optional(number)
    maximum_record_age_in_seconds     = optional(number)
    bisect_batch_on_function_error    = optional(bool, false)
    maximum_retry_attempts            = optional(number)
    tumbling_window_in_seconds        = optional(number)
    
    destination_config = optional(object({
      on_failure = optional(object({
        destination_arn = string
      }))
    }))
    
    filter_criteria = optional(object({
      filters = list(object({
        pattern = string
      }))
    }))
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for func_key, func in var.stream_processor_functions : contains(["LATEST", "TRIM_HORIZON", "AT_TIMESTAMP"], func.starting_position)
    ])
    error_message = "Starting position must be LATEST, TRIM_HORIZON, or AT_TIMESTAMP."
  }
  
  validation {
    condition = alltrue([
      for func_key, func in var.stream_processor_functions : func.batch_size >= 1 && func.batch_size <= 1000
    ])
    error_message = "Batch size must be between 1 and 1000."
  }
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for DynamoDB monitoring"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of actions to execute when alarm transitions into an ALARM state"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of actions to execute when alarm transitions into an OK state"
  type        = list(string)
  default     = []
}

variable "enable_contributor_insights" {
  description = "Enable DynamoDB Contributor Insights for tables"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for key, value in var.common_tags : can(regex("^[\\w\\s\\-_:./=+@]*$", key)) && can(regex("^[\\w\\s\\-_:./=+@]*$", value))
    ])
    error_message = "Tag keys and values can only contain letters, numbers, spaces, and the following characters: - _ : . / = + @"
  }
  
  validation {
    condition = length(var.common_tags) <= 50
    error_message = "Maximum of 50 tags allowed."
  }
}