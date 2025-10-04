# =============================================================================
# FUNCTION APP MODULE VARIABLES
# =============================================================================

# Basic Configuration
variable "function_app_name" {
  description = "Name of the Function App"
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

# Storage Account
variable "storage_account_name" {
  description = "Name of the storage account for the Function App"
  type        = string
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
  default     = "Y1"  # Consumption plan
}

variable "zone_balancing_enabled" {
  description = "Enable zone balancing for the App Service Plan"
  type        = bool
  default     = false
}

variable "worker_count" {
  description = "Number of workers for non-consumption plans"
  type        = number
  default     = 1
}

# Network Configuration
variable "subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the Function App"
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

# Application Insights
variable "enable_application_insights" {
  description = "Enable Application Insights for the Function App"
  type        = bool
  default     = true
}

variable "application_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Application Insights"
  type        = string
  default     = null
}

# Site Configuration
variable "always_on" {
  description = "Keep the function app loaded at all times"
  type        = bool
  default     = false
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
    dotnet_version              = optional(string)
    use_dotnet_isolated_runtime = optional(bool, false)
    java_version               = optional(string)
    node_version               = optional(string)
    python_version             = optional(string)
    powershell_core_version    = optional(string)
    use_custom_runtime         = optional(bool, false)
    docker = optional(object({
      registry_url      = string
      image_name        = string
      image_tag         = string
      registry_username = optional(string)
      registry_password = optional(string)
    }))
  })
  default = null
}

variable "default_documents" {
  description = "Default documents for the Function App"
  type        = list(string)
  default     = null
}

variable "elastic_instance_minimum" {
  description = "Minimum number of elastic instances"
  type        = number
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

variable "pre_warmed_instance_count" {
  description = "Number of pre-warmed instances"
  type        = number
  default     = null
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

variable "runtime_scale_monitoring_enabled" {
  description = "Enable runtime scale monitoring"
  type        = bool
  default     = true
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

# Application Settings
variable "app_settings" {
  description = "Application settings for the Function App"
  type        = map(string)
  default     = {}
}

# Connection Strings
variable "connection_strings" {
  description = "Connection strings for the Function App"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
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

# Authentication
variable "auth_settings" {
  description = "Authentication settings"
  type = object({
    enabled                        = bool
    additional_login_parameters    = optional(map(string))
    allowed_external_redirect_urls = optional(list(string))
    default_provider              = optional(string)
    issuer                        = optional(string)
    runtime_version               = optional(string)
    token_refresh_extension_hours = optional(number)
    token_store_enabled           = optional(bool)
    unauthenticated_client_action = optional(string)
    active_directory = optional(object({
      client_id         = string
      client_secret     = optional(string)
      allowed_audiences = optional(list(string))
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

# Function App Settings
variable "builtin_logging_enabled" {
  description = "Enable built-in logging"
  type        = bool
  default     = true
}

variable "content_share_force_disabled" {
  description = "Force disable content share"
  type        = bool
  default     = false
}

variable "daily_memory_time_quota" {
  description = "Daily memory time quota in MB-seconds"
  type        = number
  default     = null
}

variable "functions_extension_version" {
  description = "Functions runtime extension version"
  type        = string
  default     = "~4"
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

variable "storage_uses_managed_identity" {
  description = "Use managed identity for storage account access"
  type        = bool
  default     = false
}

variable "storage_key_vault_secret_id" {
  description = "Key Vault secret ID for storage account key"
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

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
  type = object({
    enabled_logs = list(string)
    metrics      = list(string)
  })
  default = {
    enabled_logs = [
      "FunctionAppLogs"
    ]
    metrics = [
      "AllMetrics"
    ]
  }
}