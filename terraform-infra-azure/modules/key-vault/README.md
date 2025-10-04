# Azure Key Vault Module

This Terraform module creates and manages Azure Key Vault with comprehensive security features and enterprise-grade configurations.

## Features

- **Secrets Management**: Secure storage and retrieval of secrets
- **Key Management**: Hardware Security Module (HSM) backed keys
- **Certificate Management**: SSL/TLS certificate lifecycle management
- **Access Control**: RBAC and access policies support
- **Security**: Private endpoints, firewall rules, and audit logging
- **Monitoring**: Diagnostic settings and metric alerts
- **Compliance**: Purge protection and soft delete
- **Integration**: Managed identity and service principal support

## Usage

### Basic Example

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                = "my-keyvault"
  location            = "East US"
  resource_group_name = "my-rg"
  tenant_id           = "00000000-0000-0000-0000-000000000000"

  sku_name = "standard"

  access_policies = [
    {
      tenant_id = "00000000-0000-0000-0000-000000000000"
      object_id = "11111111-1111-1111-1111-111111111111"
      
      secret_permissions = [
        "Get", "List", "Set", "Delete", "Backup", "Restore"
      ]
      
      key_permissions = [
        "Get", "List", "Create", "Delete", "Import", "Backup", "Restore"
      ]
      
      certificate_permissions = [
        "Get", "List", "Create", "Delete", "Import", "ManageContacts"
      ]
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "myproject"
  }
}
```

### Advanced Enterprise Example

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                = "enterprise-kv"
  location            = "East US"
  resource_group_name = "security-rg"
  tenant_id           = "00000000-0000-0000-0000-000000000000"

  sku_name                          = "premium"
  enabled_for_disk_encryption       = true
  enabled_for_deployment            = true
  enabled_for_template_deployment   = true
  enable_rbac_authorization         = true
  purge_protection_enabled          = true
  soft_delete_retention_days        = 90
  public_network_access_enabled     = false

  # Network access rules
  network_acls = {
    bypass                     = "AzureServices"
    default_action            = "Deny"
    ip_rules                  = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [
      "/subscriptions/.../subnets/keyvault-subnet"
    ]
  }

  # Private endpoint configuration
  enable_private_endpoint    = true
  private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
  private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net"

  # Secrets to create
  secrets = {
    "database-connection-string" = {
      value         = "Server=myserver;Database=mydb;User Id=myuser;Password=mypass;"
      content_type  = "text/plain"
      expiration_date = "2025-12-31T23:59:59Z"
    }
    "api-key" = {
      value        = "super-secret-api-key-value"
      content_type = "API Key"
    }
  }

  # Keys to create
  keys = {
    "encryption-key" = {
      key_type     = "RSA"
      key_size     = 2048
      key_opts     = ["encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"]
      expiration_date = "2025-12-31T23:59:59Z"
    }
    "signing-key" = {
      key_type = "EC"
      curve    = "P-256"
      key_opts = ["sign", "verify"]
    }
  }

  # Certificates to create
  certificates = {
    "ssl-cert" = {
      issuer = "Self"
      subject = "CN=myapp.company.com"
      validity_in_months = 12
      
      subject_alternative_names = {
        dns_names = ["myapp.company.com", "www.myapp.company.com"]
      }
      
      key_properties = {
        exportable = true
        key_size   = 2048
        key_type   = "RSA"
        reuse_key  = false
      }
      
      secret_properties = {
        content_type = "application/x-pkcs12"
      }
    }
  }

  # Certificate contacts
  certificate_contacts = [
    {
      email = "security@company.com"
      name  = "Security Team"
      phone = "+1-555-0123"
    }
  ]

  # Diagnostic settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = "/subscriptions/.../workspaces/security-workspace"

  tags = {
    Environment = "production"
    Project     = "enterprise-security"
    Owner       = "security-team"
    Compliance  = "required"
  }
}
```

### RBAC Authorization Example

```hcl
module "key_vault_rbac" {
  source = "../../modules/key-vault"

  name                = "rbac-keyvault"
  location            = "East US"
  resource_group_name = "my-rg"
  tenant_id           = "00000000-0000-0000-0000-000000000000"

  sku_name                  = "standard"
  enable_rbac_authorization = true

  # No access_policies needed when using RBAC
  # Use Azure role assignments instead:
  # - Key Vault Administrator
  # - Key Vault Secrets User
  # - Key Vault Crypto User
  # - Key Vault Certificate User

  tags = {
    Environment = "production"
    AuthModel   = "rbac"
  }
}
```

### HSM-Protected Keys Example

