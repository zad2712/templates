# =============================================================================
# APPLICATION GATEWAY MODULE OUTPUTS
# =============================================================================

output "id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "backend_address_pool_id" {
  description = "ID of the default backend address pool"
  value       = tolist(azurerm_application_gateway.main.backend_address_pool)[0].id
}

output "waf_policy_id" {
  description = "ID of the WAF policy"
  value       = var.waf_enabled && var.sku_tier == "WAF_v2" ? azurerm_web_application_firewall_policy.main[0].id : null
}

output "frontend_ip_configuration" {
  description = "Frontend IP configuration of the Application Gateway"
  value = {
    name                 = tolist(azurerm_application_gateway.main.frontend_ip_configuration)[0].name
    public_ip_address_id = tolist(azurerm_application_gateway.main.frontend_ip_configuration)[0].public_ip_address_id
  }
}