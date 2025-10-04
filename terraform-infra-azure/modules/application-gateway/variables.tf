# =============================================================================
# APPLICATION GATEWAY MODULE VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the Application Gateway"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Application Gateway"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where Application Gateway will be deployed"
  type        = string
}

variable "public_ip_id" {
  description = "ID of the public IP for the Application Gateway"
  type        = string
}

# SKU Configuration
variable "sku_name" {
  description = "SKU name for the Application Gateway"
  type        = string
  default     = "WAF_v2"

  validation {
    condition = contains([
      "Standard_Small", "Standard_Medium", "Standard_Large",
      "WAF_Medium", "WAF_Large", "Standard_v2", "WAF_v2"
    ], var.sku_name)
    error_message = "SKU name must be a valid Application Gateway SKU."
  }
}

variable "sku_tier" {
  description = "SKU tier for the Application Gateway"
  type        = string
  default     = "WAF_v2"

  validation {
    condition = contains([
      "Standard", "WAF", "Standard_v2", "WAF_v2"
    ], var.sku_tier)
    error_message = "SKU tier must be a valid Application Gateway tier."
  }
}

variable "sku_capacity" {
  description = "SKU capacity for the Application Gateway"
  type        = number
  default     = 2

  validation {
    condition     = var.sku_capacity >= 1 && var.sku_capacity <= 125
    error_message = "SKU capacity must be between 1 and 125."
  }
}

# WAF Configuration
variable "waf_enabled" {
  description = "Enable WAF for the Application Gateway"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode for the Application Gateway"
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be either Detection or Prevention."
  }
}

# Autoscale Configuration
variable "enable_autoscale" {
  description = "Enable autoscaling for the Application Gateway"
  type        = bool
  default     = true
}

variable "autoscale_min_capacity" {
  description = "Minimum capacity for autoscaling"
  type        = number
  default     = 1

  validation {
    condition     = var.autoscale_min_capacity >= 0 && var.autoscale_min_capacity <= 125
    error_message = "Autoscale minimum capacity must be between 0 and 125."
  }
}

variable "autoscale_max_capacity" {
  description = "Maximum capacity for autoscaling"
  type        = number
  default     = 10

  validation {
    condition     = var.autoscale_max_capacity >= 2 && var.autoscale_max_capacity <= 125
    error_message = "Autoscale maximum capacity must be between 2 and 125."
  }
}

variable "tags" {
  description = "Tags to apply to the Application Gateway"
  type        = map(string)
  default     = {}
}