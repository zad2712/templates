# KMS Module - Variables
# Author: Diego A. Zarate

# General Configuration
variable "name_prefix" {
  description = "Name prefix for KMS resources"
  type        = string
  default     = "app"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "Name prefix must be between 1 and 32 characters."
  }
}

variable "tags" {
  description = "A map of tags to assign to KMS resources"
  type        = map(string)
  default     = {}
}

# Standard Keys Configuration
variable "create_standard_keys" {
  description = "Whether to create standard service keys (S3, EBS, RDS, etc.)"
  type        = bool
  default     = true
}

# KMS Keys Configuration
variable "kms_keys" {
  description = "Map of KMS keys to create"
  type = map(object({
    description                        = string
    key_usage                         = optional(string, "ENCRYPT_DECRYPT")
    key_spec                          = optional(string, "SYMMETRIC_DEFAULT")
    customer_master_key_spec          = optional(string, null)
    policy                            = optional(string, null)
    deletion_window_in_days           = optional(number, 30)
    is_enabled                        = optional(bool, true)
    enable_key_rotation               = optional(bool, true)
    rotation_period_in_days           = optional(number, 365)
    multi_region                      = optional(bool, false)
    bypass_policy_lockout_safety_check = optional(bool, false)
    
    # Policy principals
    key_administrators = optional(list(string), [])
    key_users         = optional(list(string), [])
    service_principals = optional(list(string), [])
    external_accounts  = optional(list(string), [])
    
    # Multi-region configuration
    replica_regions = optional(list(string), [])
    replica_policy  = optional(string, null)
    
    # Grants configuration
    grants = optional(map(object({
      grantee_principal = string
      operations       = list(string)
      constraints = optional(object({
        encryption_context_equals = optional(map(string), {})
        encryption_context_subset = optional(map(string), {})
      }), null)
      retiring_principal    = optional(string, null)
      grant_creation_tokens = optional(list(string), null)
    })), {})
    
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.kms_keys :
      contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], v.key_usage)
    ])
    error_message = "Key usage must be either ENCRYPT_DECRYPT or SIGN_VERIFY."
  }

  validation {
    condition = alltrue([
      for k, v in var.kms_keys :
      v.deletion_window_in_days >= 7 && v.deletion_window_in_days <= 30
    ])
    error_message = "Deletion window must be between 7 and 30 days."
  }

  validation {
    condition = alltrue([
      for k, v in var.kms_keys :
      v.rotation_period_in_days >= 90 && v.rotation_period_in_days <= 2560
    ])
    error_message = "Rotation period must be between 90 and 2560 days."
  }
}

# External Keys Configuration (BYOK)
variable "external_keys" {
  description = "Map of external KMS keys to create (Bring Your Own Key)"
  type = map(object({
    description                        = string
    policy                            = optional(string, null)
    deletion_window_in_days           = optional(number, 30)
    enabled                           = optional(bool, true)
    key_material_base64               = optional(string, null)
    valid_to                          = optional(string, null)
    multi_region                      = optional(bool, false)
    bypass_policy_lockout_safety_check = optional(bool, false)
    tags                              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.external_keys :
      v.deletion_window_in_days >= 7 && v.deletion_window_in_days <= 30
    ])
    error_message = "Deletion window for external keys must be between 7 and 30 days."
  }
}