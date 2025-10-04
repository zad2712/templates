# 🔒 Security Layer - Identity, Encryption & Compliance

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider~4.0-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

The **Security Layer** implements comprehensive security controls including identity management, encryption, secrets management, and compliance monitoring. This layer establishes the zero-trust security foundation for all other infrastructure components.

## 🎯 **Layer Overview**

> **Purpose**: Establish identity, encryption, secrets management, and security monitoring  
> **Dependencies**: Networking Layer → **Security Layer** → Data Layer → Compute Layer  
> **Deployment Time**: ~5-8 minutes  
> **Resources**: Key Vault, Managed Identities, Log Analytics, Application Insights, Security Center

## 🏗️ **Architecture Components**

### **🔑 Azure Key Vault**
- **Secrets Management**: Centralized storage for passwords, connection strings, certificates
- **Key Management**: Hardware Security Module (HSM) backed encryption keys
- **Certificate Management**: Automated SSL/TLS certificate provisioning and rotation
- **Access Control**: RBAC and access policies with audit logging

### **🆔 Managed Identities**
- **System-Assigned**: Automatically managed identities for Azure resources
- **User-Assigned**: Shared identities across multiple resources
- **Azure AD Integration**: Seamless authentication without stored credentials
- **RBAC Integration**: Fine-grained access control across Azure services

### **📊 Log Analytics Workspace**
- **Centralized Logging**: Unified log collection from all Azure resources
- **Query Engine**: KQL-based log analysis and alerting
- **Data Retention**: Configurable retention policies for compliance
- **Integration**: Security Center, Sentinel, and monitoring solutions

### **💡 Application Insights**
- **Application Performance Monitoring**: Real-time performance metrics
- **Distributed Tracing**: End-to-end transaction tracking
- **Custom Telemetry**: Application-specific metrics and events
- **Alerting**: Proactive issue detection and notification

### **🛡️ Azure Security Center**
- **Security Posture**: Continuous security assessment and recommendations
- **Threat Protection**: Advanced threat detection and response
- **Compliance Dashboard**: Regulatory compliance monitoring
- **Just-in-Time Access**: Temporary elevated access controls

## 📋 **Security Services Overview**

| Service | Purpose | Encryption | Compliance | Private Access | Audit Logging |
|---------|---------|------------|------------|----------------|---------------|
| 🔑 **Key Vault** | Secrets & keys management | HSM-backed | ✅ | ✅ | ✅ |
| 🆔 **Managed Identity** | Service authentication | N/A | ✅ | N/A | ✅ |
| 📊 **Log Analytics** | Centralized logging | ✅ | ✅ | ✅ | ✅ |
| 💡 **App Insights** | Application monitoring | ✅ | ✅ | ✅ | ✅ |
| 🛡️ **Security Center** | Security monitoring | N/A | ✅ | N/A | ✅ |
| 📋 **Azure Policy** | Governance & compliance | N/A | ✅ | N/A | ✅ |

## 🚀 **Quick Start**

### **1. Deploy Complete Security Layer**

```bash
# Deploy all security services
cd layers/security/environments/dev
terraform init -backend-config=backend.conf
terraform plan -var-file=terraform.auto.tfvars
terraform apply -var-file=terraform.auto.tfvars

# Or use the management script
./terraform-manager.sh deploy-security dev
```

### **2. Deploy Specific Components**

```bash
# Deploy only Key Vault and Managed Identities
terraform apply -target=module.key_vault -target=module.managed_identity -var-file=terraform.auto.tfvars

# Deploy monitoring components
terraform apply -target=module.log_analytics -target=module.application_insights -var-file=terraform.auto.tfvars
```

## 🔧 **Configuration Examples**

### **🔑 Production Key Vault**

