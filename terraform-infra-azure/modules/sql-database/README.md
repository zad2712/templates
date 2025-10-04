# Azure SQL Database Module

This Terraform module creates and manages Azure SQL Database resources with comprehensive configuration options and enterprise features.

## Features

- **SQL Server**: Managed SQL Server with security configurations
- **SQL Databases**: Multiple database support with flexible configurations  
- **Security**: Private endpoints, firewall rules, threat protection
- **Monitoring**: Diagnostic settings and auditing
- **Identity**: Azure AD integration and managed identity support
- **Backup**: Automated backup and point-in-time restore
- **Performance**: Configurable service tiers and compute models
- **Compliance**: Transparent Data Encryption (TDE) and auditing

## Usage

### Basic Example

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  server_name         = "my-sql-server"
  location            = "East US"
  resource_group_name = "my-rg"

  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  databases = {
    "app-db" = {
      collation        = "SQL_Latin1_General_CP1_CI_AS"
      license_type     = "LicenseIncluded"
      max_size_gb      = 250
      sku_name         = "S1"
      zone_redundant   = false
      read_scale       = false
      read_replica_count = 0
    }
  }

  tags = {
    Environment = "dev"
    Project     = "myproject"
  }
}
```

### Advanced Example with Security Features

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  server_name         = "my-sql-server"
  location            = "East US"
  resource_group_name = "my-rg"

  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"
  sql_server_version          = "12.0"
  minimum_tls_version         = "1.2"
  public_network_access_enabled = false

  # Azure AD Integration
  enable_azure_ad_administrator = true
  azure_ad_administrator = {
    login_username              = "admin@company.com"
    object_id                   = "00000000-0000-0000-0000-000000000000"
    tenant_id                   = "11111111-1111-1111-1111-111111111111"
    azuread_authentication_only = false
  }

  # Managed Identity
  enable_identity = true
  identity_type   = "SystemAssigned"

  # Security features
  enable_threat_detection_policy = true
  threat_detection_policy = {
    state                      = "Enabled"
    disabled_alerts           = []
    email_account_admins      = "Enabled"
    email_addresses           = ["security@company.com"]
    retention_days            = 30
    storage_account_access_key = null
    storage_endpoint          = null
  }

  # Firewall rules
  firewall_rules = {
    "AllowAzureServices" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
    "OfficeNetwork" = {
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    }
  }

  # Databases
  databases = {
    "production-db" = {
      collation           = "SQL_Latin1_General_CP1_CI_AS"
      license_type        = "LicenseIncluded"
      max_size_gb         = 1024
      sku_name           = "P2"
      zone_redundant     = true
      read_scale         = true
      read_replica_count = 2
      auto_pause_delay_in_minutes = null
      min_capacity       = null
    }
    "staging-db" = {
      collation           = "SQL_Latin1_General_CP1_CI_AS"
      license_type        = "LicenseIncluded" 
      max_size_gb         = 250
      sku_name           = "S2"
      zone_redundant     = false
      read_scale         = false
      read_replica_count = 0
    }
  }

  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
  private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.database.windows.net"

  # Diagnostic settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = "/subscriptions/.../workspaces/my-workspace"
  diagnostic_settings = {
    logs = [
      "SQLInsights",
      "AutomaticTuning",
      "QueryStoreRuntimeStatistics",
      "QueryStoreWaitStatistics",
      "Errors",
      "DatabaseWaitStatistics",
      "Timeouts",
      "Blocks",
      "Deadlocks"
    ]
    metrics = [
      "Basic",
      "InstanceAndAppAdvanced",
      "WorkloadManagement"
    ]
  }

  tags = {
    Environment = "production"
    Project     = "myproject"
    Owner       = "platform-team"
  }
}
```

### Serverless SQL Database Example

```hcl
module "serverless_sql" {
  source = "../../modules/sql-database"

  server_name         = "my-serverless-sql"
  location            = "East US"
  resource_group_name = "my-rg"

  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  databases = {
    "serverless-db" = {
      collation                   = "SQL_Latin1_General_CP1_CI_AS"
      license_type               = "LicenseIncluded"
      max_size_gb                = 32
      sku_name                   = "GP_S_Gen5_1"
      zone_redundant             = false
      auto_pause_delay_in_minutes = 60
      min_capacity               = 0.5
      read_scale                 = false
      read_replica_count         = 0
    }
  }

  tags = {
    Environment = "dev"
    Project     = "serverless-app"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | >= 3.116.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.116.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_mssql_server.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_mssql_database.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) | resource |
| [azurerm_mssql_server_security_alert_policy.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_security_alert_policy) | resource |
| [azurerm_mssql_firewall_rule.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_firewall_rule) | resource |
| [azurerm_private_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_monitor_diagnostic_setting.server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| server_name | Name of the SQL Server | `string` |
| location | Azure region where resources will be created | `string` |
| resource_group_name | Name of the resource group | `string` |
| administrator_login | SQL Server administrator login | `string` |
| administrator_login_password | SQL Server administrator password | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| sql_server_version | SQL Server version | `string` | `"12.0"` |
| minimum_tls_version | Minimum TLS version | `string` | `"1.2"` |
| public_network_access_enabled | Enable public network access | `bool` | `true` |
| connection_policy | Connection policy for the SQL Server | `string` | `"Default"` |
| enable_identity | Enable managed identity | `bool` | `false` |
| identity_type | Type of managed identity | `string` | `"SystemAssigned"` |
| databases | Map of database configurations | `map(object)` | `{}` |
| firewall_rules | Map of firewall rules | `map(object)` | `{}` |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` |
| enable_diagnostic_settings | Enable diagnostic settings | `bool` | `false` |
| tags | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| sql_server_id | ID of the SQL Server |
| sql_server_name | Name of the SQL Server |
| sql_server_fqdn | FQDN of the SQL Server |
| sql_server_identity | Managed identity of the SQL Server |
| databases | Map of created databases |
| private_endpoint_id | ID of the private endpoint |
| connection_strings | Connection strings for databases |

