# 🗄️ Data Layer - Azure Data & Storage Services

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider~4.0-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

The **Data Layer** provides comprehensive data persistence, analytics, and storage capabilities on Azure. This layer implements secure, scalable, and high-performance data services with built-in backup, disaster recovery, and compliance features.

## 🎯 **Layer Overview**

> **Purpose**: Deploy and manage data services including databases, storage, caching, and analytics  
> **Dependencies**: Networking Layer → Security Layer → **Data Layer** → Compute Layer  
> **Deployment Time**: ~8-12 minutes  
> **Resources**: Azure SQL, Cosmos DB, Storage Accounts, Redis Cache, Analytics Services

## 🏗️ **Architecture Components**

### **🗃️ Azure SQL Database**
- **Enterprise Database**: Fully managed SQL with 99.99% SLA
- **Security**: Always Encrypted, TDE, Advanced Threat Protection
- **Performance**: Auto-tuning, intelligent insights, read replicas
- **Backup**: Automated backups, point-in-time restore, geo-replication

### **🌍 Azure Cosmos DB**
- **Multi-Model Database**: Document, key-value, graph, column-family
- **Global Distribution**: Multi-region writes, automatic failover
- **Performance**: Single-digit millisecond latency, unlimited scale
- **Consistency**: Five consistency levels for different use cases

### **💾 Storage Accounts**
- **Unified Storage**: Blob, File, Queue, Table storage
- **Performance Tiers**: Hot, cool, archive for cost optimization
- **Security**: Encryption at rest, private endpoints, RBAC
- **Integration**: CDN, Search, Analytics services

### **⚡ Redis Cache**
- **In-Memory Caching**: High-performance data caching
- **High Availability**: Clustering, replication, persistence
- **Security**: TLS encryption, authentication, network isolation
- **Patterns**: Cache-aside, write-through, session store

## 📋 **Supported Services**

| Service | Purpose | Backup | Encryption | Global Scale | Private Endpoints |
|---------|---------|---------|------------|--------------|-------------------|
| 🗃️ **Azure SQL** | Relational database | ✅ | ✅ | ✅ | ✅ |
| 🌍 **Cosmos DB** | Multi-model NoSQL | ✅ | ✅ | ✅ | ✅ |
| 💾 **Storage Accounts** | Object storage | ✅ | ✅ | ✅ | ✅ |
| ⚡ **Redis Cache** | In-memory cache | ✅ | ✅ | ❌ | ✅ |
| 📊 **Synapse Analytics** | Data warehouse | ✅ | ✅ | ✅ | ✅ |
| 🔄 **Data Factory** | ETL/ELT pipelines | ✅ | ✅ | ✅ | ✅ |
| 🔍 **Cognitive Search** | Search service | ✅ | ✅ | ✅ | ✅ |

## 🚀 **Quick Start**

### **1. Deploy Complete Data Layer**

```bash
# Deploy all data services for development
cd layers/data/environments/dev
terraform init -backend-config=backend.conf
terraform plan -var-file=terraform.auto.tfvars
terraform apply -var-file=terraform.auto.tfvars

# Or use the management script
./terraform-manager.sh deploy-data dev
```

### **2. Deploy Specific Services**

```bash
# Deploy only SQL Database
terraform apply -target=module.sql_database -var-file=terraform.auto.tfvars

# Deploy Storage and Cache
terraform apply -target=module.storage_account -target=module.redis_cache -var-file=terraform.auto.tfvars
```

## 🔧 **Configuration Examples**

### **🗃️ Production SQL Database**

