# =============================================================================
# AZURE WEB APPLICATION MODULE - VARIABLES
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the web application"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$", var.name))
    error_message = "Web app name must be between 3 and 60 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# =============================================================================
# APP SERVICE PLAN CONFIGURATION
# =============================================================================

variable "os_type" {
  description = "Operating system type for the App Service Plan"
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
  default     = "B1"
  
  validation {
    condition = can(regex("^(F1|D1|B[1-3]|S[1-3]|P[1-3]V[2-3]|P[1-3]v[2-3]|I[1-3]v[2]|EP[1-3]|WS[1-3]|Y1)$", var.sku_name))
    error_message = "SKU name must be a valid App Service Plan SKU (e.g., F1, D1, B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2, etc.)."
  }
}

variable "worker_count" {
  description = "Number of workers for the App Service Plan"
  type        = number
  default     = 1
  
  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 30
    error_message = "Worker count must be between 1 and 30."
  }
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for the App Service Plan"
  type        = bool
  default     = false
}

variable "per_site_scaling_enabled" {
  description = "Enable per site scaling for the App Service Plan"
  type        = bool
  default     = false
}

# =============================================================================
# WEB APP CONFIGURATION
# =============================================================================

variable "enabled" {
  description = "Enable the web app"
  type        = bool
  default     = true
}

variable "client_affinity_enabled" {
  description = "Enable client affinity"
  type        = bool
  default     = false
}

variable "client_certificate_enabled" {
  description = "Enable client certificates"
  type        = bool
  default     = false
}

variable "client_certificate_mode" {
  description = "Client certificate mode"
  type        = string
  default     = "Required"
  
  validation {
    condition     = contains(["Required", "Optional", "OptionalInteractiveUser"], var.client_certificate_mode)
    error_message = "Client certificate mode must be 'Required', 'Optional', or 'OptionalInteractiveUser'."
  }
}

variable "https_only" {
  description = "Force HTTPS only"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "virtual_network_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

# =============================================================================
# IDENTITY CONFIGURATION
# =============================================================================

variable "enable_managed_identity" {
  description = "Enable managed identity for the web app"
  type        = bool
  default     = false
}

variable "identity_type" {
  description = "Type of managed identity"
  type        = string
  default     = "SystemAssigned"
  
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'."
  }
}

variable "user_assigned_identity_ids" {
  description = "List of user assigned identity IDs"
  type        = list(string)
  default     = []
}

# =============================================================================
# SITE CONFIGURATION
# =============================================================================

variable "always_on" {
  description = "Enable always on"
  type        = bool
  default     = true
}

variable "api_definition_url" {
  description = "API definition URL"
  type        = string
  default     = null
}

variable "api_management_api_id" {
  description = "API Management API ID"
  type        = string
  default     = null
}

variable "app_command_line" {
  description = "App command line"
  type        = string
  default     = null
}

variable "auto_heal_enabled" {
  description = "Enable auto heal"
  type        = bool
  default     = false
}

variable "container_registry_use_managed_identity" {
  description = "Use managed identity for container registry"
  type        = bool
  default     = false
}

variable "container_registry_managed_identity_client_id" {
  description = "Managed identity client ID for container registry"
  type        = string
  default     = null
}

variable "default_documents" {
  description = "List of default documents"
  type        = list(string)
  default     = ["Default.htm", "Default.html", "Default.asp", "index.htm", "index.html", "iisstart.htm", "default.aspx", "index.php"]
}

variable "ftps_state" {
  description = "FTPS state"
  type        = string
  default     = "Disabled"
  
  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "FTPS state must be 'AllAllowed', 'FtpsOnly', or 'Disabled'."
  }
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = null
}

variable "health_check_eviction_time_in_min" {
  description = "Health check eviction time in minutes"
  type        = number
  default     = null
  
  validation {
    condition     = var.health_check_eviction_time_in_min == null || (var.health_check_eviction_time_in_min >= 2 && var.health_check_eviction_time_in_min <= 10)
    error_message = "Health check eviction time must be between 2 and 10 minutes."
  }
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
  
  validation {
    condition     = contains(["WeightedRoundRobin", "LeastRequests", "LeastResponseTime", "WeightedTotalTraffic", "RequestHash", "PerSiteRoundRobin"], var.load_balancing_mode)
    error_message = "Load balancing mode must be a valid option."
  }
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
  
  validation {
    condition     = contains(["Integrated", "Classic"], var.managed_pipeline_mode)
    error_message = "Managed pipeline mode must be 'Integrated' or 'Classic'."
  }
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
  
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be '1.0', '1.1', or '1.2'."
  }
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
  
  validation {
    condition = var.remote_debugging_version == null || contains(["VS2017", "VS2019", "VS2022"], var.remote_debugging_version)
    error_message = "Remote debugging version must be 'VS2017', 'VS2019', or 'VS2022'."
  }
}

variable "scm_minimum_tls_version" {
  description = "SCM minimum TLS version"
  type        = string
  default     = "1.2"
  
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.scm_minimum_tls_version)
    error_message = "SCM minimum TLS version must be '1.0', '1.1', or '1.2'."
  }
}

variable "scm_use_main_ip_restriction" {
  description = "Use main IP restriction for SCM"
  type        = bool
  default     = false
}