```hcl
module "premium_key_vault" {
  source = "../../modules/key-vault"

  name                = "premium-kv"
  location            = "East US"
  resource_group_name = "security-rg"
  tenant_id           = "00000000-0000-0000-0000-000000000000"

  sku_name                 = "premium"  # Required for HSM
  purge_protection_enabled = true       # Required for HSM

  keys = {
    "hsm-key" = {
      key_type = "RSA-HSM"  # HSM-protected key
      key_size = 2048
      key_opts = ["encrypt", "decrypt", "sign", "verify"]
    }
    "ec-hsm-key" = {
      key_type = "EC-HSM"   # Elliptic Curve HSM key
      curve    = "P-256"
      key_opts = ["sign", "verify"]
    }
  }

  tags = {
    Environment = "production"
    Security    = "hsm-protected"
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
| [azurerm_key_vault.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_key.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) | resource |
| [azurerm_key_vault_certificate.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) | resource |
| [azurerm_private_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name | Name of the Key Vault | `string` |
| location | Azure region where resources will be created | `string` |
| resource_group_name | Name of the resource group | `string` |
| tenant_id | Azure AD tenant ID | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| sku_name | SKU name for Key Vault | `string` | `"standard"` |
| enabled_for_disk_encryption | Enable for Azure Disk Encryption | `bool` | `false` |
| enabled_for_deployment | Enable for Azure deployment | `bool` | `false` |
| enabled_for_template_deployment | Enable for ARM template deployment | `bool` | `false` |
| enable_rbac_authorization | Enable RBAC authorization | `bool` | `false` |
| purge_protection_enabled | Enable purge protection | `bool` | `false` |
| soft_delete_retention_days | Soft delete retention days | `number` | `90` |
| public_network_access_enabled | Enable public network access | `bool` | `true` |
| access_policies | List of access policies | `list(object)` | `[]` |
| network_acls | Network access rules | `object` | `null` |
| secrets | Map of secrets to create | `map(object)` | `{}` |
| keys | Map of keys to create | `map(object)` | `{}` |
| certificates | Map of certificates to create | `map(object)` | `{}` |
| certificate_contacts | List of certificate contacts | `list(object)` | `[]` |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` |
| tags | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | ID of the Key Vault |
| key_vault_name | Name of the Key Vault |
| key_vault_uri | URI of the Key Vault |
| key_vault_vault_uri | Vault URI of the Key Vault |
| secrets | Map of created secrets |
| keys | Map of created keys |
| certificates | Map of created certificates |
| private_endpoint_id | ID of the private endpoint |

## Access Policy Permissions

### Secret Permissions
| Permission | Description |
|------------|-------------|
| Get | Read secret values |
| List | List secrets |
| Set | Create/update secrets |
| Delete | Delete secrets |
| Backup | Backup secrets |
| Restore | Restore secrets |
| Recover | Recover deleted secrets |
| Purge | Permanently delete secrets |

### Key Permissions  
| Permission | Description |
|------------|-------------|
| Get | Read key metadata |
| List | List keys |
| Create | Create keys |
| Delete | Delete keys |
| Import | Import keys |
| Backup | Backup keys |
| Restore | Restore keys |
| Recover | Recover deleted keys |
| Purge | Permanently delete keys |
| Encrypt | Encrypt with key |
| Decrypt | Decrypt with key |
| Sign | Sign with key |
| Verify | Verify signatures |
| WrapKey | Wrap key operations |
| UnwrapKey | Unwrap key operations |
| Update | Update key attributes |
| GetRotationPolicy | Get key rotation policy |
| SetRotationPolicy | Set key rotation policy |
| Rotate | Rotate key |

### Certificate Permissions
| Permission | Description |
|------------|-------------|
| Get | Read certificates |
| List | List certificates |
| Create | Create certificates |
| Delete | Delete certificates |
| Import | Import certificates |
| Update | Update certificates |
| ManageContacts | Manage certificate contacts |
| GetIssuers | Get certificate issuers |
| ListIssuers | List certificate issuers |
| SetIssuers | Set certificate issuers |
| DeleteIssuers | Delete certificate issuers |
| ManageIssuers | Manage certificate issuers |
| Backup | Backup certificates |
| Restore | Restore certificates |
| Recover | Recover deleted certificates |
| Purge | Permanently delete certificates |

## Built-in Azure RBAC Roles

| Role | Permissions |
|------|-------------|
| Key Vault Administrator | Full access to all Key Vault operations |
| Key Vault Secrets User | Read secret contents |
| Key Vault Secrets Officer | Manage secrets except purge |
| Key Vault Crypto User | Encrypt/decrypt, sign/verify with keys |
| Key Vault Crypto Officer | Manage keys except purge |
| Key Vault Certificate User | Read certificate contents |
| Key Vault Certificate Officer | Manage certificates except purge |
| Key Vault Reader | Read metadata of key vault and its objects |

