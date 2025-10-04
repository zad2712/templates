# =============================================================================
# AZURE SQL DATABASE MODULE
# =============================================================================

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.sql_version
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_password
  
  minimum_tls_version               = var.minimum_tls_version
  public_network_access_enabled     = var.public_network_access_enabled
  connection_policy                = var.connection_policy
  outbound_network_restriction_enabled = var.outbound_network_restriction_enabled

  # Azure AD Administrator
  dynamic "azuread_administrator" {
    for_each = var.enable_azure_ad_authentication ? [1] : []
    content {
      login_username              = var.azure_ad_administrator.login_username
      object_id                   = var.azure_ad_administrator.object_id
      tenant_id                   = var.azure_ad_administrator.tenant_id
      azuread_authentication_only = var.azure_ad_administrator.azuread_authentication_only
    }
  }

  # Identity (for managed identity integration)
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  count = length(var.databases)

  name           = var.databases[count.index].name
  server_id      = azurerm_mssql_server.main.id
  collation      = var.databases[count.index].collation
  license_type   = var.databases[count.index].license_type
  max_size_gb    = var.databases[count.index].max_size_gb
  read_scale     = var.databases[count.index].read_scale
  sku_name       = var.databases[count.index].sku_name
  zone_redundant = var.databases[count.index].zone_redundant
  
  geo_backup_enabled                = var.databases[count.index].geo_backup_enabled
  maintenance_configuration_name    = var.databases[count.index].maintenance_configuration_name
  ledger_enabled                   = var.databases[count.index].ledger_enabled
  transparent_data_encryption_enabled = var.databases[count.index].transparent_data_encryption_enabled

  # Auto Pause and Auto Resume for Serverless
  auto_pause_delay_in_minutes = var.databases[count.index].sku_name == "GP_S_Gen5_1" ? var.databases[count.index].auto_pause_delay_in_minutes : null
  min_capacity               = contains(["GP_S_Gen5_1", "GP_S_Gen5_2"], var.databases[count.index].sku_name) ? var.databases[count.index].min_capacity : null

  # Threat Detection Policy
  dynamic "threat_detection_policy" {
    for_each = var.enable_threat_detection ? [1] : []
    content {
      state                = "Enabled"
      email_admin_enabled  = var.threat_detection_policy.email_admin_enabled
      email_addresses      = var.threat_detection_policy.email_addresses
      retention_days       = var.threat_detection_policy.retention_days
      storage_endpoint     = var.threat_detection_policy.storage_endpoint
      storage_account_access_key = var.threat_detection_policy.storage_account_access_key
    }
  }

  # Long Term Retention Policy
  dynamic "long_term_retention_policy" {
    for_each = var.enable_long_term_retention ? [1] : []
    content {
      weekly_retention  = var.long_term_retention_policy.weekly_retention
      monthly_retention = var.long_term_retention_policy.monthly_retention
      yearly_retention  = var.long_term_retention_policy.yearly_retention
      week_of_year     = var.long_term_retention_policy.week_of_year
    }
  }

  # Short Term Retention Policy
  dynamic "short_term_retention_policy" {
    for_each = var.enable_short_term_retention ? [1] : []
    content {
      retention_days           = var.short_term_retention_policy.retention_days
      backup_interval_in_hours = var.short_term_retention_policy.backup_interval_in_hours
    }
  }

  tags = var.tags
}

# Elastic Pool (optional)
resource "azurerm_mssql_elasticpool" "main" {
  count = var.enable_elastic_pool ? 1 : 0

  name                = var.elastic_pool.name
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_mssql_server.main.name
  license_type        = var.elastic_pool.license_type
  max_size_gb         = var.elastic_pool.max_size_gb
  zone_redundant      = var.elastic_pool.zone_redundant

  sku {
    name     = var.elastic_pool.sku.name
    tier     = var.elastic_pool.sku.tier
    family   = var.elastic_pool.sku.family
    capacity = var.elastic_pool.sku.capacity
  }

  per_database_settings {
    min_capacity = var.elastic_pool.per_database_settings.min_capacity
    max_capacity = var.elastic_pool.per_database_settings.max_capacity
  }

  tags = var.tags
}

# Firewall Rules
resource "azurerm_mssql_firewall_rule" "main" {
  count = length(var.firewall_rules)

  name             = var.firewall_rules[count.index].name
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.firewall_rules[count.index].start_ip_address
  end_ip_address   = var.firewall_rules[count.index].end_ip_address
}

# Virtual Network Rules
resource "azurerm_mssql_virtual_network_rule" "main" {
  count = length(var.virtual_network_rules)

  name      = var.virtual_network_rules[count.index].name
  server_id = azurerm_mssql_server.main.id
  subnet_id = var.virtual_network_rules[count.index].subnet_id
}

# Private Endpoint (if enabled)
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names             = ["sqlServer"]
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
resource "azurerm_monitor_diagnostic_setting" "server" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_mssql_server.main.id
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

resource "azurerm_monitor_diagnostic_setting" "database" {
  count = var.enable_diagnostic_settings ? length(var.databases) : 0

  name                       = "${var.databases[count.index].name}-diagnostics"
  target_resource_id         = azurerm_mssql_database.main[count.index].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.database_logs
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.database_metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}