# =============================================================================
# PRIVATE ENDPOINT OUTPUTS
# =============================================================================

output "id" {
  description = "The ID of the Private Endpoint"
  value       = azurerm_private_endpoint.main.id
}

output "name" {
  description = "The name of the Private Endpoint"
  value       = azurerm_private_endpoint.main.name
}

output "private_service_connection" {
  description = "The private service connection details"
  value = {
    private_ip_address = azurerm_private_endpoint.main.private_service_connection[0].private_ip_address
    name              = azurerm_private_endpoint.main.private_service_connection[0].name
  }
}

output "network_interface" {
  description = "The network interface of the Private Endpoint"
  value = {
    id   = azurerm_private_endpoint.main.network_interface[0].id
    name = azurerm_private_endpoint.main.network_interface[0].name
  }
}

output "private_ip_address" {
  description = "The private IP address associated with the private endpoint"
  value       = azurerm_private_endpoint.main.private_service_connection[0].private_ip_address
}

output "private_ip_addresses" {
  description = "All private IP addresses associated with the private endpoint"
  value       = azurerm_private_endpoint.main.private_service_connection[*].private_ip_address
}

output "custom_dns_configs" {
  description = "Custom DNS configurations for the private endpoint"
  value = azurerm_private_endpoint.main.custom_dns_configs != null ? [
    for config in azurerm_private_endpoint.main.custom_dns_configs : {
      fqdn         = config.fqdn
      ip_addresses = config.ip_addresses
    }
  ] : []
}

output "private_dns_zone_group" {
  description = "The private DNS zone group configuration"
  value = var.private_dns_zone_group != null ? {
    id   = azurerm_private_endpoint.main.private_dns_zone_group[0].id
    name = azurerm_private_endpoint.main.private_dns_zone_group[0].name
  } : null
}

output "private_dns_zone_configs" {
  description = "The private DNS zone configurations"
  value = var.private_dns_zone_group != null ? [
    for config in azurerm_private_endpoint.main.private_dns_zone_group[0].private_dns_zone_config : {
      name                = config.name
      private_dns_zone_id = config.private_dns_zone_id
      record_sets = [
        for record in config.record_sets : {
          name         = record.name
          type         = record.type
          fqdn         = record.fqdn
          ttl          = record.ttl
          ip_addresses = record.ip_addresses
        }
      ]
    }
  ] : []
}

output "application_security_group_associations" {
  description = "The application security group associations"
  value = {
    for k, v in azurerm_private_endpoint_application_security_group_association.main : k => {
      id                            = v.id
      private_endpoint_id           = v.private_endpoint_id
      application_security_group_id = v.application_security_group_id
    }
  }
}

output "network_security_group_association" {
  description = "The network security group association"
  value = length(azurerm_network_interface_security_group_association.main) > 0 ? {
    id                        = azurerm_network_interface_security_group_association.main[0].id
    network_interface_id      = azurerm_network_interface_security_group_association.main[0].network_interface_id
    network_security_group_id = azurerm_network_interface_security_group_association.main[0].network_security_group_id
  } : null
}

output "recommended_dns_zone" {
  description = "Recommended private DNS zone for the service type and subresources"
  value = var.service_type != "custom" && contains(keys(local.service_dns_zones), var.service_type) ? {
    for subresource in var.subresource_names :
    subresource => lookup(local.service_dns_zones[var.service_type], subresource, null)
  } : {}
}