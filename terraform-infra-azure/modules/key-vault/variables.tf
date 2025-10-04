# =============================================================================
# KEY VAULT VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the Key Vault"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z]([a-zA-Z0-9-]*[a-zA-Z0-9])?$", var.name)) && length(var.name) >= 3 && length(var.name) <= 24
    error_message = "Key Vault name must be 3-24 characters long, start with a letter, and contain only alphanumeric characters and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location where resources will be created"
  type        = string
}

variable "sku_name" {
  description = "The Name of the SKU used for this Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "tenant_id" {
  description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault"
  type        = string
  default     = null
}

variable "enabled_for_deployment" {
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault?"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACLs for the Key Vault"
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action            = optional(string, "Allow")
    ip_rules                  = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
  validation {
    condition = var.network_acls == null || (
      contains(["AzureServices", "None"], var.network_acls.bypass) &&
      contains(["Allow", "Deny"], var.network_acls.default_action)
    )
    error_message = "Network ACLs bypass must be 'AzureServices' or 'None', and default_action must be 'Allow' or 'Deny'."
  }
}

variable "access_policies" {
  description = "List of access policies for the Key Vault"
  type = list(object({
    tenant_id               = optional(string)
    object_id               = string
    application_id          = optional(string)
    certificate_permissions = optional(list(string), [])
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = []
}

variable "contact" {
  description = "Contact information for the Key Vault certificate issuer"
  type = list(object({
    email = string
    name  = optional(string)
    phone = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the Key Vault"
  type        = map(string)
  default     = {}
}

# Private endpoint configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for the Key Vault"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for the private endpoint"
  type        = string
  default     = null
}

# Secrets to create in the Key Vault
variable "secrets" {
  description = "Map of secrets to create in the Key Vault"
  type = map(object({
    value            = string
    content_type     = optional(string)
    not_before_date  = optional(string)
    expiration_date  = optional(string)
    tags            = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}

# Keys to create in the Key Vault
variable "keys" {
  description = "Map of keys to create in the Key Vault"
  type = map(object({
    key_type        = string
    key_size        = optional(number)
    curve           = optional(string)
    key_opts        = optional(list(string))
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags           = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for key in var.keys :
      contains(["EC", "EC-HSM", "RSA", "RSA-HSM"], key.key_type)
    ])
    error_message = "Key type must be one of: EC, EC-HSM, RSA, RSA-HSM."
  }
}

# Certificates to create in the Key Vault
variable "certificates" {
  description = "Map of certificates to create in the Key Vault"
  type = map(object({
    certificate_policy = object({
      issuer_parameters = object({
        name = string
      })
      key_properties = object({
        exportable = bool
        key_size   = optional(number, 2048)
        key_type   = optional(string, "RSA")
        reuse_key  = optional(bool, true)
      })
      lifetime_actions = optional(list(object({
        action = object({
          action_type = string
        })
        trigger = object({
          days_before_expiry  = optional(number)
          lifetime_percentage = optional(number)
        })
      })))
      secret_properties = object({
        content_type = string
      })
      x509_certificate_properties = optional(object({
        extended_key_usage = optional(list(string))
        key_usage          = list(string)
        subject            = string
        validity_in_months = number
        subject_alternative_names = optional(object({
          dns_names = optional(list(string))
          emails    = optional(list(string))
          upns      = optional(list(string))
        }))
      }))
    })
    tags = optional(map(string), {})
  }))
  default = {}
}

# Diagnostic settings
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
  default     = null
}