# =============================================================================
# AZURE FUNCTION APP MODULE
# =============================================================================

# Storage Account for Function App
resource "azurerm_storage_account" "function" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                = var.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
  
  # Security settings
  enable_https_traffic_only      = true
  min_tls_version               = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled     = true

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "function" {
  count = var.enable_application_insights ? 1 : 0

  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"

  tags = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location           = var.location
  os_type            = var.os_type
  sku_name           = var.sku_name

  # Zone redundancy
  zone_balancing_enabled = var.zone_balancing_enabled

  # Worker count for non-consumption plans
  worker_count = var.sku_name != "Y1" ? var.worker_count : null

  tags = var.tags
}

# Function App
resource "azurerm_linux_function_app" "main" {
  count = var.os_type == "Linux" ? 1 : 0

  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location           = var.location
  service_plan_id    = azurerm_service_plan.main.id

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  # Network configuration
  virtual_network_subnet_id = var.subnet_id
  
  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  # Site configuration
  site_config {
    always_on                              = var.always_on
    api_definition_url                     = var.api_definition_url
    api_management_api_id                  = var.api_management_api_id
    app_command_line                       = var.app_command_line
    application_insights_connection_string = var.enable_application_insights ? azurerm_application_insights.function[0].connection_string : null
    application_insights_key              = var.enable_application_insights ? azurerm_application_insights.function[0].instrumentation_key : null
    
    # CORS
    dynamic "cors" {
      for_each = var.cors != null ? [var.cors] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    # IP restrictions
    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        ip_address                = ip_restriction.value.ip_address
        service_tag              = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        name                     = ip_restriction.value.name
        priority                 = ip_restriction.value.priority
        action                   = ip_restriction.value.action

        dynamic "headers" {
          for_each = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }

    # SCM IP restrictions
    dynamic "scm_ip_restriction" {
      for_each = var.scm_ip_restrictions
      content {
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag              = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
        name                     = scm_ip_restriction.value.name
        priority                 = scm_ip_restriction.value.priority
        action                   = scm_ip_restriction.value.action
      }
    }

    # Application stack
    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
        java_version               = application_stack.value.java_version
        node_version               = application_stack.value.node_version
        python_version             = application_stack.value.python_version
        powershell_core_version    = application_stack.value.powershell_core_version
        use_custom_runtime         = application_stack.value.use_custom_runtime

        dynamic "docker" {
          for_each = application_stack.value.docker != null ? [application_stack.value.docker] : []
          content {
            registry_url      = docker.value.registry_url
            image_name        = docker.value.image_name
            image_tag         = docker.value.image_tag
            registry_username = docker.value.registry_username
            registry_password = docker.value.registry_password
          }
        }
      }
    }

    # Additional settings
    default_documents                    = var.default_documents
    elastic_instance_minimum            = var.elastic_instance_minimum
    ftps_state                         = var.ftps_state
    health_check_path                  = var.health_check_path
    health_check_eviction_time_in_min  = var.health_check_eviction_time_in_min
    http2_enabled                      = var.http2_enabled
    load_balancing_mode               = var.load_balancing_mode
    managed_pipeline_mode             = var.managed_pipeline_mode
    minimum_tls_version               = var.minimum_tls_version
    pre_warmed_instance_count         = var.pre_warmed_instance_count
    remote_debugging_enabled          = var.remote_debugging_enabled
    remote_debugging_version          = var.remote_debugging_version
    runtime_scale_monitoring_enabled  = var.runtime_scale_monitoring_enabled
    scm_minimum_tls_version          = var.scm_minimum_tls_version
    scm_use_main_ip_restriction      = var.scm_use_main_ip_restriction
    use_32_bit_worker                = var.use_32_bit_worker
    vnet_route_all_enabled           = var.vnet_route_all_enabled
    websockets_enabled               = var.websockets_enabled
  }

  # App settings
  app_settings = var.app_settings

  # Backup configuration
  dynamic "backup" {
    for_each = var.backup != null ? [var.backup] : []
    content {
      name                = backup.value.name
      enabled            = backup.value.enabled
      storage_account_url = backup.value.storage_account_url

      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit          = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = backup.value.schedule.keep_at_least_one_backup
        retention_period_days   = backup.value.schedule.retention_period_days
        start_time             = backup.value.schedule.start_time
      }
    }
  }

  # Connection strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Sticky settings
  dynamic "sticky_settings" {
    for_each = var.sticky_settings != null ? [var.sticky_settings] : []
    content {
      app_setting_names       = sticky_settings.value.app_setting_names
      connection_string_names = sticky_settings.value.connection_string_names
    }
  }

  # Authentication
  dynamic "auth_settings" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      enabled                        = auth_settings.value.enabled
      additional_login_parameters    = auth_settings.value.additional_login_parameters
      allowed_external_redirect_urls = auth_settings.value.allowed_external_redirect_urls
      default_provider              = auth_settings.value.default_provider
      issuer                        = auth_settings.value.issuer
      runtime_version               = auth_settings.value.runtime_version
      token_refresh_extension_hours = auth_settings.value.token_refresh_extension_hours
      token_store_enabled           = auth_settings.value.token_store_enabled
      unauthenticated_client_action = auth_settings.value.unauthenticated_client_action

      dynamic "active_directory" {
        for_each = auth_settings.value.active_directory != null ? [auth_settings.value.active_directory] : []
        content {
          client_id         = active_directory.value.client_id
          client_secret     = active_directory.value.client_secret
          allowed_audiences = active_directory.value.allowed_audiences
        }
      }
    }
  }

  # HTTPS only
  https_only = var.https_only

  # Client certificate settings
  client_certificate_enabled           = var.client_certificate_enabled
  client_certificate_mode             = var.client_certificate_mode
  client_certificate_exclusion_paths  = var.client_certificate_exclusion_paths

  # Built-in logging
  builtin_logging_enabled = var.builtin_logging_enabled

  # Content share force disabled
  content_share_force_disabled = var.content_share_force_disabled

  # Daily memory time quota
  daily_memory_time_quota = var.daily_memory_time_quota

  # Functions extension version
  functions_extension_version = var.functions_extension_version

  # Key vault reference identity
  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Storage settings
  storage_uses_managed_identity = var.storage_uses_managed_identity
  storage_key_vault_secret_id   = var.storage_key_vault_secret_id

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Windows Function App
resource "azurerm_windows_function_app" "main" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location           = var.location
  service_plan_id    = azurerm_service_plan.main.id

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  # Network configuration
  virtual_network_subnet_id = var.subnet_id

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  # Site configuration
  site_config {
    always_on                              = var.always_on
    api_definition_url                     = var.api_definition_url
    api_management_api_id                  = var.api_management_api_id
    app_command_line                       = var.app_command_line
    application_insights_connection_string = var.enable_application_insights ? azurerm_application_insights.function[0].connection_string : null
    application_insights_key              = var.enable_application_insights ? azurerm_application_insights.function[0].instrumentation_key : null

    # Application stack for Windows
    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
        java_version               = application_stack.value.java_version
        node_version               = application_stack.value.node_version
        powershell_core_version    = application_stack.value.powershell_core_version
        use_custom_runtime         = application_stack.value.use_custom_runtime
      }
    }

    # Similar configuration as Linux function app...
    default_documents                    = var.default_documents
    elastic_instance_minimum            = var.elastic_instance_minimum
    ftps_state                         = var.ftps_state
    health_check_path                  = var.health_check_path
    health_check_eviction_time_in_min  = var.health_check_eviction_time_in_min
    http2_enabled                      = var.http2_enabled
    load_balancing_mode               = var.load_balancing_mode
    managed_pipeline_mode             = var.managed_pipeline_mode
    minimum_tls_version               = var.minimum_tls_version
    pre_warmed_instance_count         = var.pre_warmed_instance_count
    remote_debugging_enabled          = var.remote_debugging_enabled
    remote_debugging_version          = var.remote_debugging_version
    runtime_scale_monitoring_enabled  = var.runtime_scale_monitoring_enabled
    scm_minimum_tls_version          = var.scm_minimum_tls_version
    scm_use_main_ip_restriction      = var.scm_use_main_ip_restriction
    use_32_bit_worker                = var.use_32_bit_worker
    vnet_route_all_enabled           = var.vnet_route_all_enabled
    websockets_enabled               = var.websockets_enabled
  }

  # App settings
  app_settings = var.app_settings

  # Connection strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # HTTPS only
  https_only = var.https_only

  # Client certificate settings
  client_certificate_enabled           = var.client_certificate_enabled
  client_certificate_mode             = var.client_certificate_mode
  client_certificate_exclusion_paths  = var.client_certificate_exclusion_paths

  # Built-in logging
  builtin_logging_enabled = var.builtin_logging_enabled

  # Daily memory time quota
  daily_memory_time_quota = var.daily_memory_time_quota

  # Functions extension version
  functions_extension_version = var.functions_extension_version

  # Key vault reference identity
  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Storage settings
  storage_uses_managed_identity = var.storage_uses_managed_identity
  storage_key_vault_secret_id   = var.storage_key_vault_secret_id

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Function App Slot (for staging deployments)
resource "azurerm_linux_function_app_slot" "staging" {
  count = var.os_type == "Linux" && var.enable_staging_slot ? 1 : 0

  name           = "staging"
  function_app_id = azurerm_linux_function_app.main[0].id

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  site_config {
    always_on = var.always_on
    
    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
        java_version               = application_stack.value.java_version
        node_version               = application_stack.value.node_version
        python_version             = application_stack.value.python_version
        powershell_core_version    = application_stack.value.powershell_core_version
        use_custom_runtime         = application_stack.value.use_custom_runtime
      }
    }
  }

  app_settings = merge(var.app_settings, {
    "STAGING_SLOT" = "true"
  })

  tags = var.tags
}

# Private Endpoint (if enabled)
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.function_app_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.function_app_name}-psc"
    private_connection_resource_id = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
    subresource_names             = ["sites"]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name               = "${var.function_app_name}-diagnostics"
  target_resource_id = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.enabled_logs
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}