```hcl
# terraform.auto.tfvars
key_vault_sku                     = "premium"      # Premium tier with HSM
key_vault_soft_delete_retention_days = 90          # 90-day recovery window
key_vault_purge_protection_enabled = true          # Prevent permanent deletion
key_vault_enable_rbac_authorization = true         # Use RBAC for access control
key_vault_public_network_access_enabled = false    # Private access only

# Network Access Control Lists
key_vault_enable_network_acls = true
key_vault_allowed_ips        = [
  "203.0.113.0/24",                                # Corporate network
  "198.51.100.0/24"                               # Management network
]
key_vault_allowed_subnets    = []                  # Use private endpoints instead

# Private endpoint configuration
key_vault_enable_private_endpoint = true

# Diagnostic logging
key_vault_diagnostic_logs = [
  "AuditEvent",                                    # Access audit logs
  "AzurePolicyEvaluationDetails"                  # Policy compliance logs
]

key_vault_diagnostic_metrics = [
  "AllMetrics"                                     # Performance metrics
]

# Production secrets with secure references
key_vault_secrets = {
  # Database connection strings
  "sql-connection-string" = {
    value        = "Server=tcp:myproject-prod-sql.database.windows.net,1433;Database=prod-app-db;Authentication=Active Directory Managed Identity;"
    content_type = "application/x-sql-connection"
    expiration_date = null                         # No expiration for infrastructure secrets
    
    tags = {
      Environment = "production"
      Service     = "database"
      Compliance  = "PCI-DSS"
    }
  }
  
  # API keys and service credentials
  "external-api-key" = {
    value        = "your-secure-api-key-here"
    content_type = "text/plain"
    expiration_date = "2025-12-31T23:59:59Z"      # Annual rotation
    
    tags = {
      Environment = "production"
      Service     = "external-integration"
      Owner       = "api-team@mycompany.com"
    }
  }
  
  # Azure AD application secrets
  "aad-client-secret" = {
    value        = "your-aad-client-secret"
    content_type = "text/plain"
    expiration_date = "2025-06-30T23:59:59Z"      # Semi-annual rotation
    
    tags = {
      Environment = "production"
      Service     = "authentication"
      Compliance  = "SOC2"
    }
  }
  
  # Storage account keys (when managed identity not possible)
  "storage-account-key" = {
    value        = "@Microsoft.Storage/storageAccounts/myprojectprodstorage/keys/key1"
    content_type = "text/plain"
    expiration_date = null
    
    tags = {
      Environment = "production"
      Service     = "storage"
      AutoRotate  = "true"
    }
  }
  
  # Custom application configuration
  "jwt-signing-key" = {
    value        = "your-jwt-signing-key"
    content_type = "application/x-certificate"
    expiration_date = "2025-12-31T23:59:59Z"
    
    tags = {
      Environment = "production"
      Service     = "authentication"
      KeyType     = "signing"
    }
  }
}

# Encryption keys for data protection
key_vault_keys = {
  # Primary data encryption key
  "data-encryption-key" = {
    key_type = "RSA-HSM"                          # Hardware Security Module
    key_size = 4096                               # 4096-bit key
    key_opts = [
      "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"
    ]
    expiration_date = null                         # No expiration for infrastructure keys
    
    tags = {
      Environment = "production"
      Purpose     = "data-encryption"
      Compliance  = "FIPS-140-2-Level-3"
    }
  }
  
  # Backup encryption key for disaster recovery
  "backup-encryption-key" = {
    key_type = "RSA-HSM"
    key_size = 4096
    key_opts = ["decrypt", "encrypt", "unwrapKey", "wrapKey"]
    expiration_date = null
    
    tags = {
      Environment = "production"
      Purpose     = "backup-encryption"
      Owner       = "backup-team@mycompany.com"
    }
  }
  
  # Document signing key for digital signatures
  "document-signing-key" = {
    key_type = "EC-HSM"                           # Elliptic Curve for signatures
    curve    = "P-384"                            # NIST P-384 curve
    key_opts = ["sign", "verify"]
    expiration_date = "2026-12-31T23:59:59Z"      # 2-year rotation
    
    tags = {
      Environment = "production"
      Purpose     = "document-signing"
      Compliance  = "eIDAS"
    }
  }
}

# SSL/TLS certificates for custom domains
key_vault_certificates = {
  # Production application certificate
  "production-app-cert" = {
    certificate_policy = {
      issuer_parameters = {
        name = "DigiCert"                         # External CA for production
      }
      
      key_properties = {
        exportable = false                        # Non-exportable for security
        key_size   = 4096                         # 4096-bit RSA
        key_type   = "RSA"
        reuse_key  = false                        # Generate new key on renewal
      }
      
      lifetime_actions = [
        {
          action = {
            action_type = "AutoRenew"             # Automatic renewal
          }
          trigger = {
            days_before_expiry = 30               # Renew 30 days before expiry
          }
        },
        {
          action = {
            action_type = "EmailContacts"         # Email notification
          }
          trigger = {
            days_before_expiry = 45               # Notify 45 days before expiry
          }
        }
      ]
      
      secret_properties = {
        content_type = "application/x-pkcs12"     # PKCS#12 format
      }
      
      x509_certificate_properties = {
        key_usage = [
          "digitalSignature",
          "keyEncipherment"
        ]
        
        extended_key_usage = [
          "1.3.6.1.5.5.7.3.1",                  # Server Authentication
          "1.3.6.1.5.5.7.3.2"                   # Client Authentication
        ]
        
        subject = "CN=app.mycompany.com,O=MyCompany Inc,L=Seattle,ST=WA,C=US"
        validity_in_months = 24                   # 2-year validity
        
        subject_alternative_names = {
          dns_names = [
            "app.mycompany.com",
            "www.app.mycompany.com",
            "api.mycompany.com",
            "admin.mycompany.com"
          ]
          
          emails = [
            "ssl-admin@mycompany.com"
          ]
        }
      }
    }
    
    tags = {
      Environment = "production"
      Service     = "web-application"
      Owner       = "security-team@mycompany.com"
    }
  }
  
  # Internal services certificate
  "internal-services-cert" = {
    certificate_policy = {
      issuer_parameters = {
        name = "Self"                             # Self-signed for internal
      }
      
      key_properties = {
        exportable = true
        key_size   = 2048
        key_type   = "RSA"
        reuse_key  = true
      }
      
      lifetime_actions = [
        {
          action = {
            action_type = "AutoRenew"
          }
          trigger = {
            days_before_expiry = 14
          }
        }
      ]
      
      secret_properties = {
        content_type = "application/x-pkcs12"
      }
      
      x509_certificate_properties = {
        key_usage = [
          "digitalSignature",
          "keyEncipherment"
        ]
        
        subject = "CN=internal.mycompany.local"
        validity_in_months = 12
        
        subject_alternative_names = {
          dns_names = [
            "internal.mycompany.local",
            "*.internal.mycompany.local"
          ]
        }
      }
    }
  }
}
```

