# =============================================================================
# REDIS CACHE OUTPUTS
# =============================================================================

output "id" {
  description = "The ID of the Redis Cache"
  value       = azurerm_redis_cache.main.id
}

output "name" {
  description = "The name of the Redis Cache"
  value       = azurerm_redis_cache.main.name
}

output "hostname" {
  description = "The hostname of the Redis Cache"
  value       = azurerm_redis_cache.main.hostname
}

output "ssl_port" {
  description = "The SSL port of the Redis Cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "port" {
  description = "The non-SSL port of the Redis Cache"
  value       = azurerm_redis_cache.main.port
}

output "primary_access_key" {
  description = "The primary access key for the Redis Cache"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the Redis Cache"
  value       = azurerm_redis_cache.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string for the Redis Cache"
  value       = azurerm_redis_cache.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The secondary connection string for the Redis Cache"
  value       = azurerm_redis_cache.main.secondary_connection_string
  sensitive   = true
}

output "redis_configuration" {
  description = "The Redis configuration of the Redis Cache"
  value       = azurerm_redis_cache.main.redis_configuration
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = length(azurerm_private_endpoint.main) > 0 ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint"
  value       = length(azurerm_private_endpoint.main) > 0 ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

output "identity" {
  description = "The identity of the Redis Cache"
  value = azurerm_redis_cache.main.identity != null ? {
    type         = azurerm_redis_cache.main.identity[0].type
    principal_id = azurerm_redis_cache.main.identity[0].principal_id
    tenant_id    = azurerm_redis_cache.main.identity[0].tenant_id
  } : null
}

output "firewall_rules" {
  description = "The firewall rules of the Redis Cache"
  value = {
    for k, rule in azurerm_redis_firewall_rule.main : k => {
      id               = rule.id
      name            = rule.name
      start_ip        = rule.start_ip
      end_ip          = rule.end_ip
    }
  }
}