```hcl
# terraform.auto.tfvars
sql_databases = {
  "production-app" = {
    database_name                = "prod-app-db"
    administrator_login          = "sqladmin"
    administrator_login_password = "@Microsoft.KeyVault(VaultName=myproject-prod-kv;SecretName=sql-admin-password)"
    server_version              = "12.0"
    
    # Performance tier
    sku_name                    = "P4"           # 500 DTU Performance
    max_size_gb                 = 1024           # 1TB storage
    zone_redundant              = true           # Zone redundancy
    
    # Read scaling
    read_scale                  = "Enabled"      # Enable read replicas
    read_replica_count          = 3              # Multiple read replicas
    
    # Security configuration
    enable_transparent_data_encryption = true   # TDE encryption
    enable_threat_detection           = true    # Advanced threat protection
    enable_vulnerability_assessment   = true    # Security scanning
    
    # Backup and disaster recovery
    backup_retention_days            = 35       # 35-day retention
    backup_storage_redundancy        = "Geo"    # Geo-redundant backups
    enable_long_term_retention       = true     # Long-term retention
    
    long_term_retention = {
      weekly_retention  = "P12W"                # 12 weeks
      monthly_retention = "P12M"                # 12 months
      yearly_retention  = "P7Y"                 # 7 years
      week_of_year     = 1                      # Week 1 for yearly
    }
    
    # High availability
    auto_pause_delay_in_minutes = -1            # Disable auto-pause
    min_capacity               = 2.0             # Min compute (vCores)
    max_capacity               = 32.0            # Max compute scaling
    
    # Network security
    public_network_access_enabled = false       # Private access only
    
    # Firewall rules (if needed for specific IPs)
    firewall_rules = [
      {
        name             = "AllowAzureServices"
        start_ip_address = "0.0.0.0"
        end_ip_address   = "0.0.0.0"
      }
    ]
    
    # Azure AD integration
    azure_ad_admin_login        = "dba-team@mycompany.com"
    azure_ad_admin_object_id    = "12345678-1234-1234-1234-123456789012"
    azure_ad_authentication_only = false        # Allow both AAD and SQL auth
  }
  
  "analytics-db" = {
    database_name                = "prod-analytics-db"
    administrator_login          = "analyticsadmin"
    administrator_login_password = "@Microsoft.KeyVault(VaultName=myproject-prod-kv;SecretName=analytics-db-password)"
    server_version              = "12.0"
    
    # Data warehouse configuration
    sku_name                    = "DW1000c"      # Data Warehouse compute
    max_size_gb                 = 10240          # 10TB storage
    
    # Analytics optimizations
    read_scale                  = "Enabled"
    read_replica_count          = 1              # Single read replica for analytics
    
    # Security
    enable_transparent_data_encryption = true
    enable_threat_detection           = true
    
    # Backup strategy for analytics
    backup_retention_days = 14                   # Shorter retention for analytics
    backup_storage_redundancy = "Local"          # Local backup for cost
  }
}
```

### **🌍 Production Cosmos DB**