### **🆔 Production Managed Identities**

```hcl
managed_identities = {
  # Azure Kubernetes Service identity
  "aks" = {
    name = "myproject-prod-aks-identity"
    
    tags = {
      Service     = "AKS"
      Environment = "production"
      Owner       = "platform-team@mycompany.com"
    }
  }
  
  # Azure Functions identity
  "function-app" = {
    name = "myproject-prod-func-identity"
    
    tags = {
      Service     = "Functions"
      Environment = "production"
      Owner       = "backend-team@mycompany.com"
    }
  }
  
  # Web Application identity
  "web-app" = {
    name = "myproject-prod-webapp-identity"
    
    tags = {
      Service     = "WebApp"
      Environment = "production"
      Owner       = "frontend-team@mycompany.com"
    }
  }
  
  # Data services identity
  "data-services" = {
    name = "myproject-prod-data-identity"
    
    tags = {
      Service     = "Data"
      Environment = "production"
      Owner       = "data-team@mycompany.com"
    }
  }
  
  # Backup services identity
  "backup" = {
    name = "myproject-prod-backup-identity"
    
    tags = {
      Service     = "Backup"
      Environment = "production"
      Owner       = "ops-team@mycompany.com"
    }
  }
  
  # Monitoring services identity
  "monitoring" = {
    name = "myproject-prod-monitor-identity"
    
    tags = {
      Service     = "Monitoring"
      Environment = "production"
      Owner       = "sre-team@mycompany.com"
    }
  }
}
```

### **📊 Production Log Analytics & Monitoring**

