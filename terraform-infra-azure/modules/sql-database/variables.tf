# =============================================================================
# SQL DATABASE VARIABLES
# =============================================================================

variable "server_name" {
  description = "Name of the SQL Server"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.server_name)) && length(var.server_name) >= 1 && length(var.server_name) <= 63
    error_message = "SQL Server name must be 1-63 characters long, start and end with alphanumeric characters, and can only contain lowercase letters, numbers, and hyphens."
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

variable "sql_version" {
  description = "The version for the new server"
  type        = string
  default     = "12.0"
  validation {
    condition     = contains(["2.0", "12.0"], var.sql_version)
    error_message = "SQL Server version must be '2.0' or '12.0'."
  }
}

variable "administrator_login" {
  description = "The administrator username of the SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "administrator_login_password" {
  description = "The administrator password of the SQL Server"
  type        = string
  sensitive   = true
  default     = null
}

variable "use_managed_identity" {
  description = "Use Azure AD authentication instead of SQL authentication"
  type        = bool
  default     = true
}

variable "azuread_administrator" {
  description = "Azure AD administrator configuration"
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool, false)
  })
  default = null
}

variable "connection_policy" {
  description = "The connection policy the server will use"
  type        = string
  default     = "Default"
  validation {
    condition     = contains(["Default", "Proxy", "Redirect"], var.connection_policy)
    error_message = "Connection policy must be 'Default', 'Proxy', or 'Redirect'."
  }
}

variable "minimum_tls_version" {
  description = "The minimum TLS version for the server"
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2", "Disabled"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be '1.0', '1.1', '1.2', or 'Disabled'."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for this server"
  type        = bool
  default     = true
}

variable "outbound_network_restriction_enabled" {
  description = "Whether outbound network traffic is restricted for this server"
  type        = bool
  default     = false
}

variable "identity" {
  description = "An identity block for the SQL Server"
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

variable "transparent_data_encryption_key_vault_key_id" {
  description = "The Key Vault key identifier for transparent data encryption"
  type        = string
  default     = null
}

variable "primary_user_assigned_identity_id" {
  description = "The primary user assigned identity ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the SQL Server"
  type        = map(string)
  default     = {}
}

# Database Configuration
variable "databases" {
  description = "List of databases to create on the server"
  type = list(object({
    name                        = string
    collation                   = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    license_type               = optional(string, "LicenseIncluded")
    max_size_gb                = optional(number, 250)
    min_capacity               = optional(number, 0.5)
    auto_pause_delay_in_minutes = optional(number, 60)
    read_scale                 = optional(bool, false)
    read_replica_count         = optional(number, 0)
    sku_name                   = optional(string, "GP_S_Gen5_2")
    zone_redundant             = optional(bool, false)
    create_mode               = optional(string, "Default")
    creation_source_database_id = optional(string)
    restore_point_in_time      = optional(string)
    recover_database_id        = optional(string)
    restore_dropped_database_id = optional(string)
    sample_name               = optional(string)
    storage_account_type      = optional(string, "Geo")
    threat_detection_policy = optional(object({
      state                      = optional(string, "Enabled")
      disabled_alerts           = optional(list(string), [])
      email_account_admins      = optional(string, "Enabled")
      email_addresses           = optional(list(string), [])
      retention_days            = optional(number, 0)
      storage_account_access_key = optional(string)
      storage_endpoint          = optional(string)
    }))
    long_term_retention_policy = optional(object({
      weekly_retention  = optional(string, "PT0S")
      monthly_retention = optional(string, "PT0S")
      yearly_retention  = optional(string, "PT0S")
      week_of_year     = optional(number, 1)
    }))
    short_term_retention_policy = optional(object({
      retention_days           = optional(number, 7)
      backup_interval_in_hours = optional(number, 24)
    }))
    tags = optional(map(string), {})
  }))
  default = []
}

# Elastic Pool Configuration
variable "elastic_pools" {
  description = "List of elastic pools to create on the server"
  type = list(object({
    name     = string
    sku = object({
      name     = string
      tier     = string
      family   = optional(string)
      capacity = number
    })
    per_database_settings = object({
      min_capacity = number
      max_capacity = number
    })
    max_size_gb    = optional(number)
    zone_redundant = optional(bool, false)
    license_type   = optional(string, "LicenseIncluded")
    maintenance_configuration_name = optional(string)
    tags = optional(map(string), {})
  }))
  default = []
}

# Firewall Rules
variable "firewall_rules" {
  description = "List of firewall rules for the SQL Server"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

# Virtual Network Rules
variable "virtual_network_rules" {
  description = "List of virtual network rules for the SQL Server"
  type = list(object({
    name                                 = string
    subnet_id                           = string
    ignore_missing_vnet_service_endpoint = optional(bool, false)
  }))
  default = []
}

# Private endpoint configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for the SQL Server"
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

# Diagnostic settings
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
  default     = null
}

# Failover Group Configuration
variable "failover_group" {
  description = "Failover group configuration for the SQL Server"
  type = object({
    name                          = string
    partner_server_id            = string
    databases                    = list(string)
    grace_minutes               = optional(number, 60)
    mode                        = optional(string, "Automatic")
    read_write_endpoint_failover_policy = optional(object({
      mode          = string
      grace_minutes = optional(number)
    }))
    readonly_endpoint_failover_policy = optional(object({
      mode = string
    }))
    tags = optional(map(string), {})
  })
  default = null
}

# Server Security Alert Policy
variable "security_alert_policy" {
  description = "Security alert policy configuration for the SQL Server"
  type = object({
    state                      = optional(string, "Enabled")
    disabled_alerts           = optional(list(string), [])
    email_account_admins      = optional(bool, false)
    email_addresses           = optional(list(string), [])
    retention_days            = optional(number, 0)
    storage_account_access_key = optional(string)
    storage_endpoint          = optional(string)
  })
  default = null
}

# Vulnerability Assessment
variable "vulnerability_assessment" {
  description = "Vulnerability assessment configuration for the SQL Server"
  type = object({
    storage_container_path     = string
    storage_account_access_key = optional(string)
    storage_container_sas_key  = optional(string)
    recurring_scans = optional(object({
      enabled                   = optional(bool, true)
      email_subscription_admins = optional(bool, false)
      emails                   = optional(list(string), [])
    }))
  })
  default = null
}