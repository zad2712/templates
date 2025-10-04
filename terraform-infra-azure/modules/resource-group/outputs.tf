# =============================================================================
# RESOURCE GROUP MODULE OUTPUTS
# =============================================================================

output "id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "tags" {
  description = "Tags applied to the resource group"
  value       = azurerm_resource_group.main.tags
}

output "lock_id" {
  description = "ID of the resource group lock"
  value       = var.enable_lock ? azurerm_management_lock.resource_group_lock[0].id : null
}