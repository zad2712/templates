# =============================================================================
# REDIS CACHE MODULE
# =============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  enable_non_ssl_port           = var.enable_non_ssl_port
  minimum_tls_version           = var.minimum_tls_version
  redis_version                 = var.redis_version
  public_network_access_enabled = var.public_network_access_enabled
  private_static_ip_address     = var.private_static_ip_address
  subnet_id                     = var.subnet_id
  shard_count                   = var.shard_count
  zones                         = var.zones
  replicas_per_master           = var.replicas_per_master
  replicas_per_primary          = var.replicas_per_primary
  tenant_settings               = var.tenant_settings

  # Redis configuration
  redis_configuration {
    enable_authentication           = var.redis_configuration.enable_authentication
    maxmemory_reserved             = var.redis_configuration.maxmemory_reserved
    maxmemory_delta                = var.redis_configuration.maxmemory_delta
    maxmemory_policy               = var.redis_configuration.maxmemory_policy
    maxfragmentationmemory_reserved = var.redis_configuration.maxfragmentationmemory_reserved
    rdb_backup_enabled             = var.redis_configuration.rdb_backup_enabled
    rdb_backup_frequency           = var.redis_configuration.rdb_backup_frequency
    rdb_backup_max_snapshot_count  = var.redis_configuration.rdb_backup_max_snapshot_count
    rdb_storage_connection_string  = var.redis_configuration.rdb_storage_connection_string
    notify_keyspace_events         = var.redis_configuration.notify_keyspace_events
    aof_backup_enabled             = var.redis_configuration.aof_backup_enabled
    aof_storage_connection_string_0 = var.redis_configuration.aof_storage_connection_string_0
    aof_storage_connection_string_1 = var.redis_configuration.aof_storage_connection_string_1
  }

  # Patch schedule
  dynamic "patch_schedule" {
    for_each = var.patch_schedule
    content {
      day_of_week        = patch_schedule.value.day_of_week
      start_hour_utc     = patch_schedule.value.start_hour_utc
      maintenance_window = patch_schedule.value.maintenance_window
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Firewall rules
resource "azurerm_redis_firewall_rule" "main" {
  for_each = {
    for rule in var.firewall_rules : rule.name => rule
  }

  name             = each.value.name
  redis_cache_name = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip         = each.value.start_ip_address
  end_ip           = each.value.end_ip_address
}

# Private Endpoint
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_redis_cache.main.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  tags = var.tags
}

# Private DNS Zone Group
resource "azurerm_private_dns_zone_group" "main" {
  count = var.enable_private_endpoint && var.private_dns_zone_id != null ? 1 : 0

  name                 = "${var.name}-dns-zone-group"
  resource_group_name  = var.resource_group_name
  private_endpoint_id  = azurerm_private_endpoint.main[0].id

  private_dns_zone_config {
    name                 = "redis"
    private_dns_zone_id  = var.private_dns_zone_id
  }
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_redis_cache.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ConnectedClientList"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}

# Optional Log Analytics Workspace ID variable
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
  default     = null
}