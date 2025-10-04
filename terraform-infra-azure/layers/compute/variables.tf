# =============================================================================
# COMPUTE LAYER - VARIABLES
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$", var.project_name))
    error_message = "Project name must be between 3 and 60 characters, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod", "qa", "uat"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, qa, uat."
  }
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

# =============================================================================
# REMOTE STATE CONFIGURATION
# =============================================================================

variable "security_state_config" {
  description = "Configuration for security layer remote state"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
  })
}

variable "networking_state_config" {
  description = "Configuration for networking layer remote state"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
  })
}

variable "data_state_config" {
  description = "Configuration for data layer remote state"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
  })
}

# =============================================================================
# AKS CLUSTER CONFIGURATION
# =============================================================================

variable "enable_aks" {
  description = "Enable AKS cluster deployment"
  type        = bool
  default     = false
}

variable "aks_clusters" {
  description = "Map of AKS cluster configurations"
  type = map(object({
    kubernetes_version   = optional(string, "1.27")
    node_pools = map(object({
      vm_size             = string
      node_count          = number
      max_node_count      = optional(number)
      min_node_count      = optional(number)
      enable_auto_scaling = optional(bool, false)
      max_pods            = optional(number, 110)
      os_disk_size_gb     = optional(number, 128)
      os_disk_type        = optional(string, "Managed")
      ultra_ssd_enabled   = optional(bool, false)
      zones               = optional(list(string), [])
      node_labels         = optional(map(string), {})
      node_taints         = optional(list(string), [])
    }))
    
    # Network configuration
    network_plugin      = optional(string, "azure")
    network_policy      = optional(string, "azure")
    dns_service_ip      = optional(string, "10.0.0.10")
    service_cidr        = optional(string, "10.0.0.0/16")
    pod_cidr           = optional(string)
    
    # Security configuration
    enable_rbac                    = optional(bool, true)
    enable_azure_policy           = optional(bool, true)
    enable_secret_rotation        = optional(bool, true)
    enable_workload_identity      = optional(bool, true)
    
    # Monitoring
    enable_log_analytics_workspace = optional(bool, true)
    
    # Add-ons
    enable_http_application_routing = optional(bool, false)
    enable_azure_keyvault_secrets_provider = optional(bool, true)
    enable_azure_defender = optional(bool, true)
  }))
  default = {}
}

# =============================================================================
# FUNCTION APP CONFIGURATION
# =============================================================================

variable "enable_function_apps" {
  description = "Enable Function App deployment"
  type        = bool
  default     = false
}

variable "function_apps" {
  description = "Map of Function App configurations"
  type = map(object({
    # Service Plan Configuration
    os_type                = optional(string, "Linux")
    sku_name              = optional(string, "Y1")
    worker_count          = optional(number, 1)
    per_site_scaling      = optional(bool, false)
    zone_balancing_enabled = optional(bool, false)
    
    # Runtime Configuration
    runtime_stack = object({
      dotnet_version      = optional(string)
      java_version       = optional(string)
      node_version       = optional(string)
      python_version     = optional(string)
      powershell_core_version = optional(string)
      use_custom_runtime = optional(bool, false)
    })
    
    # Application Settings
    app_settings = optional(map(string), {})
    
    # Connection Strings
    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})
    
    # Storage Configuration
    storage_account = optional(object({
      account_tier             = string
      account_replication_type = string
      account_kind            = optional(string, "StorageV2")
      access_tier             = optional(string, "Hot")
    }), {
      account_tier             = "Standard"
      account_replication_type = "LRS"
    })
    
    # Security Configuration
    https_only = optional(bool, true)
    
    # Identity Configuration
    enable_system_assigned_identity = optional(bool, true)
    
    # Monitoring Configuration
    enable_application_insights = optional(bool, true)
  }))
  default = {}
}

# =============================================================================
# WEB APP CONFIGURATION
# =============================================================================

variable "enable_web_apps" {
  description = "Enable Web App deployment"
  type        = bool
  default     = false
}