```hcl
# Log Analytics Workspace configuration
log_analytics_sku               = "PerGB2018"      # Pay-per-GB pricing
log_analytics_retention_in_days = 730              # 2 years retention for compliance
log_analytics_daily_quota_gb    = 500              # 500GB daily ingestion limit

# Application Insights configuration
application_insights_type                = "web"
application_insights_retention_in_days   = 730     # 2 years retention
application_insights_daily_data_cap_in_gb = 100    # 100GB daily cap
application_insights_daily_data_cap_notifications_disabled = false

# Advanced monitoring features
enable_monitoring = true
enable_diagnostic_settings = true

# Monitoring solutions to enable
monitoring_solutions = [
  "Security",                                      # Security monitoring
  "Updates",                                       # Update management
  "ChangeTracking",                               # Change tracking
  "VMInsights",                                   # Virtual machine insights
  "ContainerInsights",                            # Container monitoring
  "ServiceMap",                                   # Application dependency mapping
  "InfrastructureInsights",                       # Infrastructure monitoring
  "NetworkMonitoring",                            # Network performance monitoring
  "AzureActivity",                                # Azure activity logs
  "KeyVaultAnalytics"                            # Key Vault analytics
]

# Custom log retention policies
log_retention_policies = {
  "SecurityEvent" = 2555                          # 7 years for security events
  "AuditLogs" = 2555                             # 7 years for audit logs
  "SigninLogs" = 365                             # 1 year for sign-in logs
  "PerformanceCounters" = 90                      # 90 days for performance data
  "ApplicationLogs" = 365                         # 1 year for application logs
  "SystemLogs" = 180                             # 6 months for system logs
}

# Alert rules for security monitoring
security_alert_rules = {
  "failed-login-attempts" = {
    name               = "Multiple Failed Login Attempts"
    description        = "Alert on multiple failed login attempts from single IP"
    frequency          = "PT5M"                   # Check every 5 minutes
    time_window        = "PT15M"                  # 15-minute window
    severity          = 1                         # Critical
    
    query = <<-EOT
      SigninLogs
      | where TimeGenerated > ago(15m)
      | where ResultType != "0"
      | summarize FailedAttempts = count() by IPAddress, UserPrincipalName
      | where FailedAttempts > 5
    EOT
    
    trigger = {
      operator  = "GreaterThan"
      threshold = 0
    }
    
    action_groups = ["security-alerts", "soc-team"]
  }
  
  "privileged-role-assignment" = {
    name               = "Privileged Role Assignment"
    description        = "Alert on privileged role assignments"
    frequency          = "PT1M"                   # Check every minute
    time_window        = "PT5M"                   # 5-minute window
    severity          = 1                         # Critical
    
    query = <<-EOT
      AuditLogs
      | where TimeGenerated > ago(5m)
      | where OperationName == "Add member to role"
      | where TargetResources has_any ("Global Administrator", "Privileged Role Administrator", "Security Administrator")
    EOT
    
    action_groups = ["security-alerts", "admin-team"]
  }
  
  "key-vault-access" = {
    name               = "Unusual Key Vault Access"
    description        = "Alert on unusual Key Vault access patterns"
    frequency          = "PT10M"                  # Check every 10 minutes
    time_window        = "PT30M"                  # 30-minute window
    severity          = 2                         # Warning
    
    query = <<-EOT
      KeyVaultData
      | where TimeGenerated > ago(30m)
      | where OperationName == "SecretGet"
      | summarize AccessCount = count() by CallerIPAddress, Identity_s
      | where AccessCount > 50
    EOT
    
    action_groups = ["security-alerts"]
  }
}
```

## 🔐 **Security Policies & Compliance**

### **Azure Policy Definitions**

```hcl
# Azure Policy assignments for security compliance
security_policies = {
  "require-encryption-in-transit" = {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
    display_name        = "Secure transfer to storage accounts should be enabled"
    description         = "Audit requirement of Secure transfer in your storage account"
    
    parameters = {
      effect = {
        value = "Audit"
      }
    }
  }
  
  "require-key-vault-soft-delete" = {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
    display_name        = "Key vaults should have soft delete enabled"
    description         = "This policy audits any key vault which does not have soft delete enabled"
    
    parameters = {
      effect = {
        value = "Audit"
      }
    }
  }
  
  "require-diagnostic-settings" = {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/7f89b1eb-583c-429a-8828-af049802c1d9"
    display_name        = "Audit diagnostic setting"
    description         = "Audit diagnostic setting for selected resource types"
    
    parameters = {
      effect = {
        value = "AuditIfNotExists"
      }
      logAnalytics = {
        value = "/subscriptions/{subscription-id}/resourceGroups/myproject-prod-security-rg/providers/Microsoft.OperationalInsights/workspaces/myproject-prod-law"
      }
    }
  }
}
```

