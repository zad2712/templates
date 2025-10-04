# 🗄️ Azure SQL Database Module

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider~4.0-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

This module provisions Azure SQL Database with advanced security features, high availability, backup configuration, and monitoring capabilities for production workloads.

## 🎯 **Features**

- ✅ **Azure SQL Server** with advanced security configuration
- ✅ **SQL Databases** with elastic pools and performance tiers
- ✅ **High Availability** with zone redundancy and failover groups
- ✅ **Security** with transparent data encryption, threat detection, and auditing
- ✅ **Backup & Recovery** with automated backups and point-in-time restore
- ✅ **Monitoring** with diagnostics and performance insights
- ✅ **Private Connectivity** with private endpoints and VNet integration
- ✅ **Compliance** with advanced data security and vulnerability assessment

## 📋 **Requirements**

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | ~> 4.0 |
| random | ~> 3.6 |

## 🚀 **Usage Examples**

### **Basic SQL Database**

```hcl
module "sql_database" {
  source = "../../modules/rds"
  
  # Basic configuration
  server_name         = "myapp-dev-sql"
  resource_group_name = "myapp-dev-data-rg"
  location           = "East US"
  
  # Authentication
  administrator_login    = "sqladmin"
  administrator_password = var.sql_admin_password  # Use Key Vault reference
  
  # Basic database
  databases = {
    "app-db" = {
      collation      = "SQL_Latin1_General_CP1_CI_AS"
      license_type   = "LicenseIncluded"
      sku_name      = "S2"  # Standard S2 (50 DTU)
      max_size_gb   = 100
      
      tags = {
        Environment = "development"
        Application = "main-app"
      }
    }
  }
  
  # Basic security
  public_network_access_enabled = false  # Private access only
  
  tags = {
    Environment = "development"
    Project     = "myapp"
    Owner       = "dev-team@company.com"
  }
}
```

### **Production SQL Database with Advanced Features**

