# =============================================================================
# COSMOS DB OUTPUTS
# =============================================================================

output "id" {
  description = "The ID of the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.id
}

output "name" {
  description = "The name of the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.name
}

output "endpoint" {
  description = "The endpoint used to connect to the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "read_endpoints" {
  description = "A list of read endpoints available for this CosmosDB account"
  value       = azurerm_cosmosdb_account.main.read_endpoints
}

output "write_endpoints" {
  description = "A list of write endpoints available for this CosmosDB account"
  value       = azurerm_cosmosdb_account.main.write_endpoints
}

output "primary_key" {
  description = "The primary key for the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "The secondary key for the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.secondary_key
  sensitive   = true
}

output "primary_readonly_key" {
  description = "The primary read-only key for the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.primary_readonly_key
  sensitive   = true
}

output "secondary_readonly_key" {
  description = "The secondary read-only key for the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.secondary_readonly_key
  sensitive   = true
}

output "connection_strings" {
  description = "A list of connection strings available for this CosmosDB account"
  value       = azurerm_cosmosdb_account.main.connection_strings
  sensitive   = true
}

output "databases" {
  description = "Map of databases created in the CosmosDB account"
  value = {
    for k, db in azurerm_cosmosdb_sql_database.main : k => {
      id   = db.id
      name = db.name
    }
  }
}

output "containers" {
  description = "Map of containers created in the databases"
  value = {
    for k, container in azurerm_cosmosdb_sql_container.main : k => {
      id                = container.id
      name             = container.name
      database_name    = container.database_name
      partition_key_path = container.partition_key_path
    }
  }
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
  description = "The identity of the CosmosDB account"
  value = azurerm_cosmosdb_account.main.identity != null ? {
    type         = azurerm_cosmosdb_account.main.identity[0].type
    principal_id = azurerm_cosmosdb_account.main.identity[0].principal_id
    tenant_id    = azurerm_cosmosdb_account.main.identity[0].tenant_id
  } : null
}