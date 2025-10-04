# Azure Redis Cache Module

This Terraform module creates and manages Azure Cache for Redis with comprehensive configuration options for high-performance caching scenarios.

## Features

- **Redis Versions**: Support for Redis 6.0 and latest versions
- **Performance Tiers**: Basic, Standard, and Premium tiers with clustering
- **Security**: Private endpoints, firewall rules, and SSL/TLS encryption
- **High Availability**: Zone redundancy and geo-replication support
- **Persistence**: Redis data persistence (Premium tier)
- **Monitoring**: Diagnostic settings and metric alerts
- **Scaling**: Configurable cache sizes and shard counts
- **Compliance**: Network isolation and access controls

## Usage

### Basic Example

```hcl
module "redis_cache" {
  source = "../../modules/redis-cache"

  name                = "my-redis-cache"
  location            = "East US"
  resource_group_name = "my-rg"

  capacity = 1
  family   = "C"
  sku_name = "Standard"

  tags = {
    Environment = "dev"
    Project     = "myproject"
  }
}
```

### Advanced Premium Example

```hcl
module "redis_cache" {
  source = "../../modules/redis-cache"

  name                = "my-premium-redis"
  location            = "East US"
  resource_group_name = "my-rg"

  capacity                      = 1
  family                       = "P"
  sku_name                     = "Premium"
  minimum_tls_version          = "1.2"
  public_network_access_enabled = false
  redis_version               = "6"
  replicas_per_master         = 1
  replicas_per_primary        = 1
  tenant_settings             = {}
  shard_count                 = 3
  zones                       = ["1", "2", "3"]

  # Redis configuration
  redis_configuration = {
    aof_backup_enabled              = true
    aof_storage_connection_string_0 = "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=..."
    aof_storage_connection_string_1 = "DefaultEndpointsProtocol=https;AccountName=mystorageaccount2;AccountKey=..."
    enable_authentication           = true
    maxmemory_reserved             = 150
    maxmemory_delta                = 150
    maxmemory_policy               = "allkeys-lru"
    maxfragmentationmemory_reserved = 150
    rdb_backup_enabled             = true
    rdb_backup_frequency           = 60
    rdb_backup_max_snapshot_count  = 1
    rdb_storage_connection_string  = "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=..."
  }

  # Firewall rules
  firewall_rules = {
    "office-network" = {
      start_ip = "203.0.113.0"
      end_ip   = "203.0.113.255"
    }
    "datacenter" = {
      start_ip = "198.51.100.0"
      end_ip   = "198.51.100.255"
    }
  }

  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
  private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.redis.cache.windows.net"

  # Patch schedule
  enable_patch_schedule = true
  patch_schedules = [
    {
      day_of_week        = "Sunday"
      start_hour_utc     = 2
      maintenance_window = "PT5H"
    }
  ]

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

### Clustered Premium Example

```hcl
module "clustered_redis" {
  source = "../../modules/redis-cache"

  name                = "my-clustered-redis"
  location            = "East US"
  resource_group_name = "my-rg"

  capacity     = 1
  family      = "P"
  sku_name    = "Premium"
  shard_count = 6  # Enable clustering with 6 shards

  redis_configuration = {
    maxmemory_reserved = 200
    maxmemory_delta   = 200
    maxmemory_policy  = "allkeys-lru"
  }

  # Zone redundancy for high availability
  zones = ["1", "2", "3"]

  tags = {
    Environment = "production"
    Project     = "high-throughput-app"
  }
}
```

### Standard with Geo-Replication

```hcl
module "primary_redis" {
  source = "../../modules/redis-cache"

  name                = "primary-redis-cache"
  location            = "East US"
  resource_group_name = "primary-rg"

  capacity = 1
  family   = "P"
  sku_name = "Premium"

  tags = {
    Environment = "production"
    Role        = "primary"
  }
}

# Geo-replicated cache in different region
module "secondary_redis" {
  source = "../../modules/redis-cache"

  name                = "secondary-redis-cache"
  location            = "West US 2"
  resource_group_name = "secondary-rg"

