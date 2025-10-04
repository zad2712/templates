# =============================================================================
# APP SERVICE MODULE VARIABLES
# =============================================================================

# Basic Configuration
variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# App Service Plan
variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "os_type" {
  description = "Operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"
  
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be either 'Linux' or 'Windows'."
  }
}

variable "sku_name" {
  description = "SKU name for the App Service Plan"
  type        = string
  default     = "P1v2"
}

variable "zone_balancing_enabled" {
  description = "Enable zone balancing for the App Service Plan"
  type        = bool
  default     = false
}

variable "worker_count" {
  description = "Number of workers"
  type        = number
  default     = 1
}

variable "per_site_scaling_enabled" {
  description = "Enable per-site scaling"
  type        = bool
  default     = false
}

# Network Configuration
variable "subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the App Service"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private endpoint"
  type        = string
  default     = null
}

# Identity Configuration
variable "identity_type" {
  description = "Type of managed identity (SystemAssigned, UserAssigned, or SystemAssigned,UserAssigned)"
  type        = string
  default     = "SystemAssigned"
  
  validation {
    condition = var.identity_type == null || contains([
      "SystemAssigned",
      "UserAssigned", 
      "SystemAssigned, UserAssigned"
    ], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "List of user assigned identity IDs"
  type        = list(string)
  default     = []
}

# Site Configuration
variable "always_on" {
  description = "Keep the app loaded at all times"
  type        = bool
  default     = true
}

variable "api_definition_url" {
  description = "URL of the API definition"
  type        = string
  default     = null
}

variable "api_management_api_id" {
  description = "API Management API ID"
  type        = string
  default     = null
}

variable "app_command_line" {
  description = "App command line to launch"
  type        = string
  default     = null
}

variable "auto_heal_enabled" {
  description = "Enable auto heal"
  type        = bool
  default     = false
}

variable "container_registry_managed_identity_client_id" {
  description = "Client ID of the managed identity for container registry"
  type        = string
  default     = null
}

variable "container_registry_use_managed_identity" {
  description = "Use managed identity for container registry"
  type        = bool
  default     = false
}

variable "cors" {
  description = "CORS configuration"
  type = object({
    allowed_origins     = list(string)
    support_credentials = optional(bool, false)
  })
  default = null
}

variable "ip_restrictions" {
  description = "IP restriction rules"
  type = list(object({
    ip_address                = optional(string)
    service_tag              = optional(string)
    virtual_network_subnet_id = optional(string)
    name                     = optional(string)
    priority                 = optional(number, 100)
    action                   = optional(string, "Allow")
    headers = optional(object({
      x_azure_fdid      = optional(list(string))
      x_fd_health_probe = optional(list(string))
      x_forwarded_for   = optional(list(string))
      x_forwarded_host  = optional(list(string))
    }))
  }))
  default = []
}

variable "scm_ip_restrictions" {
  description = "SCM IP restriction rules"
  type = list(object({
    ip_address                = optional(string)
    service_tag              = optional(string)
    virtual_network_subnet_id = optional(string)
    name                     = optional(string)
    priority                 = optional(number, 100)
    action                   = optional(string, "Allow")
  }))
  default = []
}

variable "application_stack" {
  description = "Application stack configuration"
  type = object({
    # Linux specific
    dotnet_version      = optional(string)
    go_version         = optional(string)
    java_server        = optional(string)
    java_server_version = optional(string)
    java_version       = optional(string)
    node_version       = optional(string)
    php_version        = optional(string)
    python_version     = optional(string)
    ruby_version       = optional(string)
    
    # Windows specific
    current_stack             = optional(string)
    dotnet_core_version      = optional(string)
    tomcat_version           = optional(string)
    java_embedded_server_enabled = optional(bool)
    python                   = optional(bool)
    
    # Docker configuration
    docker = optional(object({
      image_name        = string
      image_tag         = string
      registry_url      = string
      registry_username = optional(string)
      registry_password = optional(string)
    }))
  })
  default = null
}

variable "default_documents" {
  description = "Default documents for the App Service"
  type        = list(string)
  default     = null
}

variable "ftps_state" {
  description = "State of FTP / FTPS service"
  type        = string
  default     = "Disabled"
  
  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "FTPS state must be AllAllowed, FtpsOnly, or Disabled."
  }
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = null
}

variable "health_check_eviction_time_in_min" {
  description = "Time in minutes after which unhealthy instances are removed"
  type        = number
  default     = null
}

variable "http2_enabled" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "load_balancing_mode" {
  description = "Load balancing mode"
  type        = string
  default     = "LeastRequests"
}

variable "local_mysql_enabled" {
  description = "Enable local MySQL"
  type        = bool
  default     = false
}

variable "managed_pipeline_mode" {
  description = "Managed pipeline mode"
  type        = string
  default     = "Integrated"
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "remote_debugging_enabled" {
  description = "Enable remote debugging"
  type        = bool
  default     = false
}

variable "remote_debugging_version" {
  description = "Remote debugging version"
  type        = string
  default     = null
}

variable "scm_minimum_tls_version" {
  description = "Minimum TLS version for SCM site"
  type        = string
  default     = "1.2"
}

variable "scm_use_main_ip_restriction" {
  description = "Use main IP restrictions for SCM"
  type        = bool
  default     = false
}

variable "use_32_bit_worker" {
  description = "Use 32-bit worker process"
  type        = bool
  default     = false
}

variable "vnet_route_all_enabled" {
  description = "Route all traffic through VNet"
  type        = bool
  default     = false
}

variable "websockets_enabled" {
  description = "Enable WebSockets"
  type        = bool
  default     = false
}

# Auto Heal Configuration
variable "auto_heal_setting" {
  description = "Auto heal configuration"
  type = object({
    action = optional(object({
      action_type                    = string
      minimum_process_execution_time = optional(string)
      custom_action = optional(object({
        executable = string
        parameters = optional(string)
      }))
    }))
    trigger = optional(object({
      requests = optional(object({
        count    = number
        interval = string
      }))
      slow_request = optional(object({
        count      = number
        interval   = string
        time_taken = string
        path       = optional(string)
      }))
      status_code = optional(list(object({
        count             = number
        interval          = string
        status_code_range = string
        path              = optional(string)
        sub_status        = optional(number)
        win32_status_code = optional(number)
      })), [])
    }))
  })
  default = null
}

# Application Settings
variable "app_settings" {
  description = "Application settings for the App Service"
  type        = map(string)
  default     = {}
}

# Connection Strings
variable "connection_strings" {
  description = "Connection strings for the App Service"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

# Authentication v2
variable "auth_settings_v2" {
  description = "Authentication v2 settings"
  type = object({
    auth_enabled                            = bool
    runtime_version                         = optional(string)
    config_file_path                        = optional(string)
    require_authentication                  = optional(bool)
    unauthenticated_action                 = optional(string)
    default_provider                       = optional(string)
    excluded_paths                         = optional(list(string))
    require_https                          = optional(bool)
    http_route_api_prefix                  = optional(string)
    forward_proxy_convention               = optional(string)
    forward_proxy_custom_host_header_name  = optional(string)
    forward_proxy_custom_scheme_header_name = optional(string)
    
    login = optional(object({
      logout_endpoint                   = optional(string)
      token_store_enabled              = optional(bool)
      token_refresh_extension_hours    = optional(number)
      token_store_path                 = optional(string)
      token_store_sas_setting_name     = optional(string)
      preserve_url_fragments_for_logins = optional(bool)
      allowed_external_redirect_urls   = optional(list(string))
      cookie_expiration_convention     = optional(string)
      cookie_expiration_time           = optional(string)
      validate_nonce                   = optional(bool)
      nonce_expiration_time            = optional(string)
    }))
    
    azure_active_directory_v2 = optional(object({
      client_id                            = string
      tenant_auth_endpoint                 = optional(string)
      client_secret_setting_name           = optional(string)
      client_secret_certificate_thumbprint = optional(string)
      jwt_allowed_groups                   = optional(list(string))
      jwt_allowed_client_applications      = optional(list(string))
      www_authentication_disabled          = optional(bool)
      allowed_groups                       = optional(list(string))
      allowed_identities                   = optional(list(string))
      allowed_applications                 = optional(list(string))
      login_parameters                     = optional(map(string))
      allowed_audiences                    = optional(list(string))
    }))
  })
  default = null
}

# Backup Configuration
variable "backup" {
  description = "Backup configuration"
  type = object({
    name                = string
    enabled            = bool
    storage_account_url = string
    schedule = object({
      frequency_interval       = number
      frequency_unit          = string
      keep_at_least_one_backup = optional(bool, true)
      retention_period_days   = optional(number, 30)
      start_time             = optional(string)
    })
  })
  default = null
}

# Logs Configuration
variable "logs_configuration" {
  description = "Logs configuration"
  type = object({
    detailed_error_messages = optional(bool, false)
    failed_request_tracing  = optional(bool, false)
    
    application_logs = optional(object({
      file_system_level = optional(string, "Off")
      azure_blob_storage = optional(object({
        level             = string
        retention_in_days = number
        sas_url          = string
      }))
    }))
    
    http_logs = optional(object({
      azure_blob_storage = optional(object({
        retention_in_days = number
        sas_url          = string
      }))
      file_system = optional(object({
        retention_in_days = number
        retention_in_mb  = number
      }))
    }))
  })
  default = null
}

# Sticky Settings
variable "sticky_settings" {
  description = "Settings that stick to a slot during slot swaps"
  type = object({
    app_setting_names       = optional(list(string), [])
    connection_string_names = optional(list(string), [])
  })
  default = null
}

# Storage Accounts
variable "storage_accounts" {
  description = "Storage accounts to mount"
  type = list(object({
    access_key   = string
    account_name = string
    name         = string
    share_name   = string
    type         = string
    mount_path   = optional(string)
  }))
  default = []
}

# Security Settings
variable "https_only" {
  description = "Require HTTPS for all requests"
  type        = bool
  default     = true
}

variable "client_certificate_enabled" {
  description = "Enable client certificate authentication"
  type        = bool
  default     = false
}

variable "client_certificate_mode" {
  description = "Client certificate mode"
  type        = string
  default     = "Optional"
  
  validation {
    condition     = contains(["Required", "Optional"], var.client_certificate_mode)
    error_message = "Client certificate mode must be Required or Optional."
  }
}

variable "client_certificate_exclusion_paths" {
  description = "Paths to exclude from client certificate authentication"
  type        = list(string)
  default     = []
}

variable "key_vault_reference_identity_id" {
  description = "Identity ID for Key Vault reference"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "zip_deploy_file" {
  description = "ZIP deploy file path"
  type        = string
  default     = null
}

# Deployment Slot
variable "enable_staging_slot" {
  description = "Enable staging deployment slot"
  type        = bool
  default     = false
}

# Diagnostic Settings
variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
  type = object({
    enabled_logs = list(string)
    metrics      = list(string)
  })
  default = {
    enabled_logs = [
      "AppServiceHTTPLogs",
      "AppServiceConsoleLogs",
      "AppServiceAppLogs",
      "AppServiceFileAuditLogs",
      "AppServiceAuditLogs"
    ]
    metrics = [
      "AllMetrics"
    ]
  }
}