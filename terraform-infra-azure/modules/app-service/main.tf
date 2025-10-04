# =============================================================================
# AZURE APP SERVICE MODULE
# =============================================================================

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location           = var.location
  os_type            = var.os_type
  sku_name           = var.sku_name

  # Zone redundancy
  zone_balancing_enabled = var.zone_balancing_enabled

  # Worker count
  worker_count = var.worker_count

  # Per site scaling
  per_site_scaling_enabled = var.per_site_scaling_enabled

  tags = var.tags
}

# Linux App Service
resource "azurerm_linux_web_app" "main" {
  count = var.os_type == "Linux" ? 1 : 0

  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location           = var.location
  service_plan_id    = azurerm_service_plan.main.id

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
    auto_heal_enabled                      = var.auto_heal_enabled
    container_registry_managed_identity_client_id = var.container_registry_managed_identity_client_id
    container_registry_use_managed_identity = var.container_registry_use_managed_identity
    default_documents                      = var.default_documents
    ftps_state                            = var.ftps_state
    health_check_path                     = var.health_check_path
    health_check_eviction_time_in_min     = var.health_check_eviction_time_in_min
    http2_enabled                         = var.http2_enabled
    load_balancing_mode                   = var.load_balancing_mode
    local_mysql_enabled                   = var.local_mysql_enabled
    managed_pipeline_mode                 = var.managed_pipeline_mode
    minimum_tls_version                   = var.minimum_tls_version
    remote_debugging_enabled              = var.remote_debugging_enabled
    remote_debugging_version              = var.remote_debugging_version
    scm_minimum_tls_version              = var.scm_minimum_tls_version
    scm_use_main_ip_restriction          = var.scm_use_main_ip_restriction
    use_32_bit_worker                    = var.use_32_bit_worker
    vnet_route_all_enabled               = var.vnet_route_all_enabled
    websockets_enabled                   = var.websockets_enabled

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
        dotnet_version      = application_stack.value.dotnet_version
        go_version         = application_stack.value.go_version
        java_server        = application_stack.value.java_server
        java_server_version = application_stack.value.java_server_version
        java_version       = application_stack.value.java_version
        node_version       = application_stack.value.node_version
        php_version        = application_stack.value.php_version
        python_version     = application_stack.value.python_version
        ruby_version       = application_stack.value.ruby_version

        dynamic "docker" {
          for_each = application_stack.value.docker != null ? [application_stack.value.docker] : []
          content {
            image_name        = docker.value.image_name
            image_tag         = docker.value.image_tag
            registry_url      = docker.value.registry_url
            registry_username = docker.value.registry_username
            registry_password = docker.value.registry_password
          }
        }
      }
    }

    # Auto heal setting
    dynamic "auto_heal_setting" {
      for_each = var.auto_heal_setting != null ? [var.auto_heal_setting] : []
      content {
        dynamic "action" {
          for_each = auto_heal_setting.value.action != null ? [auto_heal_setting.value.action] : []
          content {
            action_type                    = action.value.action_type
            minimum_process_execution_time = action.value.minimum_process_execution_time

            dynamic "custom_action" {
              for_each = action.value.custom_action != null ? [action.value.custom_action] : []
              content {
                executable = custom_action.value.executable
                parameters = custom_action.value.parameters
              }
            }
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
              for_each = trigger.value.status_code
              content {
                count             = status_code.value.count
                interval          = status_code.value.interval
                status_code_range = status_code.value.status_code_range
                path              = status_code.value.path
                sub_status        = status_code.value.sub_status
                win32_status_code = status_code.value.win32_status_code
              }
            }
          }
        }
      }
    }
  }

  # App settings
  app_settings = var.app_settings

  # Authentication
  dynamic "auth_settings_v2" {
    for_each = var.auth_settings_v2 != null ? [var.auth_settings_v2] : []
    content {
      auth_enabled                            = auth_settings_v2.value.auth_enabled
      runtime_version                         = auth_settings_v2.value.runtime_version
      config_file_path                        = auth_settings_v2.value.config_file_path
      require_authentication                  = auth_settings_v2.value.require_authentication
      unauthenticated_action                 = auth_settings_v2.value.unauthenticated_action
      default_provider                       = auth_settings_v2.value.default_provider
      excluded_paths                         = auth_settings_v2.value.excluded_paths
      require_https                          = auth_settings_v2.value.require_https
      http_route_api_prefix                  = auth_settings_v2.value.http_route_api_prefix
      forward_proxy_convention               = auth_settings_v2.value.forward_proxy_convention
      forward_proxy_custom_host_header_name  = auth_settings_v2.value.forward_proxy_custom_host_header_name
      forward_proxy_custom_scheme_header_name = auth_settings_v2.value.forward_proxy_custom_scheme_header_name

      dynamic "login" {
        for_each = auth_settings_v2.value.login != null ? [auth_settings_v2.value.login] : []
        content {
          logout_endpoint                   = login.value.logout_endpoint
          token_store_enabled              = login.value.token_store_enabled
          token_refresh_extension_hours    = login.value.token_refresh_extension_hours
          token_store_path                 = login.value.token_store_path
          token_store_sas_setting_name     = login.value.token_store_sas_setting_name
          preserve_url_fragments_for_logins = login.value.preserve_url_fragments_for_logins
          allowed_external_redirect_urls   = login.value.allowed_external_redirect_urls
          cookie_expiration_convention     = login.value.cookie_expiration_convention
          cookie_expiration_time           = login.value.cookie_expiration_time
          validate_nonce                   = login.value.validate_nonce
          nonce_expiration_time            = login.value.nonce_expiration_time
        }
      }

      dynamic "azure_active_directory_v2" {
        for_each = auth_settings_v2.value.azure_active_directory_v2 != null ? [auth_settings_v2.value.azure_active_directory_v2] : []
        content {
          client_id                            = azure_active_directory_v2.value.client_id
          tenant_auth_endpoint                 = azure_active_directory_v2.value.tenant_auth_endpoint
          client_secret_setting_name           = azure_active_directory_v2.value.client_secret_setting_name
          client_secret_certificate_thumbprint = azure_active_directory_v2.value.client_secret_certificate_thumbprint
          jwt_allowed_groups                   = azure_active_directory_v2.value.jwt_allowed_groups
          jwt_allowed_client_applications      = azure_active_directory_v2.value.jwt_allowed_client_applications
          www_authentication_disabled          = azure_active_directory_v2.value.www_authentication_disabled
          allowed_groups                       = azure_active_directory_v2.value.allowed_groups
          allowed_identities                   = azure_active_directory_v2.value.allowed_identities
          allowed_applications                 = azure_active_directory_v2.value.allowed_applications
          login_parameters                     = azure_active_directory_v2.value.login_parameters
          allowed_audiences                    = azure_active_directory_v2.value.allowed_audiences
        }
      }
    }
  }

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
              retention_in_mb  = file_system.value.retention_in_mb
            }
          }
        }
      }
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
      name         = storage_account.value.name
      share_name   = storage_account.value.share_name
      type         = storage_account.value.type
      mount_path   = storage_account.value.mount_path
    }
  }

  # HTTPS only
  https_only = var.https_only

  # Client certificate settings
  client_certificate_enabled           = var.client_certificate_enabled
  client_certificate_mode             = var.client_certificate_mode
  client_certificate_exclusion_paths  = var.client_certificate_exclusion_paths

  # Key vault reference identity
  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # ZIP deploy file
  zip_deploy_file = var.zip_deploy_file

  tags = var.tags
}