### **RBAC Role Assignments**

```bash
# Key Vault access roles
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id "12345678-1234-1234-1234-123456789012" \
  --assignee-principal-type "ServicePrincipal" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/myproject-prod-security-rg/providers/Microsoft.KeyVault/vaults/myproject-prod-kv"

# Storage Blob Data access
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "12345678-1234-1234-1234-123456789012" \
  --assignee-principal-type "ServicePrincipal" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/myproject-prod-data-rg/providers/Microsoft.Storage/storageAccounts/myprojectprodstorage"

# Log Analytics access for monitoring
az role assignment create \
  --role "Log Analytics Contributor" \
  --assignee-object-id "87654321-4321-4321-4321-210987654321" \
  --assignee-principal-type "ServicePrincipal" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/myproject-prod-security-rg/providers/Microsoft.OperationalInsights/workspaces/myproject-prod-law"
```

## 📊 **Security Monitoring & Alerting**

### **Security Center Configuration**

```bash
# Enable Security Center Standard tier
az security pricing create \
  --name "VirtualMachines" \
  --tier "Standard"

az security pricing create \
  --name "StorageAccounts" \
  --tier "Standard"

az security pricing create \
  --name "SqlServers" \
  --tier "Standard"

az security pricing create \
  --name "KeyVaults" \
  --tier "Standard"

# Configure security contacts
az security contact create \
  --email "security@mycompany.com" \
  --phone "+1-555-123-4567" \
  --alert-notifications "On" \
  --alerts-to-admins "On"
```

### **Custom KQL Queries for Security Monitoring**

```kusto
// Failed authentication attempts
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType != "0"
| summarize FailedCount = count() by UserPrincipalName, IPAddress, AppDisplayName
| where FailedCount > 3
| sort by FailedCount desc

// Privileged operations
AuditLogs
| where TimeGenerated > ago(24h)
| where Category == "RoleManagement"
| where OperationName has_any ("Add", "Delete", "Update")
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
| sort by TimeGenerated desc

// Key Vault secret access
KeyVaultData
| where TimeGenerated > ago(1h)
| where OperationName == "SecretGet"
| summarize AccessCount = count() by bin(TimeGenerated, 5m), Identity_s
| render timechart

// Unusual network traffic
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| where FlowType_s == "ExternalPublic"
| summarize TotalFlows = count() by SrcIP_s, DestIP_s
| where TotalFlows > 1000
| sort by TotalFlows desc

// Resource modifications
AzureActivity
| where TimeGenerated > ago(1h)
| where OperationNameValue has_any ("Microsoft.Resources/deployments/write", "Microsoft.Authorization/roleAssignments/write")
| project TimeGenerated, OperationNameValue, Caller, ResourceGroup, ResourceId
| sort by TimeGenerated desc
```

## 🛡️ **Incident Response & Forensics**

### **Security Incident Playbooks**

#### **Suspicious Login Activity**
```bash
# Step 1: Identify the scope
az ad signed-in-user list-owned-objects

# Step 2: Check recent sign-in logs
az monitor activity-log list --start-time "2025-10-04T00:00:00Z" --caller "suspicious@user.com"

# Step 3: Disable user account if compromised
az ad user update --id "suspicious@user.com" --account-enabled false

# Step 4: Force sign-out from all sessions
az ad user revoke-sign-in-sessions --id "suspicious@user.com"

# Step 5: Audit permissions and access
az role assignment list --assignee "suspicious@user.com"
```

#### **Key Vault Breach Response**
```bash
# Step 1: Audit Key Vault access
az monitor activity-log list --resource-group "myproject-prod-security-rg" --start-time "2025-10-04T00:00:00Z"

# Step 2: Rotate compromised secrets
az keyvault secret set --vault-name "myproject-prod-kv" --name "compromised-secret" --value "new-secure-value"

# Step 3: Update access policies
az keyvault delete-policy --name "myproject-prod-kv" --object-id "compromised-identity-id"

# Step 4: Enable additional monitoring
az monitor diagnostic-settings create --resource "myproject-prod-kv" --name "enhanced-monitoring"
```

