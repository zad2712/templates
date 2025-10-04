# =============================================================================
# FUNCTION APP MODULE OUTPUTS
# =============================================================================

# Function App Outputs
output "function_app_id" {
  description = "ID of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = var.function_app_name
}

output "function_app_hostname" {
  description = "Default hostname of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].default_hostname : azurerm_windows_function_app.main[0].default_hostname
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${var.os_type == "Linux" ? azurerm_linux_function_app.main[0].default_hostname : azurerm_windows_function_app.main[0].default_hostname}"
}

output "function_app_kind" {
  description = "Kind of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].kind : azurerm_windows_function_app.main[0].kind
}

output "function_app_outbound_ip_addresses" {
  description = "Outbound IP addresses of the Function App"
  value       = var.os_type == "Linux" ? split(",", azurerm_linux_function_app.main[0].outbound_ip_addresses) : split(",", azurerm_windows_function_app.main[0].outbound_ip_addresses)
}

output "function_app_possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses of the Function App"
  value       = var.os_type == "Linux" ? split(",", azurerm_linux_function_app.main[0].possible_outbound_ip_addresses) : split(",", azurerm_windows_function_app.main[0].possible_outbound_ip_addresses)
}

# Identity Outputs
output "identity_principal_id" {
  description = "Principal ID of the Function App managed identity"
  value = var.identity_type != null ? (
    var.os_type == "Linux" ? 
    azurerm_linux_function_app.main[0].identity[0].principal_id : 
    azurerm_windows_function_app.main[0].identity[0].principal_id
  ) : null
}

output "identity_tenant_id" {
  description = "Tenant ID of the Function App managed identity"
  value = var.identity_type != null ? (
    var.os_type == "Linux" ? 
    azurerm_linux_function_app.main[0].identity[0].tenant_id : 
    azurerm_windows_function_app.main[0].identity[0].tenant_id
  ) : null
}

output "identity_type" {
  description = "Type of managed identity configured"
  value       = var.identity_type
}

# Storage Account Outputs
output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.function.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.function.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.function.primary_blob_endpoint
}

output "storage_account_primary_access_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.function.primary_access_key
  sensitive   = true
}

# App Service Plan Outputs
output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

output "app_service_plan_sku_name" {
  description = "SKU name of the App Service Plan"
  value       = azurerm_service_plan.main.sku_name
}

output "app_service_plan_os_type" {
  description = "OS type of the App Service Plan"
  value       = azurerm_service_plan.main.os_type
}

# Application Insights Outputs
output "application_insights_id" {
  description = "ID of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.function[0].id : null
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.function[0].name : null
}

output "application_insights_app_id" {
  description = "App ID of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.function[0].app_id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.function[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.function[0].connection_string : null
  sensitive   = true
}

# Staging Slot Outputs
output "staging_slot_id" {
  description = "ID of the staging slot"
  value       = var.enable_staging_slot && var.os_type == "Linux" ? azurerm_linux_function_app_slot.staging[0].id : null
}

output "staging_slot_hostname" {
  description = "Default hostname of the staging slot"
  value       = var.enable_staging_slot && var.os_type == "Linux" ? azurerm_linux_function_app_slot.staging[0].default_hostname : null
}

output "staging_slot_url" {
  description = "URL of the staging slot"
  value       = var.enable_staging_slot && var.os_type == "Linux" ? "https://${azurerm_linux_function_app_slot.staging[0].default_hostname}" : null
}

# Private Endpoint Outputs
output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

output "private_endpoint_fqdn" {
  description = "FQDN of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].custom_dns_configs[0].fqdn : null
}

# Configuration Outputs
output "function_app_configuration" {
  description = "Function App configuration summary"
  value = {
    name                    = var.function_app_name
    os_type                = var.os_type
    sku_name               = var.sku_name
    always_on              = var.always_on
    https_only             = var.https_only
    functions_version      = var.functions_extension_version
    vnet_integration       = var.subnet_id != null
    private_endpoint       = var.enable_private_endpoint
    application_insights   = var.enable_application_insights
    staging_slot          = var.enable_staging_slot
    managed_identity      = var.identity_type != null
  }
}

# Diagnostic Settings Outputs
output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting"
  value       = var.enable_diagnostic_settings ? azurerm_monitor_diagnostic_setting.main[0].id : null
}

# Function App Settings for CI/CD
output "function_app_publish_profile" {
  description = "Publish profile for CI/CD deployments"
  value = {
    resource_group_name = var.resource_group_name
    function_app_name   = var.function_app_name
    slot_name          = var.enable_staging_slot ? "staging" : null
  }
  sensitive = true
}

# Network Configuration
output "network_configuration" {
  description = "Network configuration summary"
  value = {
    subnet_id                = var.subnet_id
    private_endpoint_enabled = var.enable_private_endpoint
    public_access_enabled   = var.public_network_access_enabled
    vnet_route_all_enabled  = var.vnet_route_all_enabled
    ip_restrictions_count   = length(var.ip_restrictions)
    scm_ip_restrictions_count = length(var.scm_ip_restrictions)
  }
}