variable "use_32_bit_worker" {
  description = "Use 32-bit worker"
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

# =============================================================================
# APPLICATION STACK
# =============================================================================

variable "application_stack" {
  description = "Application stack configuration for Linux"
  type = object({
    docker_image        = optional(string)
    docker_image_tag    = optional(string)
    dotnet_version      = optional(string)
    go_version         = optional(string)
    java_server        = optional(string)
    java_server_version = optional(string)
    java_version       = optional(string)
    node_version       = optional(string)
    php_version        = optional(string)
    python_version     = optional(string)
    ruby_version       = optional(string)
  })
  default = null
}

variable "windows_application_stack" {
  description = "Application stack configuration for Windows"
  type = object({
    current_stack             = optional(string)
    docker_container_name     = optional(string)
    docker_container_registry = optional(string)
    docker_container_tag      = optional(string)
    dotnet_version           = optional(string)
    java_container           = optional(string)
    java_container_version   = optional(string)
    java_version             = optional(string)
    node_version             = optional(string)
    php_version              = optional(string)
    python_version           = optional(string)
  })
  default = null
}

# =============================================================================
# AUTO HEAL CONFIGURATION
# =============================================================================

variable "auto_heal_setting" {
  description = "Auto heal settings"
  type = object({
    action = optional(object({
      action_type                    = string
      minimum_process_execution_time = optional(string)
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
        status_code_range = string
        count            = number
        interval         = string
        path             = optional(string)
        sub_status       = optional(number)
        win32_status     = optional(number)
      })))
    }))
  })
  default = null
}

# =============================================================================
# CORS CONFIGURATION
# =============================================================================

variable "cors_configuration" {
  description = "CORS configuration"
  type = object({
    allowed_origins     = list(string)
    support_credentials = optional(bool, false)
  })
  default = null
}

# =============================================================================
# IP RESTRICTIONS
# =============================================================================

variable "ip_restrictions" {
  description = "List of IP restrictions"
  type = list(object({
    ip_address                = optional(string)
    service_tag              = optional(string)
    virtual_network_subnet_id = optional(string)
    name                     = optional(string)
    priority                 = optional(number)
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
  description = "List of SCM IP restrictions"
  type = list(object({
    ip_address                = optional(string)
    service_tag              = optional(string)
    virtual_network_subnet_id = optional(string)
    name                     = optional(string)
    priority                 = optional(number)
    action                   = optional(string, "Allow")
  }))
  default = []
}

# =============================================================================
# APPLICATION SETTINGS
# =============================================================================

variable "app_settings" {
  description = "Application settings"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection strings"
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}

variable "sticky_settings" {
  description = "Sticky settings"
  type = object({
    app_setting_names       = optional(list(string))
    connection_string_names = optional(list(string))
  })
  default = null
}

# =============================================================================
# STORAGE ACCOUNTS
# =============================================================================

variable "storage_accounts" {
  description = "Storage account configurations"
  type = map(object({
    type         = string
    account_name = string
    share_name   = string
    access_key   = string
    mount_path   = optional(string)
  }))
  default = {}
}

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================

variable "backup_configuration" {
  description = "Backup configuration"
  type = object({
    name                = string
    enabled             = bool
    storage_account_url = string
    schedule = optional(object({
      frequency_interval       = number
      frequency_unit          = string
      keep_at_least_one_backup = optional(bool, true)
      retention_period_days    = optional(number, 30)
      start_time              = optional(string)
    }))
  })
  default = null
}

# =============================================================================
# AUTHENTICATION
# =============================================================================

variable "enable_authentication" {
  description = "Enable authentication"
  type        = bool
  default     = false
}

variable "auth_settings" {
  description = "Authentication settings"
  type = object({
    enabled                        = bool
    default_provider              = optional(string)
    allowed_external_redirect_urls = optional(list(string))
    issuer                        = optional(string)
    runtime_version               = optional(string)
    token_refresh_extension_hours = optional(number)
    token_store_enabled          = optional(bool)
    unauthenticated_client_action = optional(string)
    active_directory = optional(object({
      client_id         = string
      client_secret     = optional(string)
      allowed_audiences = optional(list(string))
    }))
  })
  default = {
    enabled = false
  }
}

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

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
        retention_in_mb   = number
      }))
    }))
  })
  default = null
}

# =============================================================================
# CUSTOM DOMAINS
# =============================================================================

variable "custom_domains" {
  description = "Custom domain configurations"
  type = map(object({
    ssl_state  = optional(string, "Disabled")
    thumbprint = optional(string)
  }))
  default = {}
}

# =============================================================================
# APPLICATION INSIGHTS
# =============================================================================

variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = false
}

variable "application_insights_type" {
  description = "Application Insights application type"
  type        = string
  default     = "web"
  
  validation {
    condition     = contains(["web", "java", "MobileCenter", "Node.JS", "other"], var.application_insights_type)
    error_message = "Application Insights type must be 'web', 'java', 'MobileCenter', 'Node.JS', or 'other'."
  }
}

# =============================================================================
# PRIVATE ENDPOINT
# =============================================================================

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
  default     = null
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
  type = object({
    logs = optional(list(string), [
      "AppServiceAppLogs",
      "AppServiceAuditLogs",
      "AppServiceConsoleLogs",
      "AppServiceHTTPLogs",
      "AppServiceIPSecAuditLogs",
      "AppServicePlatformLogs"
    ])
    metrics = optional(list(string), [
      "AllMetrics"
    ])
  })
  default = {
    logs    = ["AppServiceAppLogs", "AppServiceAuditLogs", "AppServiceConsoleLogs", "AppServiceHTTPLogs", "AppServiceIPSecAuditLogs", "AppServicePlatformLogs"]
    metrics = ["AllMetrics"]
  }
}

# =============================================================================
# TAGS
# =============================================================================

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}