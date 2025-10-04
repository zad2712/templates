# Data Layer

## Overview

The **Data Layer** provides comprehensive data storage, management, and processing infrastructure for your applications. This layer includes relational databases, caching systems, object storage, and data analytics components that serve as the persistent storage backbone for your architecture.

## Purpose

The data layer establishes:
- **Relational Databases**: High-performance, scalable RDS instances
- **Caching Systems**: Redis and Memcached for application performance
- **Object Storage**: S3 buckets for file storage and static content
- **NoSQL Databases**: DynamoDB for flexible, serverless data storage
- **Data Analytics**: Foundation for data processing and analytics workloads

## Architecture

### 🗃️ **Core Data Components**

#### **Amazon RDS (Relational Database Service)**
- **Multi-AZ Deployment**: High availability and automatic failover
- **Read Replicas**: Scalable read performance
- **Automated Backups**: Point-in-time recovery capabilities
- **Encryption**: Data encryption at rest and in transit

#### **Amazon ElastiCache**
- **Redis**: Advanced data structures and persistence
- **Memcached**: Simple, high-performance caching
- **Cluster Mode**: Automatic scaling and sharding
- **Security**: VPC placement and encryption

#### **Amazon S3 (Simple Storage Service)**
- **Multiple Bucket Types**: Various storage classes for different use cases
- **Lifecycle Policies**: Automated data archiving and deletion
- **Versioning**: Object version control and protection
- **Cross-Region Replication**: Disaster recovery and compliance

#### **Amazon DynamoDB**
- **Serverless**: Pay-per-use, automatic scaling
- **Global Tables**: Multi-region replication
- **Point-in-Time Recovery**: Continuous backups
- **On-Demand**: Flexible capacity management

## Layer Structure

```
data/
├── README.md                    # This documentation
├── main.tf                      # Main data configuration
├── variables.tf                 # Input variables
├── outputs.tf                   # Data layer outputs
├── locals.tf                    # Local data calculations
├── providers.tf                 # Terraform and provider configuration
└── environments/
    ├── dev/
    │   ├── backend.conf         # S3 backend configuration
    │   └── terraform.auto.tfvars# Dev data settings
    ├── qa/
    │   ├── backend.conf
    │   └── terraform.auto.tfvars
    ├── uat/
    │   ├── backend.conf
    │   └── terraform.auto.tfvars
    └── prod/
        ├── backend.conf
        └── terraform.auto.tfvars
```

## Modules Used

### **RDS Module**
```hcl
module "rds" {
  count  = length(var.rds_instances) > 0 ? 1 : 0
  source = "../../modules/rds"
  
  # Database instances configuration
  instances = var.rds_instances
  
  # Network configuration
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.networking.outputs.database_subnets
  
  # Security
  security_group_ids = [data.terraform_remote_state.security.outputs.security_group_ids["rds"]]
  kms_key_id = data.terraform_remote_state.security.outputs.kms_key_ids["rds"]
  
  tags = local.common_tags
}
```

### **ElastiCache Module**
```hcl
module "elasticache" {
  count  = length(var.elasticache_clusters) > 0 ? 1 : 0
  source = "../../modules/elasticache"
  
  # Cache cluster configurations
  clusters = var.elasticache_clusters
  
  # Network configuration
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.networking.outputs.private_subnets
  
  # Security
  security_group_ids = [data.terraform_remote_state.security.outputs.security_group_ids["cache"]]
  
  tags = local.common_tags
}
```

### **S3 Module**
```hcl
module "s3" {
  source = "../../modules/s3"
  
  # S3 bucket configurations
  buckets = var.s3_buckets
  
  # Security and encryption
  kms_key_id = data.terraform_remote_state.security.outputs.kms_key_ids["s3"]
  
  tags = local.common_tags
}
```

### **DynamoDB Module**
```hcl
module "dynamodb" {
  count  = length(var.dynamodb_tables) > 0 ? 1 : 0
  source = "../../modules/dynamodb"
  
  # DynamoDB table configurations
  tables = var.dynamodb_tables
  
  # Security
  kms_key_id = data.terraform_remote_state.security.outputs.kms_key_ids["dynamodb"]
  
  tags = local.common_tags
}
```

## Database Configurations

### 🗄️ **RDS Instance Types**

#### **PostgreSQL Production Setup**
```hcl
primary_db = {
  identifier = "myapp-prod-db"
  
  # Engine configuration
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r6g.xlarge"
  
  # Storage
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type         = "gp3"
  storage_encrypted    = true
  
  # High availability
  multi_az               = true
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Performance
  performance_insights_enabled = true
  monitoring_interval         = 60
  
  # Security
  deletion_protection = true
  skip_final_snapshot = false
}
```

#### **MySQL Development Setup**
```hcl
dev_db = {
  identifier = "myapp-dev-db"
  
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t4g.micro"  # Cost optimized
  
  allocated_storage = 20
  storage_encrypted = true
  
  # Single AZ for cost savings
  multi_az = false
  backup_retention_period = 7
  
  deletion_protection = false
  skip_final_snapshot = true
}
```

