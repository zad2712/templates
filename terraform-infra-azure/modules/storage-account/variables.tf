# =============================================================================
# STORAGE ACCOUNT VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the storage account"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 characters long and can only contain lowercase letters and numbers."
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

variable "account_tier" {
  description = "Defines the Tier to use for this storage account"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account"
  type        = string
  default     = "LRS"
  validation {
    condition = contains([
      "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"
    ], var.account_replication_type)
    error_message = "Account replication type must be LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

variable "account_kind" {
  description = "Defines the Kind of account"
  type        = string
  default     = "StorageV2"
  validation {
    condition = contains([
      "BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"
    ], var.account_kind)
    error_message = "Account kind must be BlobStorage, BlockBlobStorage, FileStorage, Storage, or StorageV2."
  }
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts"
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be Hot or Cool."
  }
}

variable "enable_https_traffic_only" {
  description = "Boolean flag which forces HTTPS if enabled"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account"
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Minimum TLS version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow or disallow nested items within this Account to opt into being public"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the public network access is enabled"
  type        = bool
  default     = true
}

variable "default_to_oauth_authentication" {
  description = "Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account"
  type        = bool
  default     = false
}

variable "cross_tenant_replication_enabled" {
  description = "Should cross Tenant replication be enabled"
  type        = bool
  default     = true
}

variable "edge_zone" {
  description = "Specifies the Edge Zone within the Azure Region where this Storage Account should exist"
  type        = string
  default     = null
}

variable "large_file_share_enabled" {
  description = "Is Large File Share Enabled?"
  type        = bool
  default     = null
}

variable "nfsv3_enabled" {
  description = "Is NFSv3 protocol enabled?"
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Is infrastructure encryption enabled?"
  type        = bool
  default     = false
}

variable "sftp_enabled" {
  description = "Boolean, enable SFTP for the storage account"
  type        = bool
  default     = false
}

variable "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled?"
  type        = bool
  default     = false
}

variable "identity" {
  description = "An identity block for the Storage Account"
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null
  validation {
    condition = var.identity == null || contains([
      "SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"
    ], var.identity.type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "blob_properties" {
  description = "Blob properties configuration"
  type = object({
    versioning_enabled       = optional(bool, false)
    change_feed_enabled      = optional(bool, false)
    change_feed_retention_in_days = optional(number, 7)
    default_service_version  = optional(string)
    last_access_time_enabled = optional(bool, false)
    container_delete_retention_policy = optional(object({
      days = optional(number, 7)
    }))
    delete_retention_policy = optional(object({
      days = optional(number, 7)
    }))
    restore_policy = optional(object({
      days = number
    }))
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
  })
  default = {}
}

variable "queue_properties" {
  description = "Queue properties configuration"
  type = object({
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    logging = optional(object({
      delete                = bool
      read                  = bool
      version               = string
      write                 = bool
      retention_policy_days = optional(number)
    }))
    minute_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
    hour_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
  })
  default = {}
}

variable "share_properties" {
  description = "Share properties configuration"
  type = object({
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    retention_policy = optional(object({
      days = optional(number, 7)
    }))
    smb = optional(object({
      versions                        = optional(list(string))
      authentication_types            = optional(list(string))
      kerberos_ticket_encryption_type = optional(list(string))
      channel_encryption_type         = optional(list(string))
      multichannel_enabled           = optional(bool)
    }))
  })
  default = {}
}

variable "static_website" {
  description = "Static website configuration"
  type = object({
    index_document     = optional(string)
    error_404_document = optional(string)
  })
  default = null
}

variable "network_rules" {
  description = "Network rules for the storage account"
  type = object({
    default_action             = optional(string, "Allow")
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
  })
  default = null
  validation {
    condition = var.network_rules == null || (
      contains(["Allow", "Deny"], var.network_rules.default_action)
    )
    error_message = "Network rules default_action must be Allow or Deny."
  }
}

variable "azure_files_authentication" {
  description = "Azure Files authentication configuration"
  type = object({
    directory_type = string
    active_directory = optional(object({
      storage_sid         = string
      domain_name        = string
      domain_sid         = string
      domain_guid        = string
      forest_name        = string
      netbios_domain_name = string
    }))
  })
  default = null
  validation {
    condition = var.azure_files_authentication == null || contains([
      "AADDS", "AD", "AADKERB"
    ], var.azure_files_authentication.directory_type)
    error_message = "Directory type must be AADDS, AD, or AADKERB."
  }
}

variable "routing" {
  description = "Routing configuration"
  type = object({
    publish_internet_endpoints  = optional(bool, false)
    publish_microsoft_endpoints = optional(bool, false)
    choice                     = optional(string, "MicrosoftRouting")
  })
  default = null
  validation {
    condition = var.routing == null || contains([
      "InternetRouting", "MicrosoftRouting"
    ], var.routing.choice)
    error_message = "Routing choice must be InternetRouting or MicrosoftRouting."
  }
}

variable "immutability_policy" {
  description = "Immutability policy configuration"
  type = object({
    allow_protected_append_writes = bool
    state                        = string
    period_since_creation_in_days = number
  })
  default = null
  validation {
    condition = var.immutability_policy == null || contains([
      "Locked", "Unlocked"
    ], var.immutability_policy.state)
    error_message = "Immutability policy state must be Locked or Unlocked."
  }
}

variable "sas_policy" {
  description = "SAS policy configuration"
  type = object({
    expiration_period = string
    expiration_action = optional(string, "Log")
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to the storage account"
  type        = map(string)
  default     = {}
}

# Containers configuration
variable "containers" {
  description = "List of containers to create in the storage account"
  type = list(object({
    name                  = string
    container_access_type = optional(string, "private")
    metadata             = optional(map(string), {})
  }))
  default = []
  validation {
    condition = alltrue([
      for container in var.containers :
      contains(["blob", "container", "private"], container.container_access_type)
    ])
    error_message = "Container access type must be blob, container, or private."
  }
}

# File shares configuration
variable "file_shares" {
  description = "List of file shares to create in the storage account"
  type = list(object({
    name             = string
    quota           = optional(number, 50)
    enabled_protocol = optional(string, "SMB")
    metadata        = optional(map(string), {})
    acl = optional(list(object({
      id = string
      access_policy = optional(object({
        permissions = string
        start       = optional(string)
        expiry      = optional(string)
      }))
    })))
  }))
  default = []
  validation {
    condition = alltrue([
      for share in var.file_shares :
      contains(["SMB", "NFS"], share.enabled_protocol)
    ])
    error_message = "File share protocol must be SMB or NFS."
  }
}

# Queues configuration
variable "queues" {
  description = "List of queues to create in the storage account"
  type = list(object({
    name     = string
    metadata = optional(map(string), {})
  }))
  default = []
}

# Tables configuration
variable "tables" {
  description = "List of tables to create in the storage account"
  type = list(object({
    name = string
    acl = optional(list(object({
      id = string
      access_policy = optional(object({
        permissions = string
        start       = optional(string)
        expiry      = optional(string)
      }))
    })))
  }))
  default = []
}

# Private endpoint configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for the storage account"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Map of private DNS zone IDs for different storage services"
  type = object({
    blob  = optional(string)
    dfs   = optional(string)
    file  = optional(string)
    queue = optional(string)
    table = optional(string)
    web   = optional(string)
  })
  default = {}
}

# Diagnostic settings
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
  default     = null
}

# Customer-managed key configuration
variable "customer_managed_key" {
  description = "Customer-managed key configuration for encryption"
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  default = null
}