# =============================================================================
# RESOURCE GROUP MODULE VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the resource group"
  type        = string

  validation {
    condition     = length(var.name) <= 90 && can(regex("^[a-zA-Z0-9._\\-()]+$", var.name))
    error_message = "Resource group name must be valid and max 90 characters."
  }
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string
}

variable "enable_lock" {
  description = "Enable resource group lock"
  type        = bool
  default     = false
}

variable "lock_level" {
  description = "Level of the resource group lock"
  type        = string
  default     = "CanNotDelete"

  validation {
    condition     = contains(["ReadOnly", "CanNotDelete"], var.lock_level)
    error_message = "Lock level must be either ReadOnly or CanNotDelete."
  }
}

variable "tags" {
  description = "Tags to apply to the resource group"
  type        = map(string)
  default     = {}
}