variable "web_apps" {
  description = "Map of Web App configurations"
  type = map(object({
    # App Service Plan Configuration
    os_type                      = optional(string, "Linux")
    sku_name                    = optional(string, "B1")
    worker_count                = optional(number, 1)
    enable_zone_redundancy      = optional(bool, false)
    per_site_scaling_enabled    = optional(bool, false)
    
    # Application Stack Configuration
    application_stack = optional(object({
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
    }))
    
    windows_application_stack = optional(object({
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
    }))
    
    # Security Configuration
    https_only                    = optional(bool, true)
    client_certificate_enabled   = optional(bool, false)
    client_certificate_mode      = optional(string, "Required")
    public_network_access_enabled = optional(bool, true)
    minimum_tls_version          = optional(string, "1.2")
    
    # Site Configuration
    always_on                = optional(bool, true)
    http2_enabled           = optional(bool, true)
    websockets_enabled      = optional(bool, false)
    ftps_state             = optional(string, "Disabled")
    health_check_path      = optional(string)
    auto_heal_enabled      = optional(bool, false)
    
    # Auto Heal Configuration
    auto_heal_setting = optional(object({
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
    }))
    
    # Application Settings
    app_settings = optional(map(string), {})
    
    # Connection Strings
    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})
    
    # CORS Configuration
    cors_configuration = optional(object({
      allowed_origins     = list(string)
      support_credentials = optional(bool, false)
    }))
    
    # IP Restrictions
    ip_restrictions = optional(list(object({
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
    })), [])
    
    # Custom Domains
    custom_domains = optional(map(object({
      ssl_state  = optional(string, "Disabled")
      thumbprint = optional(string)
    })), {})
    
    # Identity Configuration
    enable_managed_identity = optional(bool, true)
    identity_type          = optional(string, "SystemAssigned")
    
    # Monitoring Configuration
    enable_application_insights = optional(bool, true)
    application_insights_type   = optional(string, "web")
    
    # Backup Configuration
    backup_configuration = optional(object({
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
    }))
    
    # Authentication Configuration
    enable_authentication = optional(bool, false)
    auth_settings = optional(object({
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
    }))
  }))
  default = {}
}

# =============================================================================
# APP SERVICE CONFIGURATION (Legacy)
# =============================================================================

variable "enable_app_services" {
  description = "Enable App Service deployment (legacy module)"
  type        = bool
  default     = false
}

variable "app_services" {
  description = "Map of App Service configurations (legacy module)"
  type = map(object({
    os_type      = string
    sku_name     = string
    worker_count = optional(number, 1)
    
    application_stack = optional(object({
      dotnet_version      = optional(string)
      java_version       = optional(string)
      node_version       = optional(string)
      php_version        = optional(string)
      python_version     = optional(string)
      ruby_version       = optional(string)
      go_version         = optional(string)
      docker_image       = optional(string)
      docker_image_tag   = optional(string)
    }))
    
    app_settings       = optional(map(string), {})
    connection_strings = optional(map(object({
      type  = string
      value = string
    })), {})
    
    always_on                   = optional(bool, true)
    health_check_path          = optional(string)
    auto_heal_enabled          = optional(bool, false)
    auto_heal_setting          = optional(any)
    client_certificate_enabled = optional(bool, false)
    enable_staging_slot        = optional(bool, false)
  }))
  default = {}
}

# =============================================================================
# CONTAINER INSTANCE CONFIGURATION
# =============================================================================

variable "enable_container_instances" {
  description = "Enable Container Instance deployment"
  type        = bool
  default     = false
}