```hcl
cosmos_db_accounts = {
  "global-app" = {
    offer_type                    = "Standard"
    kind                         = "GlobalDocumentDB"
    
    # Consistency configuration
    consistency_level            = "BoundedStaleness"
    max_interval_in_seconds      = 300          # 5 minutes
    max_staleness_prefix         = 100000       # 100K operations
    
    # Global distribution
    enable_geo_redundancy        = true         # Multi-region
    enable_multiple_write_locations = true      # Multi-master
    enable_automatic_failover    = true         # Auto-failover
    
    # Advanced features
    enable_analytical_storage    = true         # HTAP workloads
    analytical_storage_ttl       = 2592000      # 30 days
    enable_free_tier            = false         # No free tier in prod
    
    # Network security
    public_network_access_enabled = false       # Private access only
    ip_range_filter             = ""            # No IP filtering (using private endpoints)
    
    # Backup configuration
    backup_type                 = "Continuous"  # Continuous backup
    backup_interval_in_minutes  = 240          # 4 hours
    backup_retention_in_hours   = 720          # 30 days
    
    # Geo-locations for global distribution
    geo_locations = [
      {
        location          = "East US"
        failover_priority = 0
        zone_redundant   = true
      },
      {
        location          = "West US 2"
        failover_priority = 1
        zone_redundant   = true
      },
      {
        location          = "North Europe"
        failover_priority = 2
        zone_redundant   = false
      }
    ]
    
    databases = [
      {
        name       = "production-db"
        throughput = 10000                      # Dedicated throughput
        
        containers = [
          {
            name               = "users"
            partition_key_path = "/userId"
            throughput        = 4000            # Container-level throughput
            
            # Advanced indexing for performance
            indexing_policy = {
              automatic     = true
              indexing_mode = "consistent"
              
              included_paths = [
                { path = "/userId/?" },
                { path = "/email/?" },
                { path = "/profile/firstName/?" },
                { path = "/profile/lastName/?" },
                { path = "/lastLogin/?" },
                { path = "/preferences/?" }
              ]
              
              excluded_paths = [
                { path = "/metadata/*" },
                { path = "/audit/*" },
                { path = "/largeBlobs/*" }
              ]
              
              composite_indexes = [
                [
                  { path = "/userId", order = "ascending" },
                  { path = "/lastLogin", order = "descending" }
                ]
              ]
            }
            
            # Unique constraints
            unique_keys = [
              { paths = ["/email"] },
              { paths = ["/username"] }
            ]
            
            # Time-to-live for data cleanup
            default_ttl = 2592000               # 30 days default TTL
          },
          
          {
            name               = "sessions"
            partition_key_path = "/sessionId"
            throughput        = 2000
            
            # Session-specific configuration
            default_ttl = 86400                 # 24 hours for sessions
            
            indexing_policy = {
              automatic     = true
              indexing_mode = "consistent"
              
              included_paths = [
                { path = "/sessionId/?" },
                { path = "/userId/?" },
                { path = "/createdAt/?" },
                { path = "/expiresAt/?" }
              ]
              
              excluded_paths = [
                { path = "/sessionData/*" }      # Exclude large session data
              ]
            }
          },
          
          {
            name               = "analytics-events"
            partition_key_path = "/eventDate"
            throughput        = 4000
            
            # Analytics configuration
            analytical_storage_ttl = 2592000     # 30 days in analytical store
            default_ttl = 7776000               # 90 days in transactional store
            
            indexing_policy = {
              automatic     = true
              indexing_mode = "consistent"
              
              included_paths = [
                { path = "/eventDate/?" },
                { path = "/eventType/?" },
                { path = "/userId/?" }
              ]
              
              excluded_paths = [
                { path = "/eventPayload/*" }     # Large event data
              ]
            }
          }
        ]
      }
    ]
  }
}
```

### **💾 Production Storage Accounts**

