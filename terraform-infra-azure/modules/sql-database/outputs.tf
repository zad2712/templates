# =============================================================================
# SQL DATABASE OUTPUTS
# =============================================================================

output "server_id" {
  description = "The ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "server_fqdn" {
  description = "The fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "server_version" {
  description = "The version of the SQL Server"
  value       = azurerm_mssql_server.main.version
}

output "administrator_login" {
  description = "The administrator username of the SQL Server"
  value       = azurerm_mssql_server.main.administrator_login
}

output "identity" {
  description = "The identity of the SQL Server"
  value = azurerm_mssql_server.main.identity != null ? {
    type         = azurerm_mssql_server.main.identity[0].type
    principal_id = azurerm_mssql_server.main.identity[0].principal_id
    tenant_id    = azurerm_mssql_server.main.identity[0].tenant_id
  } : null
}

output "databases" {
  description = "Map of databases created on the server"
  value = {
    for k, db in azurerm_mssql_database.main : k => {
      id                = db.id
      name             = db.name
      collation        = db.collation
      license_type     = db.license_type
      max_size_gb      = db.max_size_gb
      sku_name         = db.sku_name
      zone_redundant   = db.zone_redundant
      storage_account_type = db.storage_account_type
    }
  }
}

output "elastic_pools" {
  description = "Map of elastic pools created on the server"
  value = {
    for k, pool in azurerm_mssql_elasticpool.main : k => {
      id           = pool.id
      name         = pool.name
      max_size_gb  = pool.max_size_gb
      zone_redundant = pool.zone_redundant
      license_type = pool.license_type
    }
  }
}

output "firewall_rules" {
  description = "Map of firewall rules created for the server"
  value = {
    for k, rule in azurerm_mssql_firewall_rule.main : k => {
      id               = rule.id
      name            = rule.name
      start_ip_address = rule.start_ip_address
      end_ip_address   = rule.end_ip_address
    }
  }
}

output "virtual_network_rules" {
  description = "Map of virtual network rules created for the server"
  value = {
    for k, rule in azurerm_mssql_virtual_network_rule.main : k => {
      id        = rule.id
      name      = rule.name
      subnet_id = rule.subnet_id
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

output "azuread_administrator" {
  description = "The Azure AD administrator configuration"
  value = azurerm_mssql_server_microsoft_support_auditing_policy.main != null ? {
    login_username = azurerm_mssql_server.main.azuread_administrator[0].login_username
    object_id      = azurerm_mssql_server.main.azuread_administrator[0].object_id
    tenant_id      = azurerm_mssql_server.main.azuread_administrator[0].tenant_id
  } : null
}

output "failover_group" {
  description = "The failover group configuration"
  value = length(azurerm_mssql_failover_group.main) > 0 ? {
    id   = azurerm_mssql_failover_group.main[0].id
    name = azurerm_mssql_failover_group.main[0].name
    role = azurerm_mssql_failover_group.main[0].role
  } : null
}

output "connection_strings" {
  description = "Connection strings for the databases"
  value = {
    for k, db in azurerm_mssql_database.main : k => {
      ado_net = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${db.name};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      jdbc    = "jdbc:sqlserver://${azurerm_mssql_server.main.fully_qualified_domain_name}:1433;database=${db.name};user=${azurerm_mssql_server.main.administrator_login}@${azurerm_mssql_server.main.name};password={your_password_here};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
      odbc    = "Driver={ODBC Driver 17 for SQL Server};Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${db.name};Uid=${azurerm_mssql_server.main.administrator_login}@${azurerm_mssql_server.main.name};Pwd={your_password_here};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    }
  }
  sensitive = true
}

output "security_alert_policy" {
  description = "The security alert policy configuration"
  value = length(azurerm_mssql_server_security_alert_policy.main) > 0 ? {
    id    = azurerm_mssql_server_security_alert_policy.main[0].id
    state = azurerm_mssql_server_security_alert_policy.main[0].state
  } : null
}

output "vulnerability_assessment" {
  description = "The vulnerability assessment configuration"
  value = length(azurerm_mssql_server_vulnerability_assessment.main) > 0 ? {
    id = azurerm_mssql_server_vulnerability_assessment.main[0].id
  } : null
}