## Database SKU Configuration

### Basic Tier
- **Basic**: B (5 DTU to 5 DTU)

### Standard Tier  
- **S0**: 10 DTU
- **S1**: 20 DTU  
- **S2**: 50 DTU
- **S3**: 100 DTU
- **S4, S6, S7, S9, S12**: 200-3000 DTU

### Premium Tier
- **P1**: 125 DTU
- **P2**: 250 DTU
- **P4**: 500 DTU  
- **P6**: 1000 DTU
- **P11**: 1750 DTU
- **P15**: 4000 DTU

### General Purpose (vCore)
- **GP_Gen5_2**: 2 vCores
- **GP_Gen5_4**: 4 vCores
- **GP_Gen5_8**: 8 vCores
- **GP_Gen5_16**: 16 vCores
- **GP_Gen5_32**: 32 vCores
- **GP_Gen5_80**: 80 vCores

### Business Critical (vCore)
- **BC_Gen5_2**: 2 vCores
- **BC_Gen5_4**: 4 vCores  
- **BC_Gen5_8**: 8 vCores
- **BC_Gen5_16**: 16 vCores
- **BC_Gen5_32**: 32 vCores
- **BC_Gen5_80**: 80 vCores

### Serverless (vCore)
- **GP_S_Gen5_1**: 0.5-1 vCore
- **GP_S_Gen5_2**: 0.5-2 vCore
- **GP_S_Gen5_4**: 0.5-4 vCore
- **GP_S_Gen5_6**: 0.75-6 vCore
- **GP_S_Gen5_8**: 1.0-8 vCore
- **GP_S_Gen5_10**: 1.25-10 vCore
- **GP_S_Gen5_16**: 2.0-16 vCore
- **GP_S_Gen5_32**: 4.0-32 vCore
- **GP_S_Gen5_40**: 5.0-40 vCore

## Security Configuration

### Threat Detection Policy

```hcl
threat_detection_policy = {
  state                      = "Enabled"
  disabled_alerts           = ["Sql_Injection", "Sql_Injection_Vulnerability"]
  email_account_admins      = "Enabled"
  email_addresses           = ["security@company.com", "dba@company.com"]
  retention_days            = 30
  storage_account_access_key = var.security_storage_access_key
  storage_endpoint          = var.security_storage_endpoint
}
```

### Azure AD Administrator

```hcl
azure_ad_administrator = {
  login_username              = "admin@company.com"
  object_id                   = "00000000-0000-0000-0000-000000000000"
  tenant_id                   = "11111111-1111-1111-1111-111111111111"
  azuread_authentication_only = true
}
```

### Firewall Rules

```hcl
firewall_rules = {
  "AllowAzureServices" = {
    start_ip_address = "0.0.0.0"
    end_ip_address   = "0.0.0.0"
  }
  "CompanyHQ" = {
    start_ip_address = "203.0.113.0"
    end_ip_address   = "203.0.113.255"
  }
  "DevTeam" = {
    start_ip_address = "198.51.100.50"
    end_ip_address   = "198.51.100.60"
  }
}
```

## Monitoring and Diagnostics

The module supports comprehensive diagnostic settings for both server and database levels:

### Server Logs
- DevOpsOperationsAudit
- SQLSecurityAuditEvents

### Database Logs  
- SQLInsights
- AutomaticTuning
- QueryStoreRuntimeStatistics
- QueryStoreWaitStatistics
- Errors
- DatabaseWaitStatistics
- Timeouts
- Blocks
- Deadlocks

### Metrics
- Basic
- InstanceAndAppAdvanced  
- WorkloadManagement

## Best Practices

1. **Security**: Use private endpoints in production environments
2. **Authentication**: Enable Azure AD integration and consider AD-only authentication
3. **Monitoring**: Enable diagnostic settings and threat detection
4. **Performance**: Choose appropriate SKU based on workload requirements
5. **Backup**: Configure backup retention policies for compliance needs
6. **Network**: Use firewall rules to restrict access to known IP ranges
7. **Encryption**: Enable TDE (Transparent Data Encryption) for data at rest
8. **Access**: Use managed identities for application connectivity where possible

## Troubleshooting

### Common Issues

1. **Connection timeouts**: Check firewall rules and private endpoint configuration
2. **Authentication failures**: Verify Azure AD configuration and user permissions  
3. **Performance issues**: Monitor DTU/vCore utilization and consider scaling
4. **Backup issues**: Check backup retention settings and storage configuration

### Useful Queries

```sql
-- Check database size
SELECT 
    DB_NAME() AS DatabaseName,
    CAST(SUM(size) * 8.0 / 1024 AS DECIMAL(10,2)) AS SizeMB
FROM sys.database_files;

-- Monitor active connections
SELECT 
    DB_NAME(dbid) AS DatabaseName,
    COUNT(dbid) AS ConnectionCount
FROM sys.sysprocesses
WHERE dbid > 0
GROUP BY dbid;
```

## License

This module is licensed under the MIT License. See LICENSE file for details.