```hcl
storage_accounts = {
  "application-data" = {
    account_tier              = "Standard"
    account_replication_type  = "GRS"          # Geo-redundant storage
    account_kind             = "StorageV2"     # General purpose v2
    access_tier              = "Hot"           # Hot access tier
    
    # Security configuration
    enable_https_traffic_only = true          # HTTPS only
    min_tls_version          = "TLS1_2"        # Minimum TLS 1.2
    allow_nested_items_to_be_public = false   # No public containers
    shared_access_key_enabled = false         # Disable shared keys
    
    # Advanced features
    enable_blob_versioning   = true           # Blob versioning
    enable_change_feed       = true           # Change feed for events
    enable_nfs_v3           = false          # NFS v3 support
    is_hns_enabled          = true           # Hierarchical namespace for Data Lake
    
    # Data protection
    blob_delete_retention_days = 30           # 30-day soft delete
    container_delete_retention_days = 30      # 30-day container recovery
    enable_point_in_time_restore = true      # Point-in-time restore
    point_in_time_restore_days = 7           # 7-day restore window
    
    # Cross-tenant replication
    enable_cross_tenant_replication = false   # Disable for security
    
    # Network security
    public_network_access_enabled = false     # Private access only
    default_action = "Deny"                  # Deny public access
    
    # Containers configuration
    containers = [
      {
        name        = "application-files"
        access_type = "private"
        
        # Container-level settings
        metadata = {
          environment = "production"
          purpose     = "application-data"
        }
      },
      {
        name        = "user-uploads"
        access_type = "private"
        
        metadata = {
          environment = "production"
          purpose     = "user-content"
          retention   = "7-years"
        }
      },
      {
        name        = "backup-data"
        access_type = "private"
        
        metadata = {
          environment = "production"
          purpose     = "backup-storage"
          tier        = "archive"
        }
      },
      {
        name        = "analytics-exports"
        access_type = "private"
        
        metadata = {
          environment = "production"
          purpose     = "data-analytics"
        }
      }
    ]
    
    # File shares for application data
    file_shares = [
      {
        name  = "shared-application-data"
        quota = 1024                          # 1TB quota
        
        # File share properties
        enabled_protocols = ["SMB"]
        metadata = {
          purpose = "shared-storage"
        }
      },
      {
        name  = "configuration-files"
        quota = 100                           # 100GB quota
        
        metadata = {
          purpose = "config-storage"
        }
      }
    ]
    
    # Queues for asynchronous processing
    queues = [
      {
        name = "file-processing-queue"
        
        metadata = {
          purpose = "async-file-processing"
        }
      },
      {
        name = "notification-queue"
        
        metadata = {
          purpose = "notification-service"
        }
      },
      {
        name = "audit-log-queue"
        
        metadata = {
          purpose = "audit-logging"
        }
      }
    ]
    
    # Tables for structured data
    tables = [
      {
        name = "audit-logs"
        
        metadata = {
          purpose = "audit-trail"
          retention = "7-years"
        }
      },
      {
        name = "session-metadata"
        
        metadata = {
          purpose = "session-tracking"
        }
      }
    ]
    
    # Lifecycle management
    management_policy = {
      rules = [
        {
          name    = "archive-old-data"
          enabled = true
          
          filters = {
            blob_types = ["blockBlob"]
            prefix_match = ["backup-data/"]
          }
          
          actions = {
            base_blob = {
              tier_to_cool_after_days    = 30
              tier_to_archive_after_days = 90
              delete_after_days         = 2555   # 7 years
            }
            
            snapshot = {
              delete_after_days = 30
            }
          }
        },
        
        {
          name    = "cleanup-temporary-files"
          enabled = true
          
          filters = {
            blob_types = ["blockBlob"]
            prefix_match = ["temp/", "cache/"]
          }
          
          actions = {
            base_blob = {
              delete_after_days = 7
            }
          }
        }
      ]
    }
  }
  
  "data-lake-storage" = {
    account_tier              = "Standard"
    account_replication_type  = "RAGRS"        # Read-access geo-redundant
    account_kind             = "StorageV2"
    access_tier              = "Hot"
    
    # Data Lake features
    is_hns_enabled          = true            # Hierarchical namespace (required for Data Lake)
    enable_nfs_v3           = false
    
    # Security for analytics data
    enable_https_traffic_only = true
    min_tls_version          = "TLS1_2"
    public_network_access_enabled = false
    
    # Analytics-specific containers
    containers = [
      {
        name        = "raw-data"
        access_type = "private"
      },
      {
        name        = "processed-data"
        access_type = "private"
      },
      {
        name        = "curated-data"
        access_type = "private"
      }
    ]
  }
}
```

### **⚡ Production Redis Cache**