### ⚡ **ElastiCache Configurations**

#### **Redis Cluster**
```hcl
redis_cluster = {
  cluster_id = "myapp-redis"
  
  # Engine configuration
  engine         = "redis"
  engine_version = "7.0"
  node_type      = "cache.r7g.large"
  
  # Cluster setup
  num_cache_nodes = 3
  port           = 6379
  
  # High availability
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_enabled        = true
  
  # Maintenance
  maintenance_window = "sun:03:00-sun:04:00"
  snapshot_window    = "02:00-03:00"
  snapshot_retention_limit = 7
}
```

#### **Memcached Cluster**
```hcl
memcached_cluster = {
  cluster_id = "myapp-memcached"
  
  engine         = "memcached"
  engine_version = "1.6.17"
  node_type      = "cache.t4g.micro"
  num_cache_nodes = 2
  port           = 11211
}
```

## Storage Configurations

### 📦 **S3 Bucket Types**

#### **Application Data Bucket**
```hcl
app_data = {
  bucket_name = "myapp-${var.environment}-data"
  
  # Versioning and lifecycle
  versioning_enabled = true
  lifecycle_rules = [
    {
      id     = "archive_old_versions"
      status = "Enabled"
      
      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]
  
  # Security
  public_read_access  = false
  public_write_access = false
  block_public_acls   = true
  
  # Encryption
  server_side_encryption_configuration = {
    kms_master_key_id = "aws/s3"  # or custom KMS key
    sse_algorithm     = "aws:kms"
  }
}
```

#### **Static Website Bucket**
```hcl
static_website = {
  bucket_name = "myapp-${var.environment}-static"
  
  # Website configuration
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }
  
  # Public read access for website
  public_read_access = true
  
  # CORS configuration
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://myapp.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}
```

### 🚀 **DynamoDB Tables**

#### **User Sessions Table**
```hcl
user_sessions = {
  name = "UserSessions"
  
  # Capacity
  billing_mode = "PAY_PER_REQUEST"  # On-demand
  
  # Schema
  hash_key  = "user_id"
  range_key = "session_id"
  
  attributes = [
    {
      name = "user_id"
      type = "S"
    },
    {
      name = "session_id"
      type = "S"
    },
    {
      name = "created_at"
      type = "N"
    }
  ]
  
  # TTL for automatic cleanup
  ttl = {
    attribute_name = "expires_at"
    enabled        = true
  }
  
  # Global Secondary Index
  global_secondary_indexes = [
    {
      name     = "CreatedAtIndex"
      hash_key = "created_at"
      
      projection_type    = "KEYS_ONLY"
      non_key_attributes = []
    }
  ]
  
  # Backup and recovery
  point_in_time_recovery_enabled = true
}
```

## Environment-Specific Configurations

### 🌍 **Development Environment**
```hcl
# Cost-optimized configuration
rds_instances = {
  dev_db = {
    instance_class = "db.t4g.micro"
    multi_az      = false
    backup_retention_period = 1
    deletion_protection = false
  }
}

elasticache_clusters = {
  redis = {
    node_type      = "cache.t4g.micro"
    num_cache_nodes = 1
    multi_az_enabled = false
  }
}

# Minimal S3 buckets
s3_buckets = {
  app_data = {
    versioning_enabled = false
    lifecycle_rules   = []
  }
}
```

### 🏭 **Production Environment**
```hcl
# High availability and performance
rds_instances = {
  primary_db = {
    instance_class = "db.r6g.xlarge"
    multi_az      = true
    backup_retention_period = 30
    deletion_protection = true
    
    # Read replicas for scaling
    read_replicas = [
      {
        identifier = "primary-db-read-1"
        instance_class = "db.r6g.large"
      },
      {
        identifier = "primary-db-read-2"
        instance_class = "db.r6g.large"
      }
    ]
  }
}

elasticache_clusters = {
  redis = {
    node_type = "cache.r7g.large"
    num_cache_nodes = 3
    automatic_failover_enabled = true
    multi_az_enabled = true
  }
}

# Comprehensive S3 setup
s3_buckets = {
  app_data = { /* full configuration */ }
  backups  = { /* backup storage */ }
  logs     = { /* application logs */ }
  static   = { /* static assets */ }
}
```

## Key Outputs

```hcl
# RDS Information
output "rds_endpoints" {
  description = "RDS instance endpoints"
  value = length(var.rds_instances) > 0 ? {
    for name, instance in module.rds[0].instances : name => {
      endpoint = instance.endpoint
      port     = instance.port
    }
  } : {}
}

# ElastiCache Information
output "elasticache_endpoints" {
  description = "ElastiCache cluster endpoints"
  value = length(var.elasticache_clusters) > 0 ? {
    for name, cluster in module.elasticache[0].clusters : name => {
      primary_endpoint = cluster.primary_endpoint
      reader_endpoint  = cluster.reader_endpoint
      port            = cluster.port
    }
  } : {}
}

# S3 Bucket Information
output "s3_buckets" {
  description = "S3 bucket information"
  value = {
    for name, bucket in module.s3.buckets : name => {
      id                = bucket.id
      arn               = bucket.arn
      bucket_domain_name = bucket.bucket_domain_name
    }
  }
}

# DynamoDB Information
output "dynamodb_tables" {
  description = "DynamoDB table information"
  value = length(var.dynamodb_tables) > 0 ? {
    for name, table in module.dynamodb[0].tables : name => {
      name = table.name
      arn  = table.arn
    }
  } : {}
}
```

