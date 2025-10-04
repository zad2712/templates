# =============================================================================
# COSMOS DB MODULE
# =============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  offer_type               = var.offer_type
  kind                     = var.kind
  
  enable_automatic_failover         = var.enable_automatic_failover
  enable_multiple_write_locations   = var.enable_multiple_write_locations
  ip_range_filter                  = var.ip_range_filter
  enable_free_tier                 = var.enable_free_tier
  analytical_storage_enabled       = var.analytical_storage_enabled
  local_authentication_disabled    = var.local_authentication_disabled
  
  network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services
  network_acl_bypass_ids               = var.network_acl_bypass_ids

  consistency_policy {
    consistency_level       = var.consistency_policy.consistency_level
    max_interval_in_seconds = var.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = var.consistency_policy.max_staleness_prefix
  }

  # Default geo location
  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  # Additional geo locations
  dynamic "geo_location" {
    for_each = var.geo_location
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  # Capacity configuration
  dynamic "capacity" {
    for_each = var.capacity != null ? [var.capacity] : []
    content {
      total_throughput_limit = capacity.value.total_throughput_limit
    }
  }

  # Backup configuration
  backup {
    type                = var.backup.type
    interval_in_minutes = var.backup.interval_in_minutes
    retention_in_hours  = var.backup.retention_in_hours
    storage_redundancy  = var.backup.storage_redundancy
  }

  # CORS rule
  dynamic "cors_rule" {
    for_each = var.cors_rule != null ? [var.cors_rule] : []
    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  # Identity configuration
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # Virtual network rules
  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rule
    content {
      id                                   = virtual_network_rule.value.id
      ignore_missing_vnet_service_endpoint = virtual_network_rule.value.ignore_missing_vnet_service_endpoint
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# SQL Databases
resource "azurerm_cosmosdb_sql_database" "main" {
  for_each = {
    for db in var.databases : db.name => db
  }

  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [each.value.autoscale_settings] : []
    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }
}

# SQL Containers
resource "azurerm_cosmosdb_sql_container" "main" {
  for_each = merge([
    for db_key, db in var.databases : {
      for container in coalesce(db.containers, []) :
      "${db_key}.${container.name}" => merge(container, {
        database_name = db.name
      })
    }
  ]...)

  name                  = each.value.name
  resource_group_name   = azurerm_cosmosdb_account.main.resource_group_name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = each.value.database_name
  partition_key_path    = each.value.partition_key_path
  partition_key_kind    = each.value.partition_key_kind
  throughput           = each.value.throughput
  default_ttl          = each.value.default_ttl

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_settings != null ? [each.value.autoscale_settings] : []
    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }

  dynamic "unique_key" {
    for_each = coalesce(each.value.unique_key, [])
    content {
      paths = unique_key.value.paths
    }
  }

  indexing_policy {
    indexing_mode = "consistent"

    dynamic "included_path" {
      for_each = coalesce(each.value.included_path, [])
      content {
        path = included_path.value.path
      }
    }

    dynamic "excluded_path" {
      for_each = coalesce(each.value.excluded_path, [])
      content {
        path = excluded_path.value.path
      }
    }

    dynamic "composite_index" {
      for_each = coalesce(each.value.composite_index, [])
      content {
        dynamic "index" {
          for_each = composite_index.value.index
          content {
            path  = index.value.path
            order = index.value.order
          }
        }
      }
    }

    dynamic "spatial_index" {
      for_each = coalesce(each.value.spatial_index, [])
      content {
        path = spatial_index.value.path
      }
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = each.value.conflict_resolution_policy != null ? [each.value.conflict_resolution_policy] : []
    content {
      mode                          = conflict_resolution_policy.value.mode
      conflict_resolution_path      = conflict_resolution_policy.value.conflict_resolution_path
      conflict_resolution_procedure = conflict_resolution_policy.value.conflict_resolution_procedure
    }
  }

  depends_on = [azurerm_cosmosdb_sql_database.main]
}

# Private Endpoint (if subnet is provided)
resource "azurerm_private_endpoint" "main" {
  count = length(var.virtual_network_rule) > 0 ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id          = var.virtual_network_rule[0].id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  tags = var.tags
}

# Private DNS Zone Group (if private endpoint exists)
resource "azurerm_private_dns_zone_group" "main" {
  count = length(var.virtual_network_rule) > 0 ? 1 : 0

  name                 = "${var.name}-dns-zone-group"
  resource_group_name  = var.resource_group_name
  private_endpoint_id  = azurerm_private_endpoint.main[0].id

  private_dns_zone_config {
    name                 = "cosmos-db"
    private_dns_zone_id  = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com"
  }
}