# Windows App Service
resource "azurerm_windows_web_app" "main" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location           = var.location
  service_plan_id    = azurerm_service_plan.main.id

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

  # Site configuration (similar to Linux but with Windows-specific settings)
  site_config {
    always_on                              = var.always_on
    api_definition_url                     = var.api_definition_url
    api_management_api_id                  = var.api_management_api_id
    app_command_line                       = var.app_command_line
    auto_heal_enabled                      = var.auto_heal_enabled
    default_documents                      = var.default_documents
    ftps_state                            = var.ftps_state
    health_check_path                     = var.health_check_path
    health_check_eviction_time_in_min     = var.health_check_eviction_time_in_min
    http2_enabled                         = var.http2_enabled
    load_balancing_mode                   = var.load_balancing_mode
    local_mysql_enabled                   = var.local_mysql_enabled
    managed_pipeline_mode                 = var.managed_pipeline_mode
    minimum_tls_version                   = var.minimum_tls_version
    remote_debugging_enabled              = var.remote_debugging_enabled
    remote_debugging_version              = var.remote_debugging_version
    scm_minimum_tls_version              = var.scm_minimum_tls_version
    scm_use_main_ip_restriction          = var.scm_use_main_ip_restriction
    use_32_bit_worker                    = var.use_32_bit_worker
    vnet_route_all_enabled               = var.vnet_route_all_enabled
    websockets_enabled                   = var.websockets_enabled

    # Application stack for Windows
    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        current_stack             = application_stack.value.current_stack
        dotnet_version           = application_stack.value.dotnet_version
        dotnet_core_version      = application_stack.value.dotnet_core_version
        tomcat_version           = application_stack.value.tomcat_version
        java_embedded_server_enabled = application_stack.value.java_embedded_server_enabled
        java_version             = application_stack.value.java_version
        node_version             = application_stack.value.node_version
        php_version              = application_stack.value.php_version
        python                   = application_stack.value.python
      }
    }

    # Auto heal setting (same as Linux)
    dynamic "auto_heal_setting" {
      for_each = var.auto_heal_setting != null ? [var.auto_heal_setting] : []
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
              for_each = trigger.value.status_code
              content {
                count             = status_code.value.count
                interval          = status_code.value.interval
                status_code_range = status_code.value.status_code_range
                path              = status_code.value.path
                sub_status        = status_code.value.sub_status
                win32_status_code = status_code.value.win32_status_code
              }
            }
          }
        }
      }
    }
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

  tags = var.tags
}

