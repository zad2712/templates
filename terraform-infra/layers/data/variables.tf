# =============================================================================
# DATA LAYER VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
  validation {
    condition = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "state_bucket" {
  description = "S3 bucket for storing Terraform state"
  type        = string
}

# =============================================================================
# RDS CONFIGURATION
# =============================================================================

variable "enable_rds" {
  description = "Enable RDS database"
  type        = bool
  default     = false
}

variable "rds_engine" {
  description = "RDS engine (mysql, postgres, etc.)"
  type        = string
  default     = "mysql"
}

variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "8.0"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage in GB for autoscaling"
  type        = number
  default     = 100
}

variable "rds_database_name" {
  description = "RDS database name"
  type        = string
  default     = "app"
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "RDS backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "RDS maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_monitoring_interval" {
  description = "RDS monitoring interval"
  type        = number
  default     = 60
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = false
}

# =============================================================================
# ELASTICACHE CONFIGURATION
# =============================================================================

variable "enable_elasticache" {
  description = "Enable ElastiCache Redis"
  type        = bool
  default     = false
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 1
}

variable "redis_parameter_group" {
  description = "Redis parameter group"
  type        = string
  default     = "default.redis7"
}

variable "redis_snapshot_retention_limit" {
  description = "Redis snapshot retention limit in days"
  type        = number
  default     = 7
}

variable "redis_snapshot_window" {
  description = "Redis snapshot window"
  type        = string
  default     = "03:00-05:00"
}

# =============================================================================
# DYNAMODB CONFIGURATION
# =============================================================================

variable "dynamodb_tables" {
  description = "Map of DynamoDB tables to create"
  type = map(object({
    billing_mode = optional(string, "PAY_PER_REQUEST")
    hash_key     = string
    range_key    = optional(string)
    
    attributes = list(object({
      name = string
      type = string
    }))
    
    global_secondary_indexes = optional(list(object({
      name            = string
      hash_key        = string
      range_key       = optional(string)
      projection_type = string
    })), [])
    
    local_secondary_indexes = optional(list(object({
      name            = string
      range_key       = string
      projection_type = string
    })), [])
    
    ttl = optional(object({
      attribute_name = string
      enabled        = bool
    }))
    
    stream_enabled   = optional(bool, false)
    stream_view_type = optional(string)
  }))
  default = {}
}

# =============================================================================
# S3 CONFIGURATION
# =============================================================================

variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    versioning_enabled = optional(bool, false)
    
    lifecycle_configuration = optional(object({
      rules = list(object({
        id     = string
        status = string
        
        expiration = optional(object({
          days = number
        }))
        
        noncurrent_version_expiration = optional(object({
          days = number
        }))
        
        transition = optional(list(object({
          days          = number
          storage_class = string
        })), [])
      }))
    }))
    
    cors_rule = optional(list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = optional(list(string), [])
      max_age_seconds = optional(number, 3000)
    })), [])
    
    public_read_access  = optional(bool, false)
    public_write_access = optional(bool, false)
  }))
  default = {}
}

# =============================================================================
# TAGGING
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
