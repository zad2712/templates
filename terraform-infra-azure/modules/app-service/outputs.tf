# =============================================================================
# APP SERVICE MODULE OUTPUTS
# =============================================================================

# App Service Outputs
output "app_service_id" {
  description = "ID of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = var.app_service_name
}

output "app_service_hostname" {
  description = "Default hostname of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname}"
}

output "app_service_kind" {
  description = "Kind of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].kind : azurerm_windows_web_app.main[0].kind
}

output "app_service_outbound_ip_addresses" {
  description = "Outbound IP addresses of the App Service"
  value       = var.os_type == "Linux" ? split(",", azurerm_linux_web_app.main[0].outbound_ip_addresses) : split(",", azurerm_windows_web_app.main[0].outbound_ip_addresses)
}

output "app_service_possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses of the App Service"
  value       = var.os_type == "Linux" ? split(",", azurerm_linux_web_app.main[0].possible_outbound_ip_addresses) : split(",", azurerm_windows_web_app.main[0].possible_outbound_ip_addresses)
}

# Identity Outputs
output "identity_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value = var.identity_type != null ? (
    var.os_type == "Linux" ? 
    azurerm_linux_web_app.main[0].identity[0].principal_id : 
    azurerm_windows_web_app.main[0].identity[0].principal_id
  ) : null
}

output "identity_tenant_id" {
  description = "Tenant ID of the App Service managed identity"
  value = var.identity_type != null ? (
    var.os_type == "Linux" ? 
    azurerm_linux_web_app.main[0].identity[0].tenant_id : 
    azurerm_windows_web_app.main[0].identity[0].tenant_id
  ) : null
}

output "identity_type" {
  description = "Type of managed identity configured"
  value       = var.identity_type
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

output "app_service_plan_maximum_elastic_worker_count" {
  description = "Maximum number of elastic workers for the App Service Plan"
  value       = azurerm_service_plan.main.maximum_elastic_worker_count
}

# Staging Slot Outputs
output "staging_slot_id" {
  description = "ID of the staging slot"
  value = var.enable_staging_slot ? (
    var.os_type == "Linux" ? 
    azurerm_linux_web_app_slot.staging[0].id : 
    azurerm_windows_web_app_slot.staging[0].id
  ) : null
}

output "staging_slot_hostname" {
  description = "Default hostname of the staging slot"
  value = var.enable_staging_slot ? (
    var.os_type == "Linux" ? 
    azurerm_linux_web_app_slot.staging[0].default_hostname : 
    azurerm_windows_web_app_slot.staging[0].default_hostname
  ) : null
}

output "staging_slot_url" {
  description = "URL of the staging slot"
  value = var.enable_staging_slot ? (
    var.os_type == "Linux" ? 
    "https://${azurerm_linux_web_app_slot.staging[0].default_hostname}" : 
    "https://${azurerm_windows_web_app_slot.staging[0].default_hostname}"
  ) : null
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
output "app_service_configuration" {
  description = "App Service configuration summary"
  value = {
    name                    = var.app_service_name
    os_type                = var.os_type
    sku_name               = var.sku_name
    always_on              = var.always_on
    https_only             = var.https_only
    vnet_integration       = var.subnet_id != null
    private_endpoint       = var.enable_private_endpoint
    staging_slot          = var.enable_staging_slot
    managed_identity      = var.identity_type != null
    auto_heal_enabled     = var.auto_heal_enabled
  }
}

# Site Config Outputs
output "site_config" {
  description = "Site configuration details"
  value = {
    always_on                = var.always_on
    http2_enabled           = var.http2_enabled
    websockets_enabled      = var.websockets_enabled
    minimum_tls_version     = var.minimum_tls_version
    ftps_state             = var.ftps_state
    load_balancing_mode    = var.load_balancing_mode
    managed_pipeline_mode  = var.managed_pipeline_mode
    use_32_bit_worker      = var.use_32_bit_worker
    vnet_route_all_enabled = var.vnet_route_all_enabled
  }
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

# Security Configuration
output "security_configuration" {
  description = "Security configuration summary"
  value = {
    https_only                      = var.https_only
    client_certificate_enabled     = var.client_certificate_enabled
    client_certificate_mode        = var.client_certificate_mode
    minimum_tls_version            = var.minimum_tls_version
    scm_minimum_tls_version        = var.scm_minimum_tls_version
    remote_debugging_enabled       = var.remote_debugging_enabled
    ftps_state                     = var.ftps_state
  }
}

# Application Stack Information
output "application_stack_info" {
  description = "Application stack configuration"
  value = var.application_stack != null ? {
    os_type        = var.os_type
    dotnet_version = var.application_stack.dotnet_version
    java_version   = var.application_stack.java_version
    node_version   = var.application_stack.node_version
    php_version    = var.application_stack.php_version
    python_version = var.application_stack.python_version
    ruby_version   = var.application_stack.ruby_version
    go_version     = var.application_stack.go_version
    current_stack  = var.application_stack.current_stack
    docker_enabled = var.application_stack.docker != null
  } : null
}

# Diagnostic Settings Outputs
output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting"
  value       = var.enable_diagnostic_settings ? azurerm_monitor_diagnostic_setting.main[0].id : null
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information for CI/CD"
  value = {
    resource_group_name = var.resource_group_name
    app_service_name    = var.app_service_name
    app_service_plan_name = var.app_service_plan_name
    os_type            = var.os_type
    staging_slot_name  = var.enable_staging_slot ? "staging" : null
    scm_site_hostname  = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].site_config[0].scm_type : azurerm_windows_web_app.main[0].site_config[0].scm_type
  }
  sensitive = true
}

# Custom Domain Support
output "custom_domain_verification_id" {
  description = "Custom domain verification ID"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].custom_domain_verification_id : azurerm_windows_web_app.main[0].custom_domain_verification_id
}

# Resource Location and Tags
output "resource_details" {
  description = "Resource location and tags"
  value = {
    location           = var.location
    resource_group_name = var.resource_group_name
    tags              = var.tags
  }
}

# Backup Configuration Status
output "backup_configuration" {
  description = "Backup configuration status"
  value = var.backup != null ? {
    enabled               = var.backup.enabled
    name                 = var.backup.name
    frequency_interval   = var.backup.schedule.frequency_interval
    frequency_unit       = var.backup.schedule.frequency_unit
    retention_period_days = var.backup.schedule.retention_period_days
  } : null
}