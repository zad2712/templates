# =============================================================================
# STORAGE ACCOUNT OUTPUTS
# =============================================================================

output "id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.main.name
}

output "primary_location" {
  description = "The primary location of the Storage Account"
  value       = azurerm_storage_account.main.primary_location
}

output "secondary_location" {
  description = "The secondary location of the Storage Account"
  value       = azurerm_storage_account.main.secondary_location
}

output "primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the primary location"
  value       = azurerm_storage_account.main.primary_blob_host
}

output "secondary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_blob_endpoint
}

output "secondary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_blob_host
}

output "primary_queue_endpoint" {
  description = "The endpoint URL for queue storage in the primary location"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_queue_host" {
  description = "The hostname with port if applicable for queue storage in the primary location"
  value       = azurerm_storage_account.main.primary_queue_host
}

output "secondary_queue_endpoint" {
  description = "The endpoint URL for queue storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_queue_endpoint
}

output "secondary_queue_host" {
  description = "The hostname with port if applicable for queue storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_queue_host
}

output "primary_table_endpoint" {
  description = "The endpoint URL for table storage in the primary location"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_table_host" {
  description = "The hostname with port if applicable for table storage in the primary location"
  value       = azurerm_storage_account.main.primary_table_host
}

output "secondary_table_endpoint" {
  description = "The endpoint URL for table storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_table_endpoint
}

output "secondary_table_host" {
  description = "The hostname with port if applicable for table storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_table_host
}

output "primary_file_endpoint" {
  description = "The endpoint URL for file storage in the primary location"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_file_host" {
  description = "The hostname with port if applicable for file storage in the primary location"
  value       = azurerm_storage_account.main.primary_file_host
}

output "secondary_file_endpoint" {
  description = "The endpoint URL for file storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_file_endpoint
}

output "secondary_file_host" {
  description = "The hostname with port if applicable for file storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_file_host
}

output "primary_dfs_endpoint" {
  description = "The endpoint URL for DFS storage in the primary location"
  value       = azurerm_storage_account.main.primary_dfs_endpoint
}

output "primary_dfs_host" {
  description = "The hostname with port if applicable for DFS storage in the primary location"
  value       = azurerm_storage_account.main.primary_dfs_host
}

output "secondary_dfs_endpoint" {
  description = "The endpoint URL for DFS storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_dfs_endpoint
}

output "secondary_dfs_host" {
  description = "The hostname with port if applicable for DFS storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_dfs_host
}

output "primary_web_endpoint" {
  description = "The endpoint URL for web storage in the primary location"
  value       = azurerm_storage_account.main.primary_web_endpoint
}

output "primary_web_host" {
  description = "The hostname with port if applicable for web storage in the primary location"
  value       = azurerm_storage_account.main.primary_web_host
}

output "secondary_web_endpoint" {
  description = "The endpoint URL for web storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_web_endpoint
}

output "secondary_web_host" {
  description = "The hostname with port if applicable for web storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_web_host
}

output "primary_access_key" {
  description = "The primary access key for the Storage Account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the Storage Account"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The connection string associated with the primary location"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The connection string associated with the secondary location"
  value       = azurerm_storage_account.main.secondary_connection_string
  sensitive   = true
}

output "primary_blob_connection_string" {
  description = "The connection string associated with the primary blob location"
  value       = azurerm_storage_account.main.primary_blob_connection_string
  sensitive   = true
}

output "secondary_blob_connection_string" {
  description = "The connection string associated with the secondary blob location"
  value       = azurerm_storage_account.main.secondary_blob_connection_string
  sensitive   = true
}

output "identity" {
  description = "The identity of the Storage Account"
  value = azurerm_storage_account.main.identity != null ? {
    type         = azurerm_storage_account.main.identity[0].type
    principal_id = azurerm_storage_account.main.identity[0].principal_id
    tenant_id    = azurerm_storage_account.main.identity[0].tenant_id
  } : null
}

output "containers" {
  description = "Map of containers created in the Storage Account"
  value = {
    for k, container in azurerm_storage_container.main : k => {
      id                    = container.id
      name                  = container.name
      container_access_type = container.container_access_type
      has_immutability_policy = container.has_immutability_policy
      has_legal_hold        = container.has_legal_hold
      resource_manager_id   = container.resource_manager_id
    }
  }
}

output "file_shares" {
  description = "Map of file shares created in the Storage Account"
  value = {
    for k, share in azurerm_storage_share.main : k => {
      id           = share.id
      name         = share.name
      quota        = share.quota
      enabled_protocol = share.enabled_protocol
      resource_manager_id = share.resource_manager_id
      url          = share.url
    }
  }
}

output "queues" {
  description = "Map of queues created in the Storage Account"
  value = {
    for k, queue in azurerm_storage_queue.main : k => {
      id                  = queue.id
      name               = queue.name
      resource_manager_id = queue.resource_manager_id
    }
  }
}

output "tables" {
  description = "Map of tables created in the Storage Account"
  value = {
    for k, table in azurerm_storage_table.main : k => {
      id   = table.id
      name = table.name
    }
  }
}

output "private_endpoints" {
  description = "Map of private endpoints created for the Storage Account"
  value = {
    for service, pe in azurerm_private_endpoint.main : service => {
      id                = pe.id
      name             = pe.name
      private_ip_address = pe.private_service_connection[0].private_ip_address
    }
  }
}

output "network_rules" {
  description = "The network rules of the Storage Account"
  value = azurerm_storage_account.main.network_rules != null ? {
    default_action             = azurerm_storage_account.main.network_rules[0].default_action
    bypass                     = azurerm_storage_account.main.network_rules[0].bypass
    ip_rules                   = azurerm_storage_account.main.network_rules[0].ip_rules
    virtual_network_subnet_ids = azurerm_storage_account.main.network_rules[0].virtual_network_subnet_ids
  } : null
}

output "blob_properties" {
  description = "The blob properties of the Storage Account"
  value = {
    versioning_enabled       = azurerm_storage_account.main.blob_properties[0].versioning_enabled
    change_feed_enabled      = azurerm_storage_account.main.blob_properties[0].change_feed_enabled
    default_service_version  = azurerm_storage_account.main.blob_properties[0].default_service_version
    last_access_time_enabled = azurerm_storage_account.main.blob_properties[0].last_access_time_enabled
  }
}

output "static_website" {
  description = "The static website configuration of the Storage Account"
  value = azurerm_storage_account.main.static_website != null ? {
    index_document     = azurerm_storage_account.main.static_website[0].index_document
    error_404_document = azurerm_storage_account.main.static_website[0].error_404_document
  } : null
}