# Deployment Slot (Linux)
resource "azurerm_linux_web_app_slot" "staging" {
  count = var.os_type == "Linux" && var.enable_staging_slot ? 1 : 0

  name           = "staging"
  app_service_id = azurerm_linux_web_app.main[0].id

  site_config {
    always_on = var.always_on

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version = application_stack.value.dotnet_version
        go_version    = application_stack.value.go_version
        java_version  = application_stack.value.java_version
        node_version  = application_stack.value.node_version
        php_version   = application_stack.value.php_version
        python_version = application_stack.value.python_version
        ruby_version  = application_stack.value.ruby_version
      }
    }
  }

  app_settings = merge(var.app_settings, {
    "STAGING_SLOT" = "true"
  })

  tags = var.tags
}

# Deployment Slot (Windows)
resource "azurerm_windows_web_app_slot" "staging" {
  count = var.os_type == "Windows" && var.enable_staging_slot ? 1 : 0

  name           = "staging"
  app_service_id = azurerm_windows_web_app.main[0].id

  site_config {
    always_on = var.always_on

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        current_stack        = application_stack.value.current_stack
        dotnet_version      = application_stack.value.dotnet_version
        dotnet_core_version = application_stack.value.dotnet_core_version
        java_version        = application_stack.value.java_version
        node_version        = application_stack.value.node_version
        php_version         = application_stack.value.php_version
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

  name                = "${var.app_service_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.app_service_name}-psc"
    private_connection_resource_id = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
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

  name               = "${var.app_service_name}-diagnostics"
  target_resource_id = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
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