variable "container_instances" {
  description = "Map of Container Instance configurations"
  type = map(object({
    # Container Configuration
    containers = list(object({
      name   = string
      image  = string
      cpu    = number
      memory = number
      
      # Ports
      ports = optional(list(object({
        port     = number
        protocol = optional(string, "TCP")
      })), [])
      
      # Environment Variables
      environment_variables = optional(map(string), {})
      secure_environment_variables = optional(map(string), {})
      
      # Volume Mounts
      volume_mounts = optional(list(object({
        name       = string
        mount_path = string
        read_only  = optional(bool, false)
      })), [])
      
      # Liveness Probe
      liveness_probe = optional(object({
        exec                = optional(list(string))
        http_get           = optional(object({
          path   = string
          port   = number
          scheme = optional(string, "HTTP")
        }))
        initial_delay_seconds = optional(number, 0)
        period_seconds       = optional(number, 10)
        failure_threshold    = optional(number, 3)
        success_threshold    = optional(number, 1)
        timeout_seconds      = optional(number, 1)
      }))
      
      # Readiness Probe
      readiness_probe = optional(object({
        exec                = optional(list(string))
        http_get           = optional(object({
          path   = string
          port   = number
          scheme = optional(string, "HTTP")
        }))
        initial_delay_seconds = optional(number, 0)
        period_seconds       = optional(number, 10)
        failure_threshold    = optional(number, 3)
        success_threshold    = optional(number, 1)
        timeout_seconds      = optional(number, 1)
      }))
    }))
    
    # Network Configuration
    os_type           = optional(string, "Linux")
    restart_policy    = optional(string, "Always")
    ip_address_type   = optional(string, "Private")
    exposed_ports = optional(list(object({
      port     = number
      protocol = optional(string, "TCP")
    })), [])
    
    # DNS Configuration
    dns_name_label = optional(string)
    
    # Volume Configuration
    volumes = optional(list(object({
      name = string
      type = string
      
      # Azure File Share
      azure_file_share = optional(object({
        share_name           = string
        storage_account_name = string
        storage_account_key  = string
      }))
      
      # Empty Dir
      empty_dir = optional(object({}))
      
      # Git Repo
      git_repo = optional(object({
        url       = string
        directory = optional(string)
        revision  = optional(string)
      }))
      
      # Secret
      secret = optional(map(string))
    })), [])
    
    # Identity Configuration
    enable_system_assigned_identity = optional(bool, false)
  }))
  default = {}
}

# =============================================================================
# VIRTUAL MACHINE CONFIGURATION
# =============================================================================

variable "enable_virtual_machines" {
  description = "Enable Virtual Machine deployment"
  type        = bool
  default     = false
}

variable "virtual_machines" {
  description = "Map of Virtual Machine configurations"
  type = map(object({
    # VM Configuration
    vm_size               = string
    admin_username        = string
    disable_password_authentication = optional(bool, true)
    
    # OS Configuration
    os_disk = object({
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
      disk_size_gb         = optional(number)
    })
    
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    
    # Custom Image
    source_image_id = optional(string)
    
    # Network Configuration
    network_interface = object({
      enable_accelerated_networking = optional(bool, false)
      enable_ip_forwarding         = optional(bool, false)
      
      ip_configuration = object({
        private_ip_address_allocation = optional(string, "Dynamic")
        private_ip_address           = optional(string)
        public_ip_address_id         = optional(string)
      })
    })
    
    # Data Disks
    data_disks = optional(list(object({
      name                 = string
      disk_size_gb         = number
      storage_account_type = optional(string, "Premium_LRS")
      caching             = optional(string, "ReadWrite")
      create_option       = optional(string, "Empty")
      lun                 = number
    })), [])
    
    # Extensions
    extensions = optional(list(object({
      name                 = string
      publisher            = string
      type                 = string
      type_handler_version = string
      settings             = optional(string, "{}")
      protected_settings   = optional(string, "{}")
    })), [])
    
    # Availability Configuration
    availability_set_id = optional(string)
    zone               = optional(string)
    
    # Identity Configuration
    enable_system_assigned_identity = optional(bool, false)
    
    # Boot Diagnostics
    enable_boot_diagnostics = optional(bool, true)
  }))
  default = {}
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "enable_private_endpoints" {
  description = "Enable private endpoints for supported services"
  type        = bool
  default     = true
}

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for all resources"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring and Application Insights"
  type        = bool
  default     = true
}

# =============================================================================
# TAGS
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}