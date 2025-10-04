# =============================================================================
# PRIVATE ENDPOINT MODULE
# =============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Validate subresource names for known service types
locals {
  valid_subresources = var.service_type == "custom" ? var.subresource_names : [
    for subresource in var.subresource_names :
    subresource if contains(local.service_subresources[var.service_type], subresource)
  ]
}

# Private Endpoint
resource "azurerm_private_endpoint" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  custom_network_interface_name = var.custom_network_interface_name

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = var.private_connection_resource_id
    is_manual_connection           = var.is_manual_connection
    subresource_names              = local.valid_subresources
    request_message                = var.request_message
  }

  # IP Configuration
  dynamic "ip_configuration" {
    for_each = var.ip_configuration
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  # Private DNS Zone Group
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_group != null ? [var.private_dns_zone_group] : []
    content {
      name = private_dns_zone_group.value.name

      dynamic "private_dns_zone_config" {
        for_each = private_dns_zone_group.value.private_dns_zone_configs
        content {
          name                 = private_dns_zone_config.value.name
          private_dns_zone_id  = private_dns_zone_config.value.private_dns_zone_id
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition = var.service_type == "custom" || length(local.valid_subresources) > 0
      error_message = "Invalid subresource names for the specified service type. Please check the subresource_names variable."
    }
  }
}

# Application Security Group Association
resource "azurerm_private_endpoint_application_security_group_association" "main" {
  for_each = toset(var.application_security_group_ids)

  private_endpoint_id           = azurerm_private_endpoint.main.id
  application_security_group_id = each.value
}

# Network Interface Security Group Association (if NSG is provided)
data "azurerm_network_interface" "pe_nic" {
  name                = azurerm_private_endpoint.main.network_interface[0].name
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_interface_security_group_association" "main" {
  count = var.network_security_group_id != null ? 1 : 0

  network_interface_id      = data.azurerm_network_interface.pe_nic.id
  network_security_group_id = var.network_security_group_id
}

# Policy Settings (if enabled)
resource "azurerm_subnet_network_security_group_association" "main" {
  count = var.policy_settings_enabled && var.network_security_group_id != null ? 1 : 0

  subnet_id                 = var.subnet_id
  network_security_group_id = var.network_security_group_id
}

# Common Private DNS Zones for different services
locals {
  service_dns_zones = {
    storage_account = {
      blob  = "privatelink.blob.core.windows.net"
      file  = "privatelink.file.core.windows.net"
      queue = "privatelink.queue.core.windows.net"
      table = "privatelink.table.core.windows.net"
      web   = "privatelink.web.core.windows.net"
      dfs   = "privatelink.dfs.core.windows.net"
    }
    sql_server         = { sqlServer = "privatelink.database.windows.net" }
    cosmos_db          = { Sql = "privatelink.documents.azure.com" }
    key_vault          = { vault = "privatelink.vaultcore.azure.net" }
    redis_cache        = { redisCache = "privatelink.redis.cache.windows.net" }
    app_service        = { sites = "privatelink.azurewebsites.net" }
    function_app       = { sites = "privatelink.azurewebsites.net" }
    synapse           = { Sql = "privatelink.sql.azuresynapse.net" }
    data_factory      = { dataFactory = "privatelink.datafactory.azure.net" }
    event_hub         = { namespace = "privatelink.servicebus.windows.net" }
    service_bus       = { namespace = "privatelink.servicebus.windows.net" }
    cognitive_services = { account = "privatelink.cognitiveservices.azure.com" }
    container_registry = { registry = "privatelink.azurecr.io" }
    kubernetes        = { management = "privatelink.management.azure.com" }
    mysql            = { mysqlServer = "privatelink.mysql.database.azure.com" }
    postgresql       = { postgresqlServer = "privatelink.postgres.database.azure.com" }
  }
}