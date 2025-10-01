#####################################################################################################
# Fetch Data Module - Variables Configuration
# Input variables for fetching data from infrastructure modules using remote state
#####################################################################################################

#####################################################################################################
# Environment and Identification Variables
#####################################################################################################

variable "environment" {
  description = "Environment name for identifying the correct state files and resources"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "name_prefix" {
  description = "Name prefix used across infrastructure for consistent resource identification"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.name_prefix))
    error_message = "Name prefix must contain only alphanumeric characters and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region where the infrastructure is deployed"
  type        = string
  default     = null

  validation {
    condition = var.aws_region == null || can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-west-2, eu-west-1)."
  }
}

#####################################################################################################
# Remote State Configuration Variables
#####################################################################################################

variable "terraform_state_bucket" {
  description = "S3 bucket name where Terraform state files are stored"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.terraform_state_bucket))
    error_message = "S3 bucket name must be between 3 and 63 characters, lowercase letters, numbers, dots, and hyphens only."
  }
}

variable "state_bucket_region" {
  description = "AWS region where the Terraform state bucket is located"
  type        = string
  default     = null

  validation {
    condition = var.state_bucket_region == null || can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.state_bucket_region))
    error_message = "State bucket region must be a valid AWS region format."
  }
}

variable "state_key_prefix" {
  description = "Prefix for state file keys in S3 bucket (e.g., 'environments' for environments/dev/core/terraform.tfstate)"
  type        = string
  default     = "layers"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_-]*[^/]$", var.state_key_prefix))
    error_message = "State key prefix must contain only alphanumeric characters, hyphens, underscores, and forward slashes, and cannot end with a slash."
  }
}

variable "use_workspace_in_state_key" {
  description = "Whether to include the workspace/environment name in the state key path"
  type        = bool
  default     = true
}

#####################################################################################################
# Module Selection Variables
#####################################################################################################

variable "fetch_vpc_module" {
  description = "Whether to fetch data from the VPC module (core layer)"
  type        = bool
  default     = true
}

variable "fetch_backend_module" {
  description = "Whether to fetch data from backend modules (future extensibility)"
  type        = bool
  default     = false
}

variable "fetch_frontend_module" {
  description = "Whether to fetch data from frontend modules (future extensibility)"
  type        = bool
  default     = false
}

variable "fetch_data_module" {
  description = "Whether to fetch data from data/database modules (future extensibility)"
  type        = bool
  default     = false
}

#####################################################################################################
# Module Configuration Variables
#####################################################################################################

variable "core_layer_config" {
  description = "Configuration for accessing the core layer (VPC module) state"
  type = object({
    enabled           = bool
    state_key         = optional(string)
    workspace         = optional(string)
    specific_outputs  = optional(list(string))
  })
  default = {
    enabled           = true
    state_key         = null  # Will use computed default
    workspace         = null  # Will use environment variable
    specific_outputs  = null  # Will fetch all outputs
  }
}

variable "backend_layer_config" {
  description = "Configuration for accessing backend layer state (future extensibility)"
  type = object({
    enabled           = bool
    state_key         = optional(string)
    workspace         = optional(string)
    specific_outputs  = optional(list(string))
  })
  default = {
    enabled           = false
    state_key         = null
    workspace         = null
    specific_outputs  = null
  }
}

variable "frontend_layer_config" {
  description = "Configuration for accessing frontend layer state (future extensibility)"
  type = object({
    enabled           = bool
    state_key         = optional(string)
    workspace         = optional(string)
    specific_outputs  = optional(list(string))
  })
  default = {
    enabled           = false
    state_key         = null
    workspace         = null
    specific_outputs  = null
  }
}

variable "data_layer_config" {
  description = "Configuration for accessing data layer state (future extensibility)"
  type = object({
    enabled           = bool
    state_key         = optional(string)
    workspace         = optional(string)
    specific_outputs  = optional(list(string))
  })
  default = {
    enabled           = false
    state_key         = null
    workspace         = null
    specific_outputs  = null
  }
}

#####################################################################################################
# Advanced Configuration Variables
#####################################################################################################

variable "state_lock_table" {
  description = "DynamoDB table name for Terraform state locking (optional)"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ID for state file encryption (optional)"
  type        = string
  default     = null
}

variable "assume_role_arn" {
  description = "IAM role ARN to assume when accessing state files (for cross-account access)"
  type        = string
  default     = null

  validation {
    condition = var.assume_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.assume_role_arn))
    error_message = "Assume role ARN must be a valid IAM role ARN format."
  }
}

variable "retry_attempts" {
  description = "Number of retry attempts for accessing remote state"
  type        = number
  default     = 3

  validation {
    condition     = var.retry_attempts >= 1 && var.retry_attempts <= 10
    error_message = "Retry attempts must be between 1 and 10."
  }
}

#####################################################################################################
# Output Configuration Variables
#####################################################################################################

variable "output_format" {
  description = "Format for organizing outputs (structured, flat, or raw)"
  type        = string
  default     = "structured"

  validation {
    condition     = contains(["structured", "flat", "raw"], var.output_format)
    error_message = "Output format must be one of: structured, flat, raw."
  }
}

variable "include_metadata" {
  description = "Whether to include metadata in outputs (timestamps, source info, etc.)"
  type        = bool
  default     = true
}

variable "sensitive_outputs" {
  description = "Whether to mark outputs as sensitive"
  type        = bool
  default     = false
}