  capacity = 1
  family   = "P" 
  sku_name = "Premium"

  # Link to primary cache for geo-replication
  # Note: Geo-replication setup would require additional azurerm_redis_linked_server resource

  tags = {
    Environment = "production"
    Role        = "secondary"
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
| [azurerm_redis_cache.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache) | resource |
| [azurerm_redis_firewall_rule.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_firewall_rule) | resource |
| [azurerm_private_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name | Name of the Redis cache | `string` |
| location | Azure region where resources will be created | `string` |
| resource_group_name | Name of the resource group | `string` |
| capacity | Capacity of the Redis cache | `number` |
| family | Family of the Redis cache SKU | `string` |
| sku_name | SKU name for the Redis cache | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| minimum_tls_version | Minimum TLS version | `string` | `"1.2"` |
| redis_version | Redis version | `string` | `"6"` |
| public_network_access_enabled | Enable public network access | `bool` | `true` |
| shard_count | Number of shards for Premium clustering | `number` | `null` |
| zones | Availability zones | `list(string)` | `null` |
| replicas_per_master | Number of replicas per master | `number` | `null` |
| replicas_per_primary | Number of replicas per primary | `number` | `null` |
| redis_configuration | Redis configuration settings | `object` | `{}` |
| firewall_rules | Map of firewall rules | `map(object)` | `{}` |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` |
| enable_patch_schedule | Enable patch schedule | `bool` | `false` |
| patch_schedules | List of patch schedule configurations | `list(object)` | `[]` |
| enable_diagnostic_settings | Enable diagnostic settings | `bool` | `false` |
| tags | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| redis_cache_id | ID of the Redis cache |
| redis_cache_name | Name of the Redis cache |
| redis_cache_hostname | Hostname of the Redis cache |
| redis_cache_port | Port of the Redis cache |
| redis_cache_ssl_port | SSL port of the Redis cache |
| redis_cache_primary_access_key | Primary access key |
| redis_cache_secondary_access_key | Secondary access key |
| redis_cache_primary_connection_string | Primary connection string |
| redis_cache_secondary_connection_string | Secondary connection string |
| private_endpoint_id | ID of the private endpoint |

## SKU Configuration

### Basic Tier
| Capacity | Memory | Connections | Bandwidth |
|----------|--------|-------------|-----------|
| C0 | 250 MB | 256 | 5 Mbps |
| C1 | 1 GB | 1,000 | 12.5 Mbps |
| C2 | 2.5 GB | 2,000 | 25 Mbps |
| C3 | 6 GB | 5,000 | 50 Mbps |
| C4 | 13 GB | 10,000 | 62.5 Mbps |
| C5 | 26 GB | 15,000 | 125 Mbps |
| C6 | 53 GB | 20,000 | 250 Mbps |

### Standard Tier
- Same as Basic tier but with high availability (master-replica)
- Automatic failover
- 99.9% SLA

### Premium Tier  
| Capacity | Memory | Connections | Bandwidth | Features |
|----------|--------|-------------|-----------|----------|
| P1 | 6 GB | 7,500 | 100 Mbps | Clustering, Persistence, Geo-replication |
| P2 | 13 GB | 15,000 | 200 Mbps | Clustering, Persistence, Geo-replication |
| P3 | 26 GB | 30,000 | 400 Mbps | Clustering, Persistence, Geo-replication |
| P4 | 53 GB | 40,000 | 800 Mbps | Clustering, Persistence, Geo-replication |
| P5 | 120 GB | 100,000 | 1600 Mbps | Clustering, Persistence, Geo-replication |

## Redis Configuration Options

### Memory Management
```hcl
redis_configuration = {
  maxmemory_reserved              = 150    # Reserved memory in MB
  maxmemory_delta                = 150    # Delta memory in MB  
  maxmemory_policy               = "allkeys-lru"  # Eviction policy
  maxfragmentationmemory_reserved = 150    # Fragmentation memory reserved
}
```

### Backup Configuration (Premium only)
```hcl
redis_configuration = {
  rdb_backup_enabled            = true
  rdb_backup_frequency         = 60      # Minutes: 15, 30, 60, 360, 720, 1440
  rdb_backup_max_snapshot_count = 1
  rdb_storage_connection_string = "DefaultEndpointsProtocol=https;..."
  
  # AOF (Append Only File) backup
  aof_backup_enabled              = true
  aof_storage_connection_string_0 = "DefaultEndpointsProtocol=https;..."
  aof_storage_connection_string_1 = "DefaultEndpointsProtocol=https;..."
}
```

### Security Configuration
```hcl
redis_configuration = {
  enable_authentication = true    # Require AUTH
  notify_keyspace_events = "Ex"  # Keyspace notifications
}
```

## Memory Policies

| Policy | Description |
|--------|-------------|
| noeviction | Returns errors when memory limit reached |
| allkeys-lru | Removes least recently used keys |
| volatile-lru | Removes LRU keys with expire set |
| allkeys-random | Removes random keys |
| volatile-random | Removes random keys with expire set |
| volatile-ttl | Removes keys with shortest TTL |
| allkeys-lfu | Removes least frequently used keys |
| volatile-lfu | Removes LFU keys with expire set |

## Security Features

### Network Access Control
```hcl
# Disable public access
public_network_access_enabled = false

# Firewall rules for specific IP ranges
firewall_rules = {
  "office" = {
    start_ip = "203.0.113.0"
    end_ip   = "203.0.113.255"
  }
}
```

### Private Endpoints
```hcl
enable_private_endpoint    = true
private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.redis.cache.windows.net"
```

### TLS Configuration
```hcl
minimum_tls_version = "1.2"  # Enforce TLS 1.2
```

## High Availability Features

### Zone Redundancy (Premium)
```hcl
zones = ["1", "2", "3"]  # Distribute across availability zones
```

### Clustering (Premium)
```hcl
shard_count = 6  # Enable clustering with 6 shards
```

### Replication (Standard/Premium)
```hcl
replicas_per_primary = 1  # Number of read replicas
```

## Monitoring and Diagnostics

### Diagnostic Settings
```hcl
enable_diagnostic_settings = true
log_analytics_workspace_id = "/subscriptions/.../workspaces/my-workspace"
```

### Key Metrics to Monitor
- **CPU Usage**: Should be under 80%
- **Memory Usage**: Monitor for memory pressure
- **Connected Clients**: Track connection counts
- **Cache Hit Ratio**: Aim for high hit rates (>80%)
- **Operations/sec**: Monitor throughput
- **Network Usage**: Track bandwidth utilization

### Useful Redis Commands for Monitoring
```redis
INFO memory          # Memory usage statistics
INFO clients        # Connected clients information  
INFO stats          # General statistics
MONITOR            # Real-time command monitoring
SLOWLOG GET 10     # Recent slow commands
```

## Best Practices

1. **Security**: Use private endpoints in production environments
2. **Performance**: Choose appropriate SKU based on memory and throughput needs
3. **Monitoring**: Enable diagnostic settings and set up alerts
4. **Backup**: Configure RDB/AOF backups for Premium tier
5. **Clustering**: Use clustering for high-throughput scenarios
6. **Memory**: Monitor memory usage and configure appropriate eviction policies
7. **Patching**: Schedule maintenance windows during low-traffic periods
8. **Access**: Use connection strings with SSL/TLS encryption
9. **Cost**: Right-size capacity based on actual usage patterns

## Troubleshooting

### Common Issues

1. **Connection timeouts**: Check firewall rules and private endpoint configuration
2. **Memory pressure**: Monitor memory usage and adjust eviction policies
3. **High CPU**: Consider scaling up or implementing clustering
4. **Slow queries**: Use SLOWLOG to identify problematic operations

### Performance Tuning

1. **Connection pooling**: Use connection pools in applications
2. **Pipeline commands**: Batch multiple operations
3. **Appropriate data structures**: Choose optimal Redis data types
4. **Key expiration**: Set appropriate TTL values
5. **Memory optimization**: Use hash tables for small objects

## License

This module is licensed under the MIT License. See LICENSE file for details.