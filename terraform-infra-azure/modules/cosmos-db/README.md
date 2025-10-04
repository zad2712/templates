# Azure Cosmos DB Module

This Terraform module creates and manages Azure Cosmos DB resources with comprehensive configuration options for multi-model database scenarios.

## Features

- **Multi-Model Database**: Support for SQL, MongoDB, Cassandra, Gremlin, and Table APIs
- **Global Distribution**: Multi-region deployment with configurable consistency levels
- **Security**: Private endpoints, firewall rules, and encryption
- **Performance**: Configurable throughput and autoscaling
- **Monitoring**: Diagnostic settings integration
- **Backup**: Automated backup with configurable retention
- **Identity**: Managed identity support
- **Compliance**: Network restrictions and access controls

## Usage

### Basic SQL API Example

```hcl
module "cosmos_db" {
  source = "../../modules/cosmos-db"

  name                = "my-cosmos-db"
  location            = "East US"
  resource_group_name = "my-rg"

  offer_type      = "Standard"
  kind            = "GlobalDocumentDB"
  consistency_policy = {
    consistency_level       = "Session"
    max_interval_in_seconds = null
    max_staleness_prefix    = null
  }

  geo_location = [
    {
      location          = "East US"
      failover_priority = 0
      zone_redundant    = false
    }
  ]

  sql_databases = {
    "app-db" = {
      throughput                = 400
      autoscale_max_throughput = null
      containers = {
        "users" = {
          partition_key_path      = "/userId"
          partition_key_version   = 1
          throughput             = null
          autoscale_max_throughput = 1000
          default_ttl            = null
          analytical_storage_ttl = null
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "myproject"
  }
}
```

### Advanced Multi-Region Example

```hcl
module "cosmos_db" {
  source = "../../modules/cosmos-db"

  name                = "my-global-cosmos-db"
  location            = "East US"
  resource_group_name = "my-rg"

  offer_type                    = "Standard"
  kind                         = "GlobalDocumentDB"
  enable_automatic_failover    = true
  enable_multiple_write_locations = true
  enable_free_tier            = false
  analytical_storage_enabled  = true
  public_network_access_enabled = false

  consistency_policy = {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location = [
    {
      location          = "East US"
      failover_priority = 0
      zone_redundant    = true
    },
    {
      location          = "West US 2"
      failover_priority = 1
      zone_redundant    = true
    },
    {
      location          = "North Europe"
      failover_priority = 2
      zone_redundant    = false
    }
  ]

  # Network restrictions
  ip_range_filter = [
    "203.0.113.0/24",
    "198.51.100.0/24"
  ]

  virtual_network_rule = [
    {
      id                                   = "/subscriptions/.../subnets/cosmos-subnet"
      ignore_missing_vnet_service_endpoint = false
    }
  ]

  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
  private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.documents.azure.com"

  # Managed identity
  enable_identity = true
  identity_type   = "SystemAssigned"

  # Backup policy
  backup_policy = {
    type                = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 168
    storage_redundancy  = "Geo"
  }

  # SQL databases and containers
  sql_databases = {
    "production-db" = {
      throughput                = null
      autoscale_max_throughput = 4000
      containers = {
        "users" = {
          partition_key_path      = "/userId"
          partition_key_version   = 1
          throughput             = null
          autoscale_max_throughput = 1000
          default_ttl            = 86400
          analytical_storage_ttl = -1
          unique_key = [
            {
              paths = ["/email"]
            }
          ]
          indexing_policy = {
            indexing_mode = "consistent"
            included_path = [
              {
                path = "/*"
              }
            ]
            excluded_path = [
              {
                path = "/\"_etag\"/?"
              }
            ]
          }
        }
      }
    }
  }

  # MongoDB collections
  mongodb_databases = {
    "mongo-db" = {
      throughput                = null
      autoscale_max_throughput = 1000
      collections = {
        "products" = {
          shard_key               = "productId"
          throughput             = null
          autoscale_max_throughput = 1000
          default_ttl_seconds    = null
          analytical_storage_ttl = null
          index = [
            {
              keys   = ["_id"]
              unique = true
            }
          ]
        }
      }
    }
  }

  # Diagnostic settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = "/subscriptions/.../workspaces/my-workspace"

  tags = {
    Environment = "production"
    Project     = "myproject"
    Owner       = "platform-team"
  }
}
```

### MongoDB API Example