### **Forensic Data Collection**

```kusto
// Comprehensive security timeline
union 
  (SigninLogs | project TimeGenerated, EventType = "SignIn", User = UserPrincipalName, IP = IPAddress, Result = ResultType),
  (AuditLogs | project TimeGenerated, EventType = "Audit", User = InitiatedBy.user.userPrincipalName, IP = "", Result = Result),
  (KeyVaultData | project TimeGenerated, EventType = "KeyVault", User = Identity_s, IP = CallerIPAddress, Result = ResultType)
| where TimeGenerated between (datetime(2025-10-04T00:00:00Z) .. datetime(2025-10-04T23:59:59Z))
| sort by TimeGenerated asc

// Network traffic analysis
AzureDiagnostics
| where Category == "NetworkSecurityGroupEvent"
| where TimeGenerated > ago(24h)
| project TimeGenerated, ruleName_s, direction_s, type_s, conditions_destinationIP_s, conditions_sourceIP_s
| sort by TimeGenerated desc
```

## 🔄 **Backup & Recovery**

### **Key Vault Backup Strategy**
```bash
# Backup Key Vault secrets
for secret in $(az keyvault secret list --vault-name "myproject-prod-kv" --query "[].name" -o tsv); do
    az keyvault secret backup --vault-name "myproject-prod-kv" --name "$secret" --file "${secret}.backup"
done

# Backup Key Vault keys
for key in $(az keyvault key list --vault-name "myproject-prod-kv" --query "[].name" -o tsv); do
    az keyvault key backup --vault-name "myproject-prod-kv" --name "$key" --file "${key}.backup"
done

# Backup Key Vault certificates
for cert in $(az keyvault certificate list --vault-name "myproject-prod-kv" --query "[].name" -o tsv); do
    az keyvault certificate backup --vault-name "myproject-prod-kv" --name "$cert" --file "${cert}.backup"
done
```

### **Disaster Recovery Testing**
```bash
# Test Key Vault access from DR region
az keyvault secret show --vault-name "myproject-dr-kv" --name "test-secret"

# Verify managed identity functionality
az account get-access-token --resource "https://vault.azure.net"

# Test certificate renewal process
az keyvault certificate create --vault-name "myproject-prod-kv" --name "test-cert" --policy @cert-policy.json
```

## 📈 **Performance & Cost Optimization**

### **Log Analytics Cost Management**
```kusto
// Identify high-volume log sources
Usage
| where TimeGenerated > ago(30d)
| where IsBillable == true
| summarize TotalGB = sum(Quantity) / 1000 by DataType, Solution
| sort by TotalGB desc
| limit 20

// Monitor daily ingestion trends
Usage
| where TimeGenerated > ago(30d)
| where IsBillable == true
| summarize DailyGB = sum(Quantity) / 1000 by bin(TimeGenerated, 1d)
| render timechart
```

### **Key Vault Optimization**
- **Access Patterns**: Monitor and optimize secret access patterns
- **Certificate Lifecycle**: Implement automated certificate rotation
- **Key Usage**: Regular audit of key usage and rotation schedules
- **Cost Management**: Right-size Premium vs Standard tiers based on HSM requirements

## 📚 **Compliance & Certifications**

### **Supported Compliance Frameworks**
- **SOC 2 Type II**: System and Organization Controls
- **PCI DSS**: Payment Card Industry Data Security Standard
- **GDPR**: General Data Protection Regulation
- **HIPAA**: Health Insurance Portability and Accountability Act
- **FedRAMP**: Federal Risk and Authorization Management Program
- **ISO 27001**: Information Security Management System

### **Compliance Monitoring**
```bash
# Check compliance status
az security regulatory-compliance-standards list

# Get specific compliance assessment
az security regulatory-compliance-assessments list --standard-name "PCI-DSS-3.2.1"

# Export compliance report
az security regulatory-compliance-standards show --name "SOC-TSP" --query "displayName"
```

---

**📍 Navigation**: [⬅️ Networking Layer](../networking/README.md) | [🏠 Main README](../../README.md) | [➡️ Data Layer](../data/README.md)