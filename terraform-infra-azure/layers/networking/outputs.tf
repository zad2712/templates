# =============================================================================
# NETWORKING LAYER OUTPUTS
# =============================================================================

# Resource Group
output "resource_group_name" {
  description = "Name of the networking resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the networking resource group"
  value       = module.resource_group.id
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = var.location
}

# Virtual Network
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.virtual_network.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.virtual_network.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = module.virtual_network.address_space
}

# Subnets
output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.virtual_network.subnet_ids
}

output "subnet_names" {
  description = "Map of subnet keys to their names"
  value       = module.virtual_network.subnet_names
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value       = module.virtual_network.subnet_address_prefixes
}

# Specific subnet outputs for easy reference
output "web_subnet_id" {
  description = "ID of the web subnet"
  value       = module.virtual_network.subnet_ids["web"]
}

output "app_subnet_id" {
  description = "ID of the app subnet"
  value       = module.virtual_network.subnet_ids["app"]
}

output "data_subnet_id" {
  description = "ID of the data subnet"
  value       = module.virtual_network.subnet_ids["data"]
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.virtual_network.subnet_ids["aks"]
}

output "gateway_subnet_id" {
  description = "ID of the gateway subnet"
  value       = module.virtual_network.subnet_ids["gateway"]
}

output "private_endpoints_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = module.virtual_network.subnet_ids["private_endpoints"]
}

# Network Security Groups
output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value = {
    for k, v in module.network_security_groups : k => v.id
  }
}

output "nsg_names" {
  description = "Map of NSG keys to their names"
  value = {
    for k, v in module.network_security_groups : k => v.name
  }
}

# Route Table
output "route_table_id" {
  description = "ID of the main route table"
  value       = azurerm_route_table.main.id
}

output "route_table_name" {
  description = "Name of the main route table"
  value       = azurerm_route_table.main.name
}

# Network Watcher
output "network_watcher_id" {
  description = "ID of the Network Watcher"
  value       = var.enable_network_watcher ? azurerm_network_watcher.main[0].id : null
}

# Application Gateway
output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = var.enable_application_gateway ? module.application_gateway[0].id : null
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = var.enable_application_gateway ? azurerm_public_ip.app_gateway[0].ip_address : null
}

output "application_gateway_public_ip_id" {
  description = "ID of the Application Gateway public IP"
  value       = var.enable_application_gateway ? azurerm_public_ip.app_gateway[0].id : null
}

# Private DNS Zones
output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to their IDs"
  value = {
    for k, v in azurerm_private_dns_zone.main : k => v.id
  }
}

output "private_dns_zone_names" {
  description = "List of private DNS zone names"
  value       = [for zone in azurerm_private_dns_zone.main : zone.name]
}

# Network Configuration Summary
output "network_summary" {
  description = "Summary of network configuration"
  value = {
    project_name        = var.project_name
    environment         = var.environment
    vnet_name          = module.virtual_network.name
    vnet_address_space = module.virtual_network.address_space
    subnet_count       = length(module.virtual_network.subnet_ids)
    nsg_count          = length(module.network_security_groups)
    private_dns_zones  = length(azurerm_private_dns_zone.main)
  }
}

# Tags
output "common_tags" {
  description = "Common tags applied to resources"
  value       = local.common_tags
}