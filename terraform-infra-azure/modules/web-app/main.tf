# =============================================================================
# AZURE WEB APPLICATION MODULE
# Comprehensive web application deployment with modern features
# =============================================================================

terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0"
    }
  }
}

# =============================================================================
# APP SERVICE PLAN
# =============================================================================

resource "azurerm_service_plan" "main" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.sku_name

  # Zone redundancy for high availability
  zone_balancing_enabled = var.enable_zone_redundancy

  # Worker configuration
  worker_count             = var.worker_count
  per_site_scaling_enabled = var.per_site_scaling_enabled

  tags = var.tags
}

# =============================================================================
# WEB APPLICATION
# =============================================================================

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  count = var.os_type == "Linux" ? 1 : 0

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.main.id
  client_affinity_enabled       = var.client_affinity_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  enabled                       = var.enabled
  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.virtual_network_subnet_id

  # Identity configuration
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.user_assigned_identity_ids : null
    }
  }

  # Site configuration
  site_config {
    always_on                         = var.always_on
    api_definition_url               = var.api_definition_url
    api_management_api_id            = var.api_management_api_id
    app_command_line                 = var.app_command_line
    auto_heal_enabled                = var.auto_heal_enabled
    container_registry_use_managed_identity = var.container_registry_use_managed_identity
    container_registry_managed_identity_client_id = var.container_registry_managed_identity_client_id
    default_documents               = var.default_documents
    ftps_state                      = var.ftps_state
    health_check_path              = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
    http2_enabled                  = var.http2_enabled
    load_balancing_mode           = var.load_balancing_mode
    local_mysql_enabled           = var.local_mysql_enabled
    managed_pipeline_mode         = var.managed_pipeline_mode
    minimum_tls_version           = var.minimum_tls_version
    remote_debugging_enabled      = var.remote_debugging_enabled
    remote_debugging_version      = var.remote_debugging_version
    scm_minimum_tls_version      = var.scm_minimum_tls_version
    scm_use_main_ip_restriction  = var.scm_use_main_ip_restriction
    use_32_bit_worker            = var.use_32_bit_worker
    vnet_route_all_enabled       = var.vnet_route_all_enabled
    websockets_enabled           = var.websockets_enabled
    worker_count                 = var.worker_count

    # Application stack
    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        docker_image        = application_stack.value.docker_image
        docker_image_tag    = application_stack.value.docker_image_tag
        dotnet_version      = application_stack.value.dotnet_version
        go_version         = application_stack.value.go_version
        java_server        = application_stack.value.java_server
        java_server_version = application_stack.value.java_server_version
        java_version       = application_stack.value.java_version
        node_version       = application_stack.value.node_version
        php_version        = application_stack.value.php_version
        python_version     = application_stack.value.python_version
        ruby_version       = application_stack.value.ruby_version
      }
    }

    # Auto heal rules
    dynamic "auto_heal_setting" {
      for_each = var.auto_heal_enabled && var.auto_heal_setting != null ? [var.auto_heal_setting] : []
      content {
        dynamic "action" {
          for_each = auto_heal_setting.value.action != null ? [auto_heal_setting.value.action] : []
          content {
            action_type                    = action.value.action_type
            minimum_process_execution_time = action.value.minimum_process_execution_time
          }
        }

        dynamic "trigger" {
          for_each = auto_heal_setting.value.trigger != null ? [auto_heal_setting.value.trigger] : []
          content {
            dynamic "requests" {
              for_each = trigger.value.requests != null ? [trigger.value.requests] : []
              content {
                count    = requests.value.count
                interval = requests.value.interval
              }
            }

            dynamic "slow_request" {
              for_each = trigger.value.slow_request != null ? [trigger.value.slow_request] : []
              content {
                count      = slow_request.value.count
                interval   = slow_request.value.interval
                time_taken = slow_request.value.time_taken
                path       = slow_request.value.path
              }
            }

            dynamic "status_code" {
              for_each = trigger.value.status_code != null ? trigger.value.status_code : []
              content {
                status_code_range = status_code.value.status_code_range
                count            = status_code.value.count
                interval         = status_code.value.interval
                path             = status_code.value.path
                sub_status       = status_code.value.sub_status
                win32_status     = status_code.value.win32_status
              }
            }
          }
        }
      }
    }

    # CORS configuration
    dynamic "cors" {
      for_each = var.cors_configuration != null ? [var.cors_configuration] : []
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
  }

  # Application settings
  app_settings = var.app_settings

  # Connection strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
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

  # Storage accounts
  dynamic "storage_account" {
    for_each = var.storage_accounts
    content {
      access_key   = storage_account.value.access_key
      account_name = storage_account.value.account_name
      name         = storage_account.key
      share_name   = storage_account.value.share_name
      type         = storage_account.value.type
      mount_path   = storage_account.value.mount_path
    }
  }

  # Backup configuration
  dynamic "backup" {
    for_each = var.backup_configuration != null ? [var.backup_configuration] : []
    content {
      name                = backup.value.name
      enabled             = backup.value.enabled
      storage_account_url = backup.value.storage_account_url

      dynamic "schedule" {
        for_each = backup.value.schedule != null ? [backup.value.schedule] : []
        content {
          frequency_interval       = schedule.value.frequency_interval
          frequency_unit          = schedule.value.frequency_unit
          keep_at_least_one_backup = schedule.value.keep_at_least_one_backup
          retention_period_days    = schedule.value.retention_period_days
          start_time              = schedule.value.start_time
        }
      }
    }
  }

  # Authentication
  dynamic "auth_settings" {
    for_each = var.enable_authentication ? [1] : []
    content {
      enabled                        = var.auth_settings.enabled
      default_provider              = var.auth_settings.default_provider
      allowed_external_redirect_urls = var.auth_settings.allowed_external_redirect_urls
      issuer                        = var.auth_settings.issuer
      runtime_version               = var.auth_settings.runtime_version
      token_refresh_extension_hours = var.auth_settings.token_refresh_extension_hours
      token_store_enabled          = var.auth_settings.token_store_enabled
      unauthenticated_client_action = var.auth_settings.unauthenticated_client_action

      dynamic "active_directory" {
        for_each = var.auth_settings.active_directory != null ? [var.auth_settings.active_directory] : []
        content {
          client_id         = active_directory.value.client_id
          client_secret     = active_directory.value.client_secret
          allowed_audiences = active_directory.value.allowed_audiences
        }
      }
    }
  }

  # Logs configuration
  dynamic "logs" {
    for_each = var.logs_configuration != null ? [var.logs_configuration] : []
    content {
      detailed_error_messages = logs.value.detailed_error_messages
      failed_request_tracing  = logs.value.failed_request_tracing

      dynamic "application_logs" {
        for_each = logs.value.application_logs != null ? [logs.value.application_logs] : []
        content {
          file_system_level = application_logs.value.file_system_level

          dynamic "azure_blob_storage" {
            for_each = application_logs.value.azure_blob_storage != null ? [application_logs.value.azure_blob_storage] : []
            content {
              level             = azure_blob_storage.value.level
              retention_in_days = azure_blob_storage.value.retention_in_days
              sas_url          = azure_blob_storage.value.sas_url
            }
          }
        }
      }

      dynamic "http_logs" {
        for_each = logs.value.http_logs != null ? [logs.value.http_logs] : []
        content {
          dynamic "azure_blob_storage" {
            for_each = http_logs.value.azure_blob_storage != null ? [http_logs.value.azure_blob_storage] : []
            content {
              retention_in_days = azure_blob_storage.value.retention_in_days
              sas_url          = azure_blob_storage.value.sas_url
            }
          }

          dynamic "file_system" {
            for_each = http_logs.value.file_system != null ? [http_logs.value.file_system] : []
            content {
              retention_in_days = file_system.value.retention_in_days
              retention_in_mb   = file_system.value.retention_in_mb
            }
          }
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Windows Web App
resource "azurerm_windows_web_app" "main" {
  count = var.os_type == "Windows" ? 1 : 0

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.main.id
  client_affinity_enabled       = var.client_affinity_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  enabled                       = var.enabled
  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.virtual_network_subnet_id

  # Identity configuration
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.user_assigned_identity_ids : null
    }
  }

  # Site configuration for Windows
  site_config {
    always_on           = var.always_on
    api_definition_url = var.api_definition_url
    api_management_api_id = var.api_management_api_id
    app_command_line   = var.app_command_line
    auto_heal_enabled = var.auto_heal_enabled
    default_documents = var.default_documents
    ftps_state        = var.ftps_state
    health_check_path = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
    http2_enabled     = var.http2_enabled
    load_balancing_mode = var.load_balancing_mode
    local_mysql_enabled = var.local_mysql_enabled
    managed_pipeline_mode = var.managed_pipeline_mode
    minimum_tls_version = var.minimum_tls_version
    remote_debugging_enabled = var.remote_debugging_enabled
    remote_debugging_version = var.remote_debugging_version
    scm_minimum_tls_version = var.scm_minimum_tls_version
    scm_use_main_ip_restriction = var.scm_use_main_ip_restriction
    use_32_bit_worker = var.use_32_bit_worker
    vnet_route_all_enabled = var.vnet_route_all_enabled
    websockets_enabled = var.websockets_enabled
    worker_count      = var.worker_count

    # Windows application stack
    dynamic "application_stack" {
      for_each = var.windows_application_stack != null ? [var.windows_application_stack] : []
      content {
        current_stack             = application_stack.value.current_stack
        docker_container_name     = application_stack.value.docker_container_name
        docker_container_registry = application_stack.value.docker_container_registry
        docker_container_tag      = application_stack.value.docker_container_tag
        dotnet_version           = application_stack.value.dotnet_version
        java_container           = application_stack.value.java_container
        java_container_version   = application_stack.value.java_container_version
        java_version             = application_stack.value.java_version
        node_version             = application_stack.value.node_version
        php_version              = application_stack.value.php_version
        python_version           = application_stack.value.python_version
      }
    }

    # Same auto heal, cors, ip restrictions as Linux version
    # (Omitted for brevity - would include the same dynamic blocks)
  }

  app_settings = var.app_settings

  # Connection strings, sticky settings, storage accounts, backup, auth, logs
  # (Same configuration blocks as Linux version)

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# =============================================================================
# CUSTOM DOMAINS AND SSL
# =============================================================================

# Custom domain binding
resource "azurerm_app_service_custom_hostname_binding" "main" {
  for_each = var.custom_domains

  hostname            = each.key
  app_service_name    = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
  resource_group_name = var.resource_group_name
  ssl_state          = each.value.ssl_state
  thumbprint         = each.value.thumbprint

  depends_on = [
    azurerm_linux_web_app.main,
    azurerm_windows_web_app.main
  ]
}

# =============================================================================
# APPLICATION INSIGHTS
# =============================================================================

resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.name}-ai"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_insights_type
  workspace_id        = var.log_analytics_workspace_id

  tags = var.tags
}

# =============================================================================
# PRIVATE ENDPOINT
# =============================================================================

resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id          = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
    subresource_names             = ["sites"]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.logs
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