```hcl
module "sql_database" {
  source = "../../modules/rds"
  
  # Production server configuration
  server_name         = "myapp-prod-sql"
  resource_group_name = "myapp-prod-data-rg"
  location           = "East US"
  
  # SQL Server version and features
  version = "12.0"  # SQL Server 2019
  
  # Azure AD Authentication (recommended for production)
  azuread_authentication_only = true
  azuread_administrator = {
    login_username              = "sql-admins"
    object_id                   = "12345678-1234-1234-1234-123456789012"  # Azure AD group
    tenant_id                   = var.tenant_id
    azuread_authentication_only = true
  }
  
  # Production databases with different performance tiers
  databases = {
    # Primary application database
    "production-app-db" = {
      collation    = "SQL_Latin1_General_CP1_CI_AS"
      license_type = "BasePrice"  # Existing SQL Server licenses
      
      # Premium tier for production workloads
      sku_name    = "P4"          # Premium P4 (500 DTU)
      max_size_gb = 1000          # 1TB max size
      
      # High availability
      zone_redundant = true       # Zone-redundant for HA
      
      # Backup configuration
      short_term_retention_policy = {
        retention_days           = 35    # 35 days point-in-time restore
        backup_interval_in_hours = 12    # Backup every 12 hours
      }
      
      long_term_retention_policy = {
        weekly_retention  = "P12W"       # 12 weeks
        monthly_retention = "P12M"       # 12 months
        yearly_retention  = "P7Y"        # 7 years
        week_of_year     = 1            # Week 1 for yearly backup
      }
      
      # Performance and monitoring
      auto_pause_delay_in_minutes = null  # Always on for production
      
      threat_detection_policy = {
        state                = "Enabled"
        email_account_admins = true
        email_addresses     = ["dba-team@company.com", "security-team@company.com"]
        retention_days      = 90
        
        disabled_alerts = []  # Enable all threat detection
      }
      
      tags = {
        Environment = "production"
        Application = "main-app"
        Tier       = "primary"
        Backup     = "required"
      }
    }
    
    # Analytics/Reporting database
    "analytics-db" = {
      collation    = "SQL_Latin1_General_CP1_CI_AS"
      license_type = "BasePrice"
      
      # General Purpose tier for analytics
      sku_name    = "GP_Gen5_4"    # General Purpose, Gen5, 4 vCores
      max_size_gb = 2000           # 2TB for analytics data
      
      zone_redundant = false       # Cost optimization for analytics
      
      # Read scale-out for reporting queries
      read_scale = true
      
      short_term_retention_policy = {
        retention_days = 7         # Shorter retention for analytics
      }
      
      long_term_retention_policy = {
        weekly_retention  = "P4W"  # 4 weeks
        monthly_retention = "P6M"  # 6 months
        yearly_retention  = "P3Y"  # 3 years
      }
      
      tags = {
        Environment = "production"
        Application = "analytics"
        Tier       = "secondary"
      }
    }
  }
  
  # Advanced security features
  public_network_access_enabled = false  # Private access only
  
  # Private endpoint configuration
  private_endpoint = {
    enabled                        = true
    subnet_id                     = var.private_endpoint_subnet_id
    private_dns_zone_group_name   = "sqlserver"
    private_dns_zone_ids         = [var.sql_private_dns_zone_id]
    
    tags = {
      Environment = "production"
      Purpose     = "sql-private-access"
    }
  }
  
  # Advanced Threat Protection
  security_alert_policy = {
    state               = "Enabled"
    email_account_admins = true
    email_addresses     = [
      "dba-team@company.com",
      "security-team@company.com"
    ]
    retention_days = 90
    
    disabled_alerts = []  # Enable all alerts
  }
  
  # Transparent Data Encryption
  transparent_data_encryption = {
    enabled = true
    key_vault_key_id = var.tde_key_vault_key_id  # Customer-managed key
  }
  
  # Auditing
  auditing = {
    enabled = true
    
    log_analytics_workspace_id = var.log_analytics_workspace_id
    retention_in_days = 365
    
    audit_actions_and_groups = [
      "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP",
      "FAILED_DATABASE_AUTHENTICATION_GROUP",
      "BATCH_COMPLETED_GROUP"
    ]
  }
  
  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "data-team@company.com"
    CostCenter  = "data-infrastructure"
    Compliance  = "SOX,PCI-DSS"
    Backup     = "required"
  }
}
```

## 📊 **Input Variables**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `server_name` | Name of the SQL Server | `string` | n/a | yes |
| `resource_group_name` | Name of the resource group | `string` | n/a | yes |
| `location` | Azure region for resources | `string` | n/a | yes |
| `version` | SQL Server version | `string` | `"12.0"` | no |
| `administrator_login` | SQL Server administrator login | `string` | `null` | no |
| `administrator_password` | SQL Server administrator password | `string` | `null` | no |
| `azuread_administrator` | Azure AD administrator configuration | `object` | `null` | no |
| `databases` | Map of database configurations | `map(object)` | `{}` | no |
| `elastic_pools` | Map of elastic pool configurations | `map(object)` | `{}` | no |
| `failover_groups` | Map of failover group configurations | `map(object)` | `{}` | no |
| `firewall_rules` | Map of firewall rule configurations | `map(object)` | `{}` | no |
| `virtual_network_rules` | Map of VNet rule configurations | `map(object)` | `{}` | no |
| `private_endpoint` | Private endpoint configuration | `object` | `null` | no |
| `security_alert_policy` | Security alert policy configuration | `object` | `null` | no |
| `transparent_data_encryption` | TDE configuration | `object` | `null` | no |
| `auditing` | Database auditing configuration | `object` | `null` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## 📤 **Outputs**

| Name | Description |
|------|-------------|
| `server_id` | ID of the SQL Server |
| `server_name` | Name of the SQL Server |
| `server_fqdn` | Fully qualified domain name of the SQL Server |
| `database_ids` | Map of database names to IDs |
| `private_endpoint_id` | ID of the private endpoint (if created) |
| `private_endpoint_ip` | Private IP address of the private endpoint |
| `connection_strings` | Map of database connection strings |

---

**🔗 Related Modules**: [VPC](../vpc/README.md) | [Key Vault](../kms/README.md) | [Storage](../s3/README.md)