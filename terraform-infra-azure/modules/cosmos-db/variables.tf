# =============================================================================
# COSMOS DB VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the Cosmos DB account"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,44}$", var.name))
    error_message = "Cosmos DB account name must be 3-44 characters long and can only contain lowercase letters, numbers, and hyphens."
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

variable "offer_type" {
  description = "Specifies the Offer Type to use for this CosmosDB Account"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard"], var.offer_type)
    error_message = "The offer_type must be Standard."
  }
}

variable "kind" {
  description = "Specifies the Kind of CosmosDB to create"
  type        = string
  default     = "GlobalDocumentDB"
  validation {
    condition = contains([
      "GlobalDocumentDB", "MongoDB", "Parse"
    ], var.kind)
    error_message = "The kind must be GlobalDocumentDB, MongoDB, or Parse."
  }
}

variable "consistency_policy" {
  description = "Consistency policy for the CosmosDB account"
  type = object({
    consistency_level       = string
    max_interval_in_seconds = optional(number, 300)
    max_staleness_prefix   = optional(number, 100000)
  })
  default = {
    consistency_level = "Session"
  }
  validation {
    condition = contains([
      "BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"
    ], var.consistency_policy.consistency_level)
    error_message = "Consistency level must be one of: BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix."
  }
}

variable "geo_location" {
  description = "Geo-locations for the CosmosDB account"
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
  default = []
}

variable "enable_automatic_failover" {
  description = "Enable automatic failover for this Cosmos DB account"
  type        = bool
  default     = true
}

variable "enable_multiple_write_locations" {
  description = "Enable multiple write locations for this Cosmos DB account"
  type        = bool
  default     = false
}

variable "ip_range_filter" {
  description = "IP addresses or IP address ranges in CIDR form to allow access"
  type        = string
  default     = ""
}

variable "enable_free_tier" {
  description = "Enable free tier pricing option for this Cosmos DB account"
  type        = bool
  default     = false
}

variable "analytical_storage_enabled" {
  description = "Enable Analytical Storage option for this Cosmos DB account"
  type        = bool
  default     = false
}

variable "capacity" {
  description = "The total throughput limit for this Cosmos DB account"
  type = object({
    total_throughput_limit = number
  })
  default = null
}

variable "backup" {
  description = "Backup configuration for the CosmosDB account"
  type = object({
    type                = string
    interval_in_minutes = optional(number, 240)
    retention_in_hours  = optional(number, 8)
    storage_redundancy  = optional(string, "Geo")
  })
  default = {
    type = "Periodic"
  }
  validation {
    condition = contains(["Continuous", "Periodic"], var.backup.type)
    error_message = "Backup type must be Continuous or Periodic."
  }
}

variable "cors_rule" {
  description = "Cross-Origin Resource Sharing (CORS) rules"
  type = object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  })
  default = null
}

variable "identity" {
  description = "An identity block for the Cosmos DB account"
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

variable "virtual_network_rule" {
  description = "Virtual network rules for the CosmosDB account"
  type = list(object({
    id                                   = string
    ignore_missing_vnet_service_endpoint = optional(bool, false)
  }))
  default = []
}

variable "enable_analytical_storage" {
  description = "Enable analytical storage for the CosmosDB account"
  type        = bool
  default     = false
}

variable "network_acl_bypass_for_azure_services" {
  description = "If Azure services can bypass ACLs"
  type        = bool
  default     = false
}

variable "network_acl_bypass_ids" {
  description = "List of resource IDs for the network ACL bypass"
  type        = list(string)
  default     = []
}

variable "local_authentication_disabled" {
  description = "Disable local authentication and ensure only MSI and AAD can be used exclusively for authentication"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the CosmosDB account"
  type        = map(string)
  default     = {}
}

# Database configuration
variable "databases" {
  description = "List of databases to create in the Cosmos DB account"
  type = list(object({
    name       = string
    throughput = optional(number)
    autoscale_settings = optional(object({
      max_throughput = number
    }))
    containers = optional(list(object({
      name               = string
      partition_key_path = string
      partition_key_kind = optional(string, "Hash")
      throughput         = optional(number)
      autoscale_settings = optional(object({
        max_throughput = number
      }))
      default_ttl = optional(number)
      unique_key = optional(list(object({
        paths = list(string)
      })))
      included_path = optional(list(object({
        path = string
      })))
      excluded_path = optional(list(object({
        path = string
      })))
      composite_index = optional(list(object({
        index = list(object({
          path  = string
          order = string
        }))
      })))
      spatial_index = optional(list(object({
        path = string
      })))
      conflict_resolution_policy = optional(object({
        mode                          = string
        conflict_resolution_path      = optional(string)
        conflict_resolution_procedure = optional(string)
      }))
    })))
  }))
  default = []
}