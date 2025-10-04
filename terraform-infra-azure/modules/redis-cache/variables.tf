# =============================================================================
# REDIS CACHE VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the Redis Cache instance"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.name))
    error_message = "Redis Cache name must be 1-63 characters long and can only contain letters, numbers, and hyphens."
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

variable "capacity" {
  description = "The size of the Redis cache to deploy"
  type        = number
  validation {
    condition = contains([
      0, 1, 2, 3, 4, 5, 6  # Basic/Standard: 0,1,2,3,4,5,6 | Premium: 1,2,3,4,5
    ], var.capacity)
    error_message = "Capacity must be between 0 and 6."
  }
}

variable "family" {
  description = "The SKU family/pricing group to use"
  type        = string
  default     = "C"
  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "Family must be C (Basic/Standard) or P (Premium)."
  }
}

variable "sku_name" {
  description = "The SKU of Redis to use"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU name must be Basic, Standard, or Premium."
  }
}

variable "enable_non_ssl_port" {
  description = "Enable the non-SSL port (6379)"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "The minimum TLS version"
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be 1.0, 1.1, or 1.2."
  }
}

variable "redis_version" {
  description = "Redis version to deploy"
  type        = string
  default     = "6"
  validation {
    condition     = contains(["4", "6"], var.redis_version)
    error_message = "Redis version must be 4 or 6."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled"
  type        = bool
  default     = true
}

variable "redis_configuration" {
  description = "Redis configuration settings"
  type = object({
    enable_authentication           = optional(bool, true)
    maxmemory_reserved             = optional(number)
    maxmemory_delta                = optional(number)
    maxmemory_policy               = optional(string, "volatile-lru")
    maxfragmentationmemory_reserved = optional(number)
    rdb_backup_enabled             = optional(bool, false)
    rdb_backup_frequency           = optional(number)
    rdb_backup_max_snapshot_count  = optional(number)
    rdb_storage_connection_string  = optional(string)
    notify_keyspace_events         = optional(string)
    aof_backup_enabled             = optional(bool, false)
    aof_storage_connection_string_0 = optional(string)
    aof_storage_connection_string_1 = optional(string)
  })
  default = {}
}

variable "patch_schedule" {
  description = "Patch schedule for the Redis cache"
  type = list(object({
    day_of_week        = string
    start_hour_utc     = optional(number)
    maintenance_window = optional(string)
  }))
  default = []
  validation {
    condition = alltrue([
      for schedule in var.patch_schedule :
      contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], schedule.day_of_week)
    ])
    error_message = "Day of week must be a valid day name."
  }
}

variable "private_static_ip_address" {
  description = "The static IP address to assign to the Redis cache when hosted inside a Virtual Network"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the subnet within which the Redis cache should be deployed"
  type        = string
  default     = null
}

variable "shard_count" {
  description = "Only available when using the Premium SKU - the number of shards to create on the Redis Cluster"
  type        = number
  default     = null
  validation {
    condition     = var.shard_count == null || (var.shard_count >= 1 && var.shard_count <= 10)
    error_message = "Shard count must be between 1 and 10."
  }
}

variable "zones" {
  description = "Specifies a list of Availability Zones in which this Redis Cache should be located"
  type        = list(string)
  default     = null
  validation {
    condition = var.zones == null || alltrue([
      for zone in var.zones :
      contains(["1", "2", "3"], zone)
    ])
    error_message = "Zones must be 1, 2, or 3."
  }
}

variable "identity" {
  description = "An identity block for the Redis Cache"
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

variable "replicas_per_master" {
  description = "Amount of replicas to create per master for this Redis Cache"
  type        = number
  default     = null
  validation {
    condition     = var.replicas_per_master == null || (var.replicas_per_master >= 1 && var.replicas_per_master <= 3)
    error_message = "Replicas per master must be between 1 and 3."
  }
}

variable "replicas_per_primary" {
  description = "Amount of replicas to create per primary for this Redis Cache"
  type        = number
  default     = null
  validation {
    condition     = var.replicas_per_primary == null || (var.replicas_per_primary >= 1 && var.replicas_per_primary <= 3)
    error_message = "Replicas per primary must be between 1 and 3."
  }
}

variable "tenant_settings" {
  description = "A mapping of tenant settings to values"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the Redis Cache"
  type        = map(string)
  default     = {}
}

# Private endpoint configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for the Redis Cache"
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

# Firewall rules
variable "firewall_rules" {
  description = "Firewall rules for the Redis Cache"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}