```hcl
redis_caches = {
  "session-cache" = {
    capacity                      = 6           # 6GB P1 cache
    family                       = "P"          # Premium tier
    sku_name                     = "Premium"    # Premium features
    
    # Security configuration
    enable_non_ssl_port          = false       # SSL/TLS only
    minimum_tls_version          = "1.2"        # TLS 1.2 minimum
    redis_version               = "6"           # Latest Redis version
    enable_authentication       = true          # Require authentication
    
    # High availability
    shard_count                  = 3            # 3 shards for distribution
    replica_count                = 2            # 2 replicas per shard
    
    # Network security
    enable_private_endpoint      = true         # Private connectivity
    public_network_access_enabled = false       # No public access
    
    # Performance optimization
    maxmemory_reserved          = 200           # Reserved memory (MB)
    maxmemory_delta             = 200           # Delta memory (MB)
    maxmemory_policy            = "allkeys-lru" # Eviction policy
    
    # Persistence and backup
    enable_backup               = true          # Enable backups
    backup_frequency            = 60            # Hourly backups
    backup_max_snapshot_count   = 168           # 1 week retention (24*7)
    
    # Advanced security
    auth_token_enabled         = true           # Token authentication
    
    # Monitoring
    enable_diagnostic_settings  = true          # Enable diagnostics
    
    # Configuration overrides
    redis_configuration = {
      "maxmemory-policy"           = "allkeys-lru"
      "notify-keyspace-events"     = "Ex"        # Keyspace notifications
      "timeout"                   = "300"        # Connection timeout
      "tcp-keepalive"             = "300"        # TCP keepalive
    }
  }
  
  "application-cache" = {
    capacity                      = 2           # 2GB C2 cache
    family                       = "C"          # Basic/Standard tier
    sku_name                     = "Standard"   # Standard features
    
    # Basic security
    enable_non_ssl_port          = false
    minimum_tls_version          = "1.2"
    redis_version               = "6"
    enable_authentication       = true
    
    # Single instance (no clustering)
    shard_count                  = 1
    replica_count                = 1
    
    # Performance settings
    maxmemory_policy            = "volatile-lru" # Only evict keys with expiry
    
    # Backup (available in Standard)
    enable_backup               = false         # Disabled for cost optimization
    
    # Configuration for application caching
    redis_configuration = {
      "maxmemory-policy"           = "volatile-lru"
      "timeout"                   = "0"          # No timeout
      "databases"                 = "16"         # 16 databases
    }
  }
}
```

## 🔐 **Security & Compliance**

### **Data Encryption**
- **Encryption at Rest**: All data encrypted with customer-managed keys
- **Encryption in Transit**: TLS 1.2+ for all connections
- **Key Management**: Azure Key Vault integration for key rotation
- **Certificate Management**: Automated certificate provisioning and renewal

### **Access Control**
- **Private Endpoints**: All databases accessible via private connectivity only
- **Network Isolation**: VNet integration and network security groups
- **Identity-Based Access**: Managed identities and Azure AD authentication
- **RBAC**: Fine-grained role-based access control

### **Compliance Features**
- **Audit Logging**: Comprehensive audit trails for all data access
- **Data Residency**: Geographic data residency controls
- **Backup & Recovery**: Automated backups with geo-redundancy
- **Threat Detection**: Advanced threat protection and anomaly detection

## 📊 **Monitoring & Performance**

### **Database Monitoring**
```bash
# SQL Database performance metrics
az sql db show --name prod-app-db --server myproject-prod-sql-server --resource-group myproject-prod-data-rg

# Query performance insights
az sql db query-performance show-top --database-name prod-app-db --server-name myproject-prod-sql-server --resource-group myproject-prod-data-rg

# Check database size and usage
az sql db usage show --name prod-app-db --server myproject-prod-sql-server --resource-group myproject-prod-data-rg
```

### **Cosmos DB Monitoring**
```bash
# Account throughput and usage
az cosmosdb show --name myproject-prod-cosmos --resource-group myproject-prod-data-rg

# Database and container metrics
az cosmosdb sql database throughput show --account-name myproject-prod-cosmos --name production-db --resource-group myproject-prod-data-rg

# Query request units and performance
az monitor metrics list --resource /subscriptions/{subscription}/resourceGroups/myproject-prod-data-rg/providers/Microsoft.DocumentDB/databaseAccounts/myproject-prod-cosmos --metric "TotalRequestUnits"
```

