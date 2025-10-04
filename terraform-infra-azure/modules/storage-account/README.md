# Azure Storage Account Module

This Terraform module creates and manages an Azure Storage Account with comprehensive configuration options and enterprise features.

## Features

- **Complete Storage Services**: Supports Blob, File, Queue, and Table services
- **Security**: Private endpoints, encryption, network access rules
- **Monitoring**: Diagnostic settings integration
- **Identity**: Managed identity support
- **Data Protection**: Versioning, backup policies, retention settings
- **Performance**: Multiple performance tiers and replication options
- **Compliance**: Customer-managed keys, Azure Files authentication

## Usage

### Basic Example

```hcl
module "storage_account" {
  source = "../../modules/storage-account"

  name                = "mystorageaccount"
  location            = "East US"
  resource_group_name = "my-rg"

  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = "dev"
    Project     = "myproject"
  }
}
```

### Advanced Example with Private Endpoints

```hcl
module "storage_account" {
  source = "../../modules/storage-account"

  name                = "mystorageaccount"
  location            = "East US"
  resource_group_name = "my-rg"

  account_tier                      = "Premium"
  account_replication_type          = "ZRS"
  account_kind                      = "StorageV2"
  access_tier                       = "Hot"
  enable_https_traffic_only         = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false

  # Network access
  network_rules = {
    default_action             = "Deny"
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = ["/subscriptions/.../subnets/storage-subnet"]
    bypass                     = ["Logging", "Metrics", "AzureServices"]
  }

  # Private endpoints
  enable_private_endpoints        = true
  private_endpoint_subnet_id      = "/subscriptions/.../subnets/pe-subnet"
  private_endpoint_subresources   = ["blob", "file", "queue", "table"]
  blob_private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net"
  file_private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.file.core.windows.net"

  # Managed identity
  enable_managed_identity = true
  identity = {
    type = "SystemAssigned"
  }

  # Containers
  containers = {
    "data" = {
      container_access_type = "private"
    }
    "logs" = {
      container_access_type = "private"
    }
  }

  # File shares
  shares = {
    "config" = {
      quota            = 100
      enabled_protocol = "SMB"
      access_tier      = "Hot"
    }
  }

  # Blob properties
  enable_blob_properties = true
  blob_properties = {
    versioning_enabled        = true
    change_feed_enabled       = true
    last_access_time_enabled  = true
    delete_retention_policy = {
      days = 30
    }
    container_delete_retention_policy = {
      days = 7
    }
  }

  # Diagnostic settings
  enable_diagnostic_settings   = true
  log_analytics_workspace_id   = "/subscriptions/.../workspaces/my-workspace"

  tags = {
    Environment = "production"
    Project     = "myproject"
    Owner       = "platform-team"
  }
}
```

### Static Website Example

```hcl
module "static_website" {
  source = "../../modules/storage-account"

  name                = "mystaticwebsite"
  location            = "East US"
  resource_group_name = "my-rg"

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable static website
  enable_static_website = true
  static_website = {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = {
    Environment = "production"
    Project     = "website"
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
| [azurerm_storage_account.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_share.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_storage_queue.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue) | resource |
| [azurerm_storage_table.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_table) | resource |
| [azurerm_private_endpoint.blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.file](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name | Name of the storage account | `string` |
| location | Azure region where resources will be created | `string` |
| resource_group_name | Name of the resource group | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| account_tier | Storage account tier | `string` | `"Standard"` |
| account_replication_type | Storage account replication type | `string` | `"LRS"` |
| account_kind | Storage account kind | `string` | `"StorageV2"` |
| access_tier | Access tier for the storage account | `string` | `"Hot"` |
| enable_https_traffic_only | Enable HTTPS traffic only | `bool` | `true` |
| min_tls_version | Minimum TLS version | `string` | `"TLS1_2"` |
| allow_nested_items_to_be_public | Allow nested items to be public | `bool` | `false` |
| shared_access_key_enabled | Enable shared access key | `bool` | `true` |
| public_network_access_enabled | Enable public network access | `bool` | `true` |
| default_to_oauth_authentication | Default to OAuth authentication | `bool` | `false` |
| cross_tenant_replication_enabled | Enable cross tenant replication | `bool` | `true` |
| edge_zone | Edge zone for the storage account | `string` | `null` |
| enable_managed_identity | Enable managed identity | `bool` | `false` |
| enable_private_endpoints | Enable private endpoints | `bool` | `false` |
| containers | Map of container configurations | `map(object)` | `{}` |
| shares | Map of file share configurations | `map(object)` | `{}` |
| queues | Map of queue names | `map(string)` | `{}` |
| tables | Map of table names | `map(string)` | `{}` |
| tags | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| storage_account_id | ID of the storage account |
| storage_account_name | Name of the storage account |
| primary_blob_endpoint | Primary blob endpoint |
| primary_file_endpoint | Primary file endpoint |
| primary_queue_endpoint | Primary queue endpoint |
| primary_table_endpoint | Primary table endpoint |
| primary_connection_string | Primary connection string |
| secondary_connection_string | Secondary connection string |
| containers | Map of created containers |
| shares | Map of created file shares |
| queues | Map of created queues |
| tables | Map of created tables |

## Configuration Examples

### Network Security Configuration

```hcl
network_rules = {
  default_action = "Deny"
  ip_rules = [
    "203.0.113.0/24",
    "198.51.100.0/24"
  ]
  virtual_network_subnet_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/storage-subnet"
  ]
  bypass = ["Logging", "Metrics", "AzureServices"]
}
```

### Blob Properties Configuration

```hcl
blob_properties = {
  versioning_enabled               = true
  change_feed_enabled             = true
  change_feed_retention_in_days   = 30
  default_service_version         = "2020-06-12"
  last_access_time_enabled        = true
  
  delete_retention_policy = {
    days = 30
  }
  
  restore_policy = {
    days = 7
  }
  
  container_delete_retention_policy = {
    days = 7
  }
  
  cors_rules = [
    {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD"]
      allowed_origins    = ["https://example.com"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  ]
}
```

### Customer Managed Key Configuration

```hcl
enable_customer_managed_key = true
customer_managed_key = {
  key_vault_key_id          = "/subscriptions/.../keys/my-key"
  user_assigned_identity_id = "/subscriptions/.../identities/my-identity"
}
```

## Security Features

- **Private Endpoints**: Support for blob, file, queue, and table services
- **Network Access Rules**: IP restrictions and virtual network integration
- **Encryption**: Support for customer-managed keys and encryption at rest
- **Identity**: Managed identity integration for secure access
- **Access Control**: Disable shared access keys for enhanced security
- **TLS**: Configurable minimum TLS version (1.2 recommended)

## Monitoring and Diagnostics

The module supports Azure Monitor diagnostic settings to collect:

- **Metrics**: Storage account metrics for capacity, transactions, and availability
- **Logs**: Storage service logs for auditing and troubleshooting

## Best Practices

1. **Security**: Use private endpoints in production environments
2. **Performance**: Choose appropriate tier and replication for your workload
3. **Monitoring**: Enable diagnostic settings for observability
4. **Access**: Use managed identities instead of access keys where possible
5. **Compliance**: Enable versioning and retention policies for data protection
6. **Network**: Restrict access using network rules and firewall settings

## License

This module is licensed under the MIT License. See LICENSE file for details.