## Key Types and Curves

### RSA Keys
```hcl
keys = {
  "rsa-2048" = {
    key_type = "RSA"
    key_size = 2048
  }
  "rsa-3072" = {
    key_type = "RSA" 
    key_size = 3072
  }
  "rsa-4096" = {
    key_type = "RSA"
    key_size = 4096
  }
}
```

### Elliptic Curve Keys
```hcl
keys = {
  "ec-p256" = {
    key_type = "EC"
    curve    = "P-256"
  }
  "ec-p384" = {
    key_type = "EC"
    curve    = "P-384"  
  }
  "ec-p521" = {
    key_type = "EC"
    curve    = "P-521"
  }
  "ec-secp256k1" = {
    key_type = "EC"
    curve    = "SECP256K1"
  }
}
```

### HSM-Protected Keys (Premium SKU)
```hcl
keys = {
  "hsm-rsa" = {
    key_type = "RSA-HSM"
    key_size = 2048
  }
  "hsm-ec" = {
    key_type = "EC-HSM"
    curve    = "P-256"
  }
}
```

## Certificate Configuration

### Self-Signed Certificate
```hcl
certificates = {
  "self-signed" = {
    issuer  = "Self"
    subject = "CN=myapp.company.com"
    validity_in_months = 12
    
    key_properties = {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }
  }
}
```

### Certificate Authority Integration
```hcl
certificates = {
  "ca-cert" = {
    issuer  = "DigiCert"  # Or other CA
    subject = "CN=myapp.company.com"
    validity_in_months = 12
    
    subject_alternative_names = {
      dns_names = [
        "myapp.company.com",
        "www.myapp.company.com",
        "api.myapp.company.com"
      ]
    }
  }
}
```

## Network Security

### Network ACLs Configuration
```hcl
network_acls = {
  bypass         = "AzureServices"  # or "None"
  default_action = "Deny"           # or "Allow"
  
  ip_rules = [
    "203.0.113.0/24",    # Office network
    "198.51.100.50/32"   # Build server
  ]
  
  virtual_network_subnet_ids = [
    "/subscriptions/.../subnets/app-subnet",
    "/subscriptions/.../subnets/admin-subnet"
  ]
}
```

### Private Endpoint Configuration
```hcl
enable_private_endpoint    = true
private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net"
```

## Monitoring and Diagnostics

### Diagnostic Logs Available
- **AuditEvent**: All Key Vault access events
- **AzurePolicyEvaluationDetails**: Azure Policy evaluation details

### Metrics Available
- **ServiceApiHit**: Total service API hits
- **ServiceApiLatency**: Service API latency  
- **ServiceApiResult**: Service API results
- **SaturationShoebox**: Vault saturation

### Example Diagnostic Configuration
```hcl
enable_diagnostic_settings = true
log_analytics_workspace_id = "/subscriptions/.../workspaces/security-logs"

# Additional configuration in diagnostic_settings variable
diagnostic_settings = {
  logs = ["AuditEvent"]
  metrics = [
    "AllMetrics"
  ]
}
```

## Security Best Practices

1. **Access Control**: Use RBAC instead of access policies when possible
2. **Network Security**: Disable public access and use private endpoints
3. **Purge Protection**: Enable for production Key Vaults
4. **Soft Delete**: Configure appropriate retention period
5. **Monitoring**: Enable diagnostic settings and audit logs
6. **Key Rotation**: Implement regular key rotation policies
7. **Backup**: Regular backup of critical keys and certificates
8. **Compliance**: Follow organizational security policies

## Common Use Cases

### Application Secrets Management
```hcl
secrets = {
  "database-password" = {
    value = var.db_password
    content_type = "password"
  }
  "storage-connection-string" = {
    value = var.storage_connection_string
    content_type = "connection-string"
  }
}
```

### SSL/TLS Certificate Management
```hcl
certificates = {
  "wildcard-cert" = {
    issuer = "DigiCert"
    subject = "CN=*.company.com"
    validity_in_months = 24
    
    subject_alternative_names = {
      dns_names = ["*.company.com", "company.com"]
    }
  }
}
```

### Encryption Key Management
```hcl
keys = {
  "data-encryption-key" = {
    key_type = "RSA"
    key_size = 2048
    key_opts = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]
  }
}
```

## License

This module is licensed under the MIT License. See LICENSE file for details.