# =============================================================================
# KMS MODULE VARIABLES
# =============================================================================

variable "key_name" {
  description = "Name for the KMS key"
  type        = string
  default     = "default-kms-key"
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "KMS key for encryption"
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction of the resource"
  type        = number
  default     = 7
  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "key_usage" {
  description = "Specifies the intended use of the key"
  type        = string
  default     = "ENCRYPT_DECRYPT"
  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], var.key_usage)
    error_message = "Key usage must be either ENCRYPT_DECRYPT or SIGN_VERIFY."
  }
}

variable "customer_master_key_spec" {
  description = "Specifies whether the key contains a symmetric key or an asymmetric key pair"
  type        = string
  default     = "SYMMETRIC_DEFAULT"
  validation {
    condition = contains([
      "SYMMETRIC_DEFAULT",
      "RSA_2048",
      "RSA_3072",
      "RSA_4096",
      "ECC_NIST_P256",
      "ECC_NIST_P384",
      "ECC_NIST_P521",
      "ECC_SECG_P256K1"
    ], var.customer_master_key_spec)
    error_message = "Invalid customer master key spec."
  }
}

variable "policy" {
  description = "A valid policy JSON document for the KMS key"
  type        = string
  default     = null
}

variable "key_administrators" {
  description = "List of IAM ARNs for those who will have administrative permissions"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs for those who will have usage permissions"
  type        = list(string)
  default     = []
}

variable "create_alias" {
  description = "Whether to create an alias for the KMS key"
  type        = bool
  default     = true
}

variable "alias_name" {
  description = "Name for the KMS alias (without alias/ prefix)"
  type        = string
  default     = null
}

variable "grants" {
  description = "Map of grants to create for the KMS key"
  type = map(object({
    grantee_principal = string
    operations        = list(string)
    constraints = optional(list(object({
      encryption_context_equals = optional(map(string))
      encryption_context_subset = optional(map(string))
    })), [])
    retire_on_delete = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