### **Storage Monitoring**
```bash
# Storage account metrics
az storage account show --name myprojectprodstorage --resource-group myproject-prod-data-rg

# Blob storage usage and performance
az monitor metrics list --resource /subscriptions/{subscription}/resourceGroups/myproject-prod-data-rg/providers/Microsoft.Storage/storageAccounts/myprojectprodstorage --metric "UsedCapacity"

# Check storage account health
az storage account check-name --name myprojectprodstorage
```

## 🛠️ **Backup & Disaster Recovery**

### **SQL Database Backup Strategy**
- **Automated Backups**: Full backups weekly, differential daily, log every 5-10 minutes
- **Point-in-Time Restore**: Restore to any point within retention period
- **Long-Term Retention**: Weekly/monthly/yearly backups for compliance
- **Geo-Restore**: Cross-region restore capabilities

### **Cosmos DB Backup Strategy**
- **Continuous Backup**: Point-in-time restore with 30-day retention
- **Periodic Backup**: Traditional backup with configurable intervals
- **Cross-Region Backup**: Automatic geo-redundant backup storage
- **Self-Service Restore**: Portal-based restore capabilities

### **Storage Account Protection**
- **Soft Delete**: Blob and container soft delete with retention
- **Versioning**: Automatic blob versioning for change tracking
- **Point-in-Time Restore**: Container-level restore capabilities
- **Cross-Region Replication**: GRS/RA-GRS for geo-redundancy

## 📈 **Performance Optimization**

### **Database Performance Tuning**
```sql
-- SQL Database performance queries
SELECT TOP 10 
    qt.query_sql_text,
    q.query_id,
    qt.query_text_id,
    p.plan_id,
    rs.avg_duration,
    rs.avg_cpu_time,
    rs.avg_logical_io_reads
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs ON p.plan_id = rs.plan_id
WHERE rs.last_execution_time > DATEADD(hour, -24, GETUTCDATE())
ORDER BY rs.avg_duration DESC;

-- Index usage statistics
SELECT 
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.dm_db_index_usage_stats AS s
INNER JOIN sys.indexes AS i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;
```

### **Cosmos DB Optimization**
```bash
# Monitor RU consumption
az cosmosdb sql container throughput show --account-name myproject-prod-cosmos --database-name production-db --name users --resource-group myproject-prod-data-rg

# Check partition key distribution
# Use Azure portal or SDK to analyze partition key distribution and hot partitions

# Optimize indexing policy
az cosmosdb sql container update --account-name myproject-prod-cosmos --database-name production-db --name users --resource-group myproject-prod-data-rg --idx @indexing-policy.json
```

### **Storage Performance**
- **Access Tiers**: Optimize between Hot, Cool, and Archive based on usage
- **Performance Tiers**: Premium storage for high IOPS requirements
- **CDN Integration**: Azure CDN for global content distribution
- **Caching**: Redis cache integration for frequently accessed data

## 📚 **Additional Resources**

### **Documentation**
- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)
- [Azure Cosmos DB Documentation](https://docs.microsoft.com/en-us/azure/cosmos-db/)
- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [Azure Cache for Redis Documentation](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/)

### **Best Practices**
- [SQL Database Best Practices](https://docs.microsoft.com/en-us/azure/azure-sql/database/performance-guidance)
- [Cosmos DB Best Practices](https://docs.microsoft.com/en-us/azure/cosmos-db/best-practice-dotnet)
- [Storage Best Practices](https://docs.microsoft.com/en-us/azure/storage/common/storage-performance-checklist)

---

**📍 Navigation**: [⬅️ Security Layer](../security/README.md) | [🏠 Main README](../../README.md) | [➡️ Compute Layer](../compute/README.md)