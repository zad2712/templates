# Security Layer Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# KMS Configuration
variable "kms_deletion_window" {
  description = "Number of days to wait before deleting KMS keys"
  type        = number
  default     = 7
  
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

# IAM Configuration
variable "iam_groups" {
  description = "IAM groups configuration"
  type = map(object({
    description = optional(string)
    path        = optional(string, "/")
    
    group_policy_arns = optional(list(string), [])
    
    inline_policies = optional(map(object({
      version = optional(string, "2012-10-17")
      statements = list(object({
        sid       = optional(string)
        effect    = string
        actions   = list(string)
        resources = list(string)
        
        principals = optional(object({
          type        = string
          identifiers = list(string)
        }))
        
        condition = optional(object({
          test     = string
          variable = string
          values   = list(string)
        }))
      }))
    })), {})
    
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "iam_users" {
  description = "IAM users configuration"
  type = map(object({
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
    force_destroy       = optional(bool, false)
    
    groups = optional(list(string), [])
    
    policy_arns = optional(list(string), [])
    
    inline_policies = optional(map(object({
      version = optional(string, "2012-10-17")
      statements = list(object({
        sid       = optional(string)
        effect    = string
        actions   = list(string)
        resources = list(string)
        
        condition = optional(object({
          test     = string
          variable = string
          values   = list(string)
        }))
      }))
    })), {})
    
    access_keys = optional(list(object({
      status = optional(string, "Active")
      pgp_key = optional(string)
    })), [])
    
    login_profile = optional(object({
      password_length         = optional(number, 20)
      password_reset_required = optional(bool, true)
      pgp_key                = optional(string)
    }))
    
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "custom_iam_policies" {
  description = "Custom IAM policies"
  type = map(object({
    description = optional(string)
    path        = optional(string, "/")
    
    policy = object({
      version = optional(string, "2012-10-17")
      statements = list(object({
        sid       = optional(string)
        effect    = string
        actions   = list(string)
        resources = list(string)
        
        principals = optional(object({
          type        = string
          identifiers = list(string)
        }))
        
        condition = optional(object({
          test     = string
          variable = string
          values   = list(string)
        }))
      }))
    })
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Secrets Manager Configuration
variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = true
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup for secrets"
  type        = bool
  default     = false
}

variable "backup_region" {
  description = "Backup region for cross-region replication"
  type        = string
  default     = "us-west-2"
}

# WAF Configuration
variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

# CloudWatch Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch log retention period."
  }
}

# Security Group Configuration (if not using networking layer)
variable "create_security_groups" {
  description = "Create security groups in this layer (if not created in networking layer)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for security groups (required if create_security_groups is true)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
  default     = "10.0.0.0/16"
}

# Notification Configuration
variable "notification_endpoints" {
  description = "SNS notification endpoints"
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default = []
  
  validation {
    condition = alltrue([
      for endpoint in var.notification_endpoints :
      contains(["email", "email-json", "sms", "sqs", "lambda", "https", "http"], endpoint.protocol)
    ])
    error_message = "Notification protocol must be one of: email, email-json, sms, sqs, lambda, https, http."
  }
}

# Compliance and Security Settings
variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable Security Hub for security posture management"
  type        = bool
  default     = true
}

# Cost and Resource Management
variable "enable_cost_anomaly_detection" {
  description = "Enable AWS Cost Anomaly Detection"
  type        = bool
  default     = false
}

variable "cost_anomaly_threshold" {
  description = "Cost anomaly detection threshold in USD"
  type        = number
  default     = 100
}