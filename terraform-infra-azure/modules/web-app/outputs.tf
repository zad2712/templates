# =============================================================================
# AZURE WEB APPLICATION MODULE - OUTPUTS
# =============================================================================

# =============================================================================
# APP SERVICE PLAN OUTPUTS
# =============================================================================

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

output "app_service_plan_kind" {
  description = "Kind of the App Service Plan"
  value       = azurerm_service_plan.main.kind
}

output "app_service_plan_reserved" {
  description = "Whether the App Service Plan is reserved (Linux)"
  value       = azurerm_service_plan.main.reserved
}

# =============================================================================
# WEB APP OUTPUTS
# =============================================================================

output "web_app_id" {
  description = "ID of the web app"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
}

output "web_app_name" {
  description = "Name of the web app"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
}

output "web_app_default_hostname" {
  description = "Default hostname of the web app"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname
}

output "web_app_kind" {
  description = "Kind of the web app"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].kind : azurerm_windows_web_app.main[0].kind
}

output "web_app_outbound_ip_addresses" {
  description = "Outbound IP addresses of the web app"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].outbound_ip_addresses : azurerm_windows_web_app.main[0].outbound_ip_addresses
}

output "web_app_possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses of the web app"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].possible_outbound_ip_addresses : azurerm_windows_web_app.main[0].possible_outbound_ip_addresses
}

output "web_app_site_credential" {
  description = "Site credentials for the web app"
  value = var.os_type == "Linux" ? {
    name     = azurerm_linux_web_app.main[0].site_credential[0].name
    password = azurerm_linux_web_app.main[0].site_credential[0].password
  } : {
    name     = azurerm_windows_web_app.main[0].site_credential[0].name
    password = azurerm_windows_web_app.main[0].site_credential[0].password
  }
  sensitive = true
}

# =============================================================================
# IDENTITY OUTPUTS
# =============================================================================

output "web_app_identity" {
  description = "Identity configuration of the web app"
  value = var.enable_managed_identity ? (
    var.os_type == "Linux" ? {
      type         = azurerm_linux_web_app.main[0].identity[0].type
      principal_id = azurerm_linux_web_app.main[0].identity[0].principal_id
      tenant_id    = azurerm_linux_web_app.main[0].identity[0].tenant_id
      identity_ids = azurerm_linux_web_app.main[0].identity[0].identity_ids
    } : {
      type         = azurerm_windows_web_app.main[0].identity[0].type
      principal_id = azurerm_windows_web_app.main[0].identity[0].principal_id
      tenant_id    = azurerm_windows_web_app.main[0].identity[0].tenant_id
      identity_ids = azurerm_windows_web_app.main[0].identity[0].identity_ids
    }
  ) : null
}

output "web_app_principal_id" {
  description = "Principal ID of the web app managed identity"
  value       = var.enable_managed_identity ? (var.os_type == "Linux" ? azurerm_linux_web_app.main[0].identity[0].principal_id : azurerm_windows_web_app.main[0].identity[0].principal_id) : null
}

output "web_app_tenant_id" {
  description = "Tenant ID of the web app managed identity"
  value       = var.enable_managed_identity ? (var.os_type == "Linux" ? azurerm_linux_web_app.main[0].identity[0].tenant_id : azurerm_windows_web_app.main[0].identity[0].tenant_id) : null
}

# =============================================================================
# CUSTOM DOMAIN OUTPUTS
# =============================================================================

output "custom_domain_verification_id" {
  description = "Custom domain verification ID"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].custom_domain_verification_id : azurerm_windows_web_app.main[0].custom_domain_verification_id
}

output "custom_domains" {
  description = "Map of custom domain bindings"
  value = {
    for domain, binding in azurerm_app_service_custom_hostname_binding.main : domain => {
      hostname    = binding.hostname
      ssl_state   = binding.ssl_state
      thumbprint  = binding.thumbprint
    }
  }
}

# =============================================================================
# APPLICATION INSIGHTS OUTPUTS
# =============================================================================

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].name : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

output "application_insights_app_id" {
  description = "App ID of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].app_id : null
}

# =============================================================================
# PRIVATE ENDPOINT OUTPUTS
# =============================================================================

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

output "private_endpoint_network_interface" {
  description = "Network interface of the private endpoint"
  value = var.enable_private_endpoint ? {
    id                = azurerm_private_endpoint.main[0].network_interface[0].id
    name              = azurerm_private_endpoint.main[0].network_interface[0].name
    private_ip_address = azurerm_private_endpoint.main[0].network_interface[0].private_ip_address
  } : null
}

# =============================================================================
# URL AND ENDPOINT OUTPUTS
# =============================================================================

output "web_app_url" {
  description = "URL of the web app"
  value       = "https://${var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname}"
}

output "web_app_scm_url" {
  description = "SCM URL of the web app"
  value       = "https://${var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname}.scm.azurewebsites.net"
}

output "web_app_ftp_url" {
  description = "FTP URL of the web app"
  value       = "ftp://${var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname}.ftp.azurewebsites.net"
}

# =============================================================================
# CONFIGURATION OUTPUTS
# =============================================================================

output "web_app_app_settings" {
  description = "Application settings of the web app"
  value       = var.app_settings
  sensitive   = true
}

output "web_app_connection_strings" {
  description = "Connection strings of the web app"
  value       = var.connection_strings
  sensitive   = true
}

output "web_app_site_config" {
  description = "Site configuration summary"
  value = {
    always_on          = var.always_on
    http2_enabled      = var.http2_enabled
    https_only         = var.https_only
    minimum_tls_version = var.minimum_tls_version
    ftps_state         = var.ftps_state
    websockets_enabled = var.websockets_enabled
    health_check_path  = var.health_check_path
  }
}

# =============================================================================
# DIAGNOSTIC OUTPUTS
# =============================================================================

output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting"
  value       = var.enable_diagnostic_settings ? azurerm_monitor_diagnostic_setting.main[0].id : null
}

# =============================================================================
# RESOURCE GROUP AND LOCATION
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "location" {
  description = "Location of the resources"
  value       = var.location
}

# =============================================================================
# SUMMARY OUTPUTS
# =============================================================================

output "web_app_summary" {
  description = "Summary of the web app deployment"
  value = {
    web_app_name           = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
    web_app_url           = "https://${var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname}"
    app_service_plan_name = azurerm_service_plan.main.name
    app_service_plan_sku  = var.sku_name
    os_type              = var.os_type
    resource_group_name  = var.resource_group_name
    location             = var.location
    https_only           = var.https_only
    managed_identity_enabled = var.enable_managed_identity
    private_endpoint_enabled = var.enable_private_endpoint
    application_insights_enabled = var.enable_application_insights
    custom_domains_count = length(var.custom_domains)
  }
}