```hcl
module "mongodb_cosmos" {
  source = "../../modules/cosmos-db"

  name                = "my-mongodb-cosmos"
  location            = "East US"
  resource_group_name = "my-rg"

  offer_type = "Standard"
  kind      = "MongoDB"
  
  mongo_server_version = "4.2"
  
  consistency_policy = {
    consistency_level = "Session"
  }

  geo_location = [
    {
      location          = "East US"
      failover_priority = 0
      zone_redundant    = false
    }
  ]

  mongodb_databases = {
    "app-db" = {
      throughput                = 400
      autoscale_max_throughput = null
      collections = {
        "users" = {
          shard_key               = "userId"
          throughput             = null
          autoscale_max_throughput = 1000
          default_ttl_seconds    = null
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "mongodb-app"
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
| [azurerm_cosmosdb_account.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account) | resource |
| [azurerm_cosmosdb_sql_database.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_database) | resource |
| [azurerm_cosmosdb_sql_container.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container) | resource |
| [azurerm_cosmosdb_mongo_database.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_mongo_database) | resource |
| [azurerm_cosmosdb_mongo_collection.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_mongo_collection) | resource |
| [azurerm_private_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name | Name of the Cosmos DB account | `string` |
| location | Azure region where resources will be created | `string` |
| resource_group_name | Name of the resource group | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| offer_type | Offer type for the Cosmos DB account | `string` | `"Standard"` |
| kind | Kind of Cosmos DB account | `string` | `"GlobalDocumentDB"` |
| consistency_policy | Consistency policy configuration | `object` | See variables.tf |
| geo_location | List of geo locations | `list(object)` | Single region |
| enable_automatic_failover | Enable automatic failover | `bool` | `false` |
| enable_multiple_write_locations | Enable multiple write locations | `bool` | `false` |
| enable_free_tier | Enable free tier | `bool` | `false` |
| analytical_storage_enabled | Enable analytical storage | `bool` | `false` |
| public_network_access_enabled | Enable public network access | `bool` | `true` |
| sql_databases | Map of SQL database configurations | `map(object)` | `{}` |
| mongodb_databases | Map of MongoDB database configurations | `map(object)` | `{}` |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` |
| tags | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| cosmosdb_account_id | ID of the Cosmos DB account |
| cosmosdb_account_name | Name of the Cosmos DB account |
| cosmosdb_account_endpoint | Endpoint of the Cosmos DB account |
| cosmosdb_account_primary_key | Primary key of the Cosmos DB account |
| cosmosdb_account_secondary_key | Secondary key of the Cosmos DB account |
| cosmosdb_account_connection_strings | Connection strings for the Cosmos DB account |
| sql_databases | Map of created SQL databases |
| mongodb_databases | Map of created MongoDB databases |
| private_endpoint_id | ID of the private endpoint |

## Consistency Levels

### Strong
- **Use case**: Critical applications requiring strict consistency
- **Availability**: Lower availability during outages
- **Performance**: Higher latency
- **Configuration**: `consistency_level = "Strong"`

### Bounded Staleness
- **Use case**: Applications that can tolerate bounded lag
- **Configuration**: 
  ```hcl
  consistency_level       = "BoundedStaleness"
  max_interval_in_seconds = 300
  max_staleness_prefix    = 100000
  ```

### Session (Default)
- **Use case**: Most applications (99% of scenarios)
- **Guarantees**: Read-your-writes, monotonic reads
- **Configuration**: `consistency_level = "Session"`

### Consistent Prefix
- **Use case**: Applications that need ordered updates
- **Configuration**: `consistency_level = "ConsistentPrefix"`

### Eventual
- **Use case**: Applications prioritizing availability and performance
- **Configuration**: `consistency_level = "Eventual"`

## Performance Configuration

### Throughput Models

**Manual Throughput**
```hcl
throughput = 400  # Fixed RU/s
autoscale_max_throughput = null
```

**Autoscale Throughput**
```hcl
throughput = null
autoscale_max_throughput = 4000  # Max RU/s (scales from 10% automatically)
```

### Container Partitioning

```hcl
containers = {
  "orders" = {
    partition_key_path    = "/customerId"
    partition_key_version = 1
    # ... other configuration
  }
}
```

## Security Features

### Network Access Control

```hcl
# IP-based access control
ip_range_filter = ["203.0.113.0/24", "198.51.100.50"]

# Virtual network rules
virtual_network_rule = [
  {
    id = "/subscriptions/.../subnets/cosmos-subnet"
    ignore_missing_vnet_service_endpoint = false
  }
]
```

### Private Endpoints

```hcl
enable_private_endpoint    = true
private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.documents.azure.com"
```

## API Support

### SQL (Core) API
- **Use case**: Document database with SQL queries
- **Features**: ACID transactions, stored procedures, triggers
- **Configuration**: `kind = "GlobalDocumentDB"`

### MongoDB API  
- **Use case**: MongoDB compatibility
- **Features**: MongoDB wire protocol support
- **Configuration**: `kind = "MongoDB"`

### Cassandra API
- **Use case**: Wide-column database
- **Configuration**: `kind = "GlobalDocumentDB"` with Cassandra tables

### Gremlin (Graph) API
- **Use case**: Graph database applications
- **Configuration**: `kind = "GlobalDocumentDB"` with Gremlin graph

### Table API
- **Use case**: Key-value storage
- **Configuration**: `kind = "GlobalDocumentDB"` with tables

## Best Practices

1. **Partitioning**: Choose partition keys with high cardinality and even distribution
2. **Consistency**: Use Session consistency for most scenarios (default)
3. **Security**: Use private endpoints in production environments
4. **Performance**: Consider autoscale for variable workloads
5. **Monitoring**: Enable diagnostic settings for observability
6. **Backup**: Configure backup policies based on RTO/RPO requirements
7. **Cost**: Use free tier for development and testing
8. **Regions**: Place read regions close to users for better performance

## License

This module is licensed under the MIT License. See LICENSE file for details.