# DynamoDB Module Variables

# Basic Configuration
variable "create_table" {
  description = "Controls if DynamoDB table should be created"
  type        = bool
  default     = true
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput and how you manage capacity"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key"
  type        = string
  default     = null
}

variable "table_class" {
  description = "The storage class of the table"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "Table class must be either STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "deletion_protection_enabled" {
  description = "Enables deletion protection for table"
  type        = bool
  default     = false
}

variable "point_in_time_recovery_enabled" {
  description = "Enables point in time recovery for table"
  type        = bool
  default     = true
}

# Capacity Configuration
variable "read_capacity" {
  description = "The number of read units for this table (only applicable when billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "The number of write units for this table (only applicable when billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

# Attributes
variable "attributes" {
  description = "List of nested attribute definitions"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

# Global Secondary Indexes
variable "global_secondary_indexes" {
  description = "Describe a GSI for the table"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

# Local Secondary Indexes
variable "local_secondary_indexes" {
  description = "Describe an LSI on the table"
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
  default = []
}

# DynamoDB Stream
variable "stream_enabled" {
  description = "Indicates whether Streams are to be enabled (true) or disabled (false)"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "When an item in the table is modified, StreamViewType determines what information is written to the table's stream"
  type        = string
  default     = null
  validation {
    condition = var.stream_view_type == null ? true : contains([
      "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"
    ], var.stream_view_type)
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}

# Server Side Encryption
variable "server_side_encryption_enabled" {
  description = "Indicates whether server-side encryption is enabled"
  type        = bool
  default     = true
}

variable "server_side_encryption_kms_key_id" {
  description = "The ARN of the CMK that should be used for the AWS KMS encryption"
  type        = string
  default     = null
}

# TTL
variable "ttl_enabled" {
  description = "Indicates whether ttl is enabled"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "The name of the table attribute to store the TTL timestamp in"
  type        = string
  default     = "ttl"
}

# Global Tables (Replicas)
variable "replica_regions" {
  description = "Region names for creating replica tables"
  type = list(object({
    region_name            = string
    kms_key_arn            = optional(string)
    point_in_time_recovery = optional(bool)
    propagate_tags         = optional(bool)
  }))
  default = []
}

# Import Configuration
variable "import_table" {
  description = "Configuration for importing data from S3"
  type = object({
    bucket_owner = optional(string)
    s3_bucket_source = object({
      bucket       = string
      bucket_owner = optional(string)
      key_prefix   = optional(string)
    })
    input_compression_type = optional(string)
    input_format           = string
    input_format_options   = optional(map(string))
  })
  default = null
}

# Auto Scaling
variable "autoscaling_enabled" {
  description = "Whether or not to enable autoscaling"
  type        = bool
  default     = false
}

variable "autoscaling_read" {
  description = "A map of read autoscaling settings"
  type = object({
    max_capacity       = number
    min_capacity       = number
    target_value       = number
    scale_in_cooldown  = number
    scale_out_cooldown = number
  })
  default = {
    max_capacity       = 100
    min_capacity       = 5
    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

variable "autoscaling_write" {
  description = "A map of write autoscaling settings"
  type = object({
    max_capacity       = number
    min_capacity       = number
    target_value       = number
    scale_in_cooldown  = number
    scale_out_cooldown = number
  })
  default = {
    max_capacity       = 100
    min_capacity       = 5
    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

variable "gsi_autoscaling" {
  description = "A map of GSI autoscaling settings by GSI name"
  type = map(object({
    read = object({
      max_capacity       = number
      min_capacity       = number
      target_value       = number
      scale_in_cooldown  = number
      scale_out_cooldown = number
    })
    write = object({
      max_capacity       = number
      min_capacity       = number
      target_value       = number
      scale_in_cooldown  = number
      scale_out_cooldown = number
    })
  }))
  default = {}
}

# CloudWatch
variable "enable_contributor_insights" {
  description = "Enable CloudWatch Contributor Insights for the table"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for the table"
  type        = bool
  default     = true
}

variable "cloudwatch_alarm_actions" {
  description = "List of actions to take when alarms are triggered"
  type        = list(string)
  default     = []
}

variable "read_throttled_requests_threshold" {
  description = "Threshold for read throttled requests alarm"
  type        = number
  default     = 0
}

variable "write_throttled_requests_threshold" {
  description = "Threshold for write throttled requests alarm"
  type        = number
  default     = 0
}

variable "consumed_read_capacity_threshold" {
  description = "Threshold for consumed read capacity alarm (only for provisioned mode)"
  type        = number
  default     = 80
}

variable "consumed_write_capacity_threshold" {
  description = "Threshold for consumed write capacity alarm (only for provisioned mode)"
  type        = number
  default     = 80
}

# Kinesis Data Firehose Integration
variable "enable_kinesis_firehose" {
  description = "Enable Kinesis Data Firehose for DynamoDB Streams"
  type        = bool
  default     = false
}

variable "kinesis_firehose_role_arn" {
  description = "IAM role ARN for Kinesis Data Firehose"
  type        = string
  default     = null
}

variable "kinesis_firehose_s3_bucket_arn" {
  description = "S3 bucket ARN for Kinesis Data Firehose destination"
  type        = string
  default     = null
}

variable "kinesis_firehose_lambda_arn" {
  description = "Lambda function ARN for data transformation"
  type        = string
  default     = null
}

variable "kinesis_firehose_glue_database" {
  description = "Glue database name for Parquet conversion"
  type        = string
  default     = null
}

variable "kinesis_firehose_glue_table" {
  description = "Glue table name for Parquet conversion"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
