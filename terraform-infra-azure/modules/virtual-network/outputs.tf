# =============================================================================
# VIRTUAL NETWORK MODULE OUTPUTS
# =============================================================================

output "id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for k, v in azurerm_subnet.main : k => v.id
  }
}

output "subnet_names" {
  description = "Map of subnet keys to their names"
  value = {
    for k, v in azurerm_subnet.main : k => v.name
  }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value = {
    for k, v in azurerm_subnet.main : v.name => v.address_prefixes
  }
}

output "ddos_protection_plan_id" {
  description = "ID of the DDoS protection plan"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.main[0].id : null
}