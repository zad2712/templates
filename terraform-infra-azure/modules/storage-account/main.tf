# =============================================================================
# AZURE STORAGE ACCOUNT MODULE
# =============================================================================

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                = var.location
  account_tier            = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind            = var.account_kind
  access_tier             = var.access_tier

  # Security settings
  enable_https_traffic_only      = var.enable_https_traffic_only
  min_tls_version               = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled     = var.shared_access_key_enabled
  public_network_access_enabled = var.public_network_access_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication

  # Cross-tenant replication
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled

  # Availability zones
  edge_zone = var.edge_zone

  # Large file shares
  large_file_share_enabled = var.large_file_share_enabled

  # Network rules
  dynamic "network_rules" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action             = var.network_rules.default_action
      bypass                     = var.network_rules.bypass
      ip_rules                   = var.network_rules.ip_rules
      virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids

      dynamic "private_link_access" {
        for_each = var.network_rules.private_link_access
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }

  # Blob properties
  dynamic "blob_properties" {
    for_each = var.enable_blob_properties ? [1] : []
    content {
      versioning_enabled       = var.blob_properties.versioning_enabled
      change_feed_enabled     = var.blob_properties.change_feed_enabled
      change_feed_retention_in_days = var.blob_properties.change_feed_retention_in_days
      default_service_version = var.blob_properties.default_service_version
      last_access_time_enabled = var.blob_properties.last_access_time_enabled

      dynamic "cors_rule" {
        for_each = var.blob_properties.cors_rules
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = var.blob_properties.delete_retention_policy != null ? [var.blob_properties.delete_retention_policy] : []
        content {
          days = delete_retention_policy.value.days
        }
      }

      dynamic "restore_policy" {
        for_each = var.blob_properties.restore_policy != null ? [var.blob_properties.restore_policy] : []
        content {
          days = restore_policy.value.days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = var.blob_properties.container_delete_retention_policy != null ? [var.blob_properties.container_delete_retention_policy] : []
        content {
          days = container_delete_retention_policy.value.days
        }
      }
    }
  }

  # Queue properties
  dynamic "queue_properties" {
    for_each = var.enable_queue_properties ? [1] : []
    content {
      dynamic "cors_rule" {
        for_each = var.queue_properties.cors_rules
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "logging" {
        for_each = var.queue_properties.logging != null ? [var.queue_properties.logging] : []
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          version               = logging.value.version
          write                 = logging.value.write
          retention_policy_days = logging.value.retention_policy_days
        }
      }

      dynamic "minute_metrics" {
        for_each = var.queue_properties.minute_metrics != null ? [var.queue_properties.minute_metrics] : []
        content {
          enabled               = minute_metrics.value.enabled
          version               = minute_metrics.value.version
          include_apis          = minute_metrics.value.include_apis
          retention_policy_days = minute_metrics.value.retention_policy_days
        }
      }

      dynamic "hour_metrics" {
        for_each = var.queue_properties.hour_metrics != null ? [var.queue_properties.hour_metrics] : []
        content {
          enabled               = hour_metrics.value.enabled
          version               = hour_metrics.value.version
          include_apis          = hour_metrics.value.include_apis
          retention_policy_days = hour_metrics.value.retention_policy_days
        }
      }
    }
  }

  # Share properties (for File shares)
  dynamic "share_properties" {
    for_each = var.enable_share_properties ? [1] : []
    content {
      dynamic "cors_rule" {
        for_each = var.share_properties.cors_rules
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "retention_policy" {
        for_each = var.share_properties.retention_policy != null ? [var.share_properties.retention_policy] : []
        content {
          days = retention_policy.value.days
        }
      }

      dynamic "smb" {
        for_each = var.share_properties.smb != null ? [var.share_properties.smb] : []
        content {
          versions                        = smb.value.versions
          authentication_types           = smb.value.authentication_types
          kerberos_ticket_encryption_type = smb.value.kerberos_ticket_encryption_type
          channel_encryption_type        = smb.value.channel_encryption_type
        }
      }
    }
  }

  # Static website
  dynamic "static_website" {
    for_each = var.enable_static_website ? [1] : []
    content {
      index_document     = var.static_website.index_document
      error_404_document = var.static_website.error_404_document
    }
  }

  # Customer managed key
  dynamic "customer_managed_key" {
    for_each = var.enable_customer_managed_key ? [1] : []
    content {
      key_vault_key_id          = var.customer_managed_key.key_vault_key_id
      user_assigned_identity_id = var.customer_managed_key.user_assigned_identity_id
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }

  # Azure files authentication
  dynamic "azure_files_authentication" {
    for_each = var.enable_azure_files_authentication ? [1] : []
    content {
      directory_type = var.azure_files_authentication.directory_type

      dynamic "active_directory" {
        for_each = var.azure_files_authentication.active_directory != null ? [var.azure_files_authentication.active_directory] : []
        content {
          storage_sid         = active_directory.value.storage_sid
          domain_name         = active_directory.value.domain_name
          domain_sid          = active_directory.value.domain_sid
          domain_guid         = active_directory.value.domain_guid
          forest_name         = active_directory.value.forest_name
          netbios_domain_name = active_directory.value.netbios_domain_name
        }
      }
    }
  }

  tags = var.tags
}

# Storage Containers
resource "azurerm_storage_container" "main" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.container_access_type
}

# Storage Shares
resource "azurerm_storage_share" "main" {
  for_each = var.shares

  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
  quota                = each.value.quota
  enabled_protocol     = each.value.enabled_protocol
  access_tier          = each.value.access_tier
}

# Storage Queues
resource "azurerm_storage_queue" "main" {
  for_each = var.queues

  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
}

# Storage Tables
resource "azurerm_storage_table" "main" {
  for_each = var.tables

  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
}

# Private Endpoints
resource "azurerm_private_endpoint" "blob" {
  count = var.enable_private_endpoints && contains(var.private_endpoint_subresources, "blob") ? 1 : 0

  name                = "${var.name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names             = ["blob"]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.blob_private_dns_zone_id != null ? [1] : []
    content {
      name                 = "blob-dns-zone-group"
      private_dns_zone_ids = [var.blob_private_dns_zone_id]
    }
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "file" {
  count = var.enable_private_endpoints && contains(var.private_endpoint_subresources, "file") ? 1 : 0

  name                = "${var.name}-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-file-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names             = ["file"]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.file_private_dns_zone_id != null ? [1] : []
    content {
      name                 = "file-dns-zone-group"
      private_dns_zone_ids = [var.file_private_dns_zone_id]
    }
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "metric" {
    for_each = var.diagnostic_settings.metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}