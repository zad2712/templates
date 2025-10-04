# =============================================================================
# SECURITY LAYER VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
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
# KMS CONFIGURATION
# =============================================================================

variable "kms_keys" {
  description = "Map of KMS keys to create"
  type = map(object({
    description             = string
    policy                  = optional(string)
    deletion_window_in_days = optional(number, 7)
  }))
  default = {
    general = {
      description = "General purpose KMS key"
    }
    rds = {
      description = "KMS key for RDS encryption"
    }
    s3 = {
      description = "KMS key for S3 encryption"
    }
  }
}

# =============================================================================
# IAM CONFIGURATION
# =============================================================================

variable "application_roles" {
  description = "Map of application-specific IAM roles"
  type = map(object({
    description        = string
    assume_role_policy = string
    policies           = list(string)
    policy_arns        = optional(list(string), [])
  }))
  default = {}
}

variable "service_roles" {
  description = "Map of AWS service IAM roles (EC2, Lambda, ECS, etc.)"
  type = map(object({
    service     = string
    description = string
    policies    = optional(list(string), [])
    policy_arns = optional(list(string), [])
  }))
  default = {}
}

# =============================================================================
# SECURITY GROUPS CONFIGURATION
# =============================================================================

variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    description = string
    ingress = optional(list(object({
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      security_groups = optional(list(string), [])
      description     = optional(string)
    })), [])
    egress = optional(list(object({
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      security_groups = optional(list(string), [])
      description     = optional(string)
    })), [])
  }))
  default = {}
}

# =============================================================================
# WAF CONFIGURATION
# =============================================================================

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = false
}

variable "waf_scope" {
  description = "WAF scope (CLOUDFRONT or REGIONAL)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.waf_scope)
    error_message = "WAF scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "waf_rules" {
  description = "WAF rules configuration"
  type = map(object({
    priority  = number
    action    = string
    rule_type = string
    statement = any
  }))
  default = {}
}

# =============================================================================
# SECRETS MANAGER CONFIGURATION
# =============================================================================

variable "secrets" {
  description = "Map of secrets to create in AWS Secrets Manager"
  type = map(object({
    description             = string
    secret_string           = optional(string)
    secret_binary           = optional(string)
    recovery_window_in_days = optional(number, 7)
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
