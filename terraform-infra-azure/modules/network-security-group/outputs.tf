# =============================================================================
# NETWORK SECURITY GROUP MODULE OUTPUTS
# =============================================================================

output "id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

output "name" {
  description = "Name of the network security group"
  value       = azurerm_network_security_group.main.name
}

output "location" {
  description = "Location of the network security group"
  value       = azurerm_network_security_group.main.location
}

output "resource_group_name" {
  description = "Resource group name of the network security group"
  value       = azurerm_network_security_group.main.resource_group_name
}

output "security_rule_names" {
  description = "List of security rule names"
  value       = [for rule in azurerm_network_security_rule.main : rule.name]
}