## Performance Optimization

### 🚀 **Database Performance**

#### **RDS Optimization**
- **Instance Sizing**: Right-size based on CPU and memory usage
- **Storage Type**: Use gp3 for cost-effective performance
- **Read Replicas**: Scale read workloads horizontally
- **Connection Pooling**: Implement application-level pooling

#### **ElastiCache Optimization**
- **Node Types**: Memory-optimized instances for caching workloads
- **Cluster Mode**: Use cluster mode for Redis scaling
- **TTL Strategy**: Implement appropriate cache expiration policies
- **Monitoring**: Track hit rates and memory utilization

### 📊 **Monitoring and Metrics**

#### **CloudWatch Metrics**
- **RDS**: CPU utilization, connection count, IOPS
- **ElastiCache**: Hit rate, memory usage, network throughput
- **S3**: Request metrics, storage metrics, data transfer
- **DynamoDB**: Read/write capacity, throttling events

#### **Performance Insights**
- Enable for RDS instances to identify slow queries
- Monitor wait events and top SQL statements
- Set up automated alerts for performance degradation

## Backup and Disaster Recovery

### 💾 **Backup Strategies**

#### **RDS Backups**
```hcl
# Automated backups
backup_retention_period = 30  # 30 days
backup_window          = "03:00-04:00"

# Manual snapshots for major releases
# Cross-region backup replication for DR
```

#### **S3 Backup**
```hcl
# Cross-region replication
replication_configuration = {
  role = aws_iam_role.replication.arn
  
  rules = [
    {
      id     = "backup-replication"
      status = "Enabled"
      
      destination = {
        bucket        = "myapp-backup-us-west-2"
        storage_class = "STANDARD_IA"
      }
    }
  ]
}
```

#### **DynamoDB Backup**
- Point-in-time recovery enabled
- On-demand backups before major changes
- Cross-region backups for disaster recovery

### 🔄 **Disaster Recovery**

#### **RTO/RPO Targets**
- **Production**: RTO < 1 hour, RPO < 15 minutes
- **UAT**: RTO < 4 hours, RPO < 1 hour
- **Dev**: RTO < 24 hours, RPO < 4 hours

#### **DR Procedures**
1. **Detection**: Automated monitoring and alerting
2. **Assessment**: Determine scope and impact
3. **Recovery**: Execute documented recovery procedures
4. **Validation**: Test application functionality
5. **Communication**: Update stakeholders on status

## Security Best Practices

### 🔒 **Data Security**

#### **Encryption**
- **At Rest**: All storage encrypted with KMS keys
- **In Transit**: TLS/SSL for all database connections
- **Key Management**: Rotate encryption keys regularly
- **Access Control**: Principle of least privilege

#### **Network Security**
- **VPC Placement**: All databases in private subnets
- **Security Groups**: Restrictive inbound rules
- **Network ACLs**: Additional subnet-level protection
- **VPC Endpoints**: Private connectivity to AWS services

#### **Access Management**
- **IAM Roles**: Service-specific database access
- **Database Users**: Application-specific database accounts
- **Secrets Manager**: Automated credential rotation
- **Auditing**: Enable database audit logging

## Cost Optimization

### 💰 **Cost Management**

#### **RDS Cost Optimization**
- **Reserved Instances**: 1-3 year commitments for stable workloads
- **Right Sizing**: Monitor and adjust instance classes
- **Storage**: Use gp3 instead of gp2 for better price/performance
- **Automated Scaling**: Aurora serverless for variable workloads

#### **S3 Cost Optimization**
- **Storage Classes**: Use appropriate classes (IA, Glacier)
- **Lifecycle Policies**: Automatic transition and deletion
- **Intelligent Tiering**: Automatic cost optimization
- **Transfer Optimization**: Use CloudFront for content delivery

#### **ElastiCache Cost Optimization**
- **Reserved Nodes**: For predictable cache workloads
- **Node Sizing**: Monitor memory utilization
- **Cluster Mode**: Scale horizontally instead of vertically

## Related Documentation

- [Main Project README](../../README.md)
- [Security Layer README](../security/README.md)
- [RDS Module Documentation](../../modules/rds/README.md)
- [S3 Module Documentation](../../modules/s3/README.md)
- [AWS Database Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)

---

## 👤 Author

**Diego A. Zarate** - *Data Architecture & Database Specialist*

---

> 🗃️ **Data Foundation**: This layer provides scalable, secure, and performant data storage for your applications. Regular monitoring and optimization ensure optimal performance and cost-effectiveness.
