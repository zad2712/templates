# RDS Module

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)

## Overview

This Terraform module creates and manages Amazon RDS (Relational Database Service) resources with comprehensive configuration options following AWS best practices and security guidelines. The module supports multiple database engines, high availability configurations, automated backups, security features, monitoring, and performance optimization.

## Features

- **Multiple Database Engines**: MySQL, PostgreSQL, Oracle, SQL Server, MariaDB, and Aurora (MySQL/PostgreSQL)
- **High Availability**: Multi-AZ deployments, Aurora clusters with automatic failover
- **Security**: Encryption at rest and in transit, VPC integration, IAM database authentication
- **Automated Backups**: Point-in-time recovery, automated snapshots, cross-region backup replication
- **Performance**: Performance Insights, Enhanced Monitoring, read replicas
- **Scaling**: Aurora Serverless, storage auto-scaling, connection pooling with RDS Proxy
- **Parameter Management**: Custom parameter groups and option groups
- **Network Security**: VPC security groups, private subnets, SSL/TLS enforcement
- **Monitoring**: CloudWatch integration, log exports, custom metrics and alarms
- **Maintenance**: Automated maintenance windows, minor version upgrades

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          RDS Module                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   RDS Instance  │  │  Aurora Cluster │  │   RDS Proxy     │  │
│  │   (Single AZ)   │  │   (Multi-AZ)    │  │ (Connection     │  │
│  │                 │  │                 │  │  Pooling)       │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │   Multi-AZ RDS  │  │  Read Replicas  │                      │
│  │   (Standby)     │  │  (Scaling)      │                      │
│  └─────────────────┘  └─────────────────┘                      │
├─────────────────────────────────────────────────────────────────┤
│                     Supporting Resources                        │
│  • DB Subnet Groups     • Parameter Groups                     │
│  • Option Groups        • Security Groups                       │
│  • KMS Encryption       • CloudWatch Logs                      │
├─────────────────────────────────────────────────────────────────┤
│                      Network & Security                         │
│  • VPC Integration      • Private Subnets                      │
│  • Security Groups      • IAM Roles & Policies                 │
│  • SSL/TLS Encryption   • At-Rest Encryption                   │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic MySQL Instance

```hcl
module "rds_mysql" {
  source = "./modules/rds"

  name_prefix = "myapp"

  # DB Subnet Group
  db_subnet_groups = {
    "main" = {
      subnet_ids  = ["subnet-12345678", "subnet-87654321"]
      description = "Main DB subnet group"
    }
  }

  # MySQL Instance
  rds_instances = {
    "mysql-primary" = {
      allocated_storage     = 20
      max_allocated_storage = 100
      storage_type          = "gp3"
      storage_encrypted     = true
      
      engine         = "mysql"
      engine_version = "8.0.35"
      instance_class = "db.t3.micro"
      db_name        = "appdb"
      username       = "admin"
      
      db_subnet_group_name   = "main"
      vpc_security_group_ids = [module.security_groups.database_sg_id]
      
      multi_az               = true
      backup_retention_period = 7
      deletion_protection    = true
      
      performance_insights_enabled = true
      enabled_cloudwatch_logs_exports = ["error", "general", "slow"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-application"
  }
}
```

### Aurora PostgreSQL Cluster

```hcl
module "rds_aurora" {
  source = "./modules/rds"

  name_prefix = "enterprise"

  # DB Subnet Group
  db_subnet_groups = {
    "aurora" = {
      subnet_ids  = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]
      description = "Aurora cluster subnet group"
    }
  }

  # Cluster Parameter Group
  rds_cluster_parameter_groups = {
    "aurora-postgresql" = {
      family = "aurora-postgresql15"
      parameters = [
        {
          name  = "shared_preload_libraries"
          value = "pg_stat_statements"
        },
        {
          name  = "log_statement"
          value = "all"
        }
      ]
    }
  }

  # Aurora Cluster
  rds_clusters = {
    "postgresql-cluster" = {
      engine              = "aurora-postgresql"
      engine_version      = "15.4"
      database_name       = "enterprisedb"
      master_username     = "postgres"
      
      db_subnet_group_name            = "aurora"
      db_cluster_parameter_group_name = "aurora-postgresql"
      vpc_security_group_ids          = [module.security_groups.database_sg_id]
      
      storage_encrypted       = true
      kms_key_id             = module.kms.key_arns["rds"]
      backup_retention_period = 30
      deletion_protection     = true
      
      enabled_cloudwatch_logs_exports = ["postgresql"]
      
      availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
    }
  }

  # Cluster Instances
  rds_cluster_instances = {
    "writer" = {
      cluster_identifier = "postgresql-cluster"
      instance_class     = "db.r6g.large"
      engine            = "aurora-postgresql"
      
      performance_insights_enabled = true
      monitoring_interval          = 60
      monitoring_role_arn         = module.iam.enhanced_monitoring_role_arn
    },
    "reader-1" = {
      cluster_identifier = "postgresql-cluster"
      instance_class     = "db.r6g.large"
      engine            = "aurora-postgresql"
      
      performance_insights_enabled = true
    }
  }

  tags = {
    Environment = "production"
    Project     = "enterprise-app"
    Tier        = "database"
  }
}
```

### Enterprise Setup with RDS Proxy

```hcl
module "rds_enterprise" {
  source = "./modules/rds"

  name_prefix = "prod"

  # DB Subnet Groups
  db_subnet_groups = {
    "primary" = {
      subnet_ids  = ["subnet-12345678", "subnet-87654321"]
      description = "Primary database subnet group"
    }
  }

  # Parameter Groups
  db_parameter_groups = {
    "mysql-custom" = {
      family = "mysql8.0"
      parameters = [
        {
          name  = "innodb_buffer_pool_size"
          value = "{DBInstanceClassMemory*3/4}"
        },
        {
          name  = "max_connections"
          value = "1000"
        },
        {
          name  = "slow_query_log"
          value = "1"
        }
      ]
    }
  }

  # RDS Instance
  rds_instances = {
    "mysql-primary" = {
      allocated_storage     = 500
      max_allocated_storage = 1000
      storage_type          = "gp3"
      storage_encrypted     = true
      kms_key_id           = module.kms.key_arns["rds"]
      
      engine         = "mysql"
      engine_version = "8.0.35"
      instance_class = "db.r5.xlarge"
      db_name        = "proddb"
      username       = "admin"
      
      db_subnet_group_name   = "primary"
      parameter_group_name   = "mysql-custom"
      vpc_security_group_ids = [module.security_groups.database_sg_id]
      
      multi_az                      = true
      backup_retention_period       = 30
      backup_window                = "03:00-04:00"
      maintenance_window           = "sun:04:00-sun:05:00"
      deletion_protection          = true
      
      performance_insights_enabled = true
      performance_insights_retention_period = 93
      monitoring_interval          = 60
      monitoring_role_arn         = module.iam.enhanced_monitoring_role_arn
      
      enabled_cloudwatch_logs_exports = ["error", "general", "slow"]
    }
  }

  # RDS Proxy for connection pooling
  rds_proxies = {
    "mysql-proxy" = {
      engine_family = "MYSQL"
      auth = [
        {
          auth_scheme = "SECRETS"
          secret_arn  = aws_secretsmanager_secret.db_credentials.arn
        }
      ]
      role_arn              = module.iam.rds_proxy_role_arn
      vpc_subnet_ids        = ["subnet-12345678", "subnet-87654321"]
      vpc_security_group_ids = [module.security_groups.rds_proxy_sg_id]
      
      require_tls = true
      
      connection_pool_config = {
        max_connections_percent = 100
        max_idle_connections_percent = 50
        connection_borrow_timeout = 120
      }
      
      targets = [
        {
          db_instance_identifier = "mysql-primary"
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "enterprise-app"
    Compliance  = "required"
  }
}
```

### Aurora Serverless for Development

```hcl
module "rds_dev" {
  source = "./modules/rds"

  name_prefix = "dev"

  db_subnet_groups = {
    "dev" = {
      subnet_ids  = ["subnet-dev1", "subnet-dev2"]
      description = "Development environment subnet group"
    }
  }

  rds_clusters = {
    "aurora-serverless" = {
      engine         = "aurora-mysql"
      engine_version = "5.7.mysql_aurora.2.10.1"
      engine_mode   = "serverless"
      database_name = "devdb"
      
      db_subnet_group_name   = "dev"
      vpc_security_group_ids = [module.security_groups.database_sg_id]
      
      storage_encrypted       = true
      backup_retention_period = 1
      skip_final_snapshot    = true
      
      scaling_configuration = {
        auto_pause               = true
        max_capacity            = 2
        min_capacity            = 1
        seconds_until_auto_pause = 300
      }
    }
  }

  tags = {
    Environment = "development"
    AutoShutdown = "enabled"
  }
}
```

### Multi-Region Setup with Cross-Region Backups

```hcl
# Primary region RDS
module "rds_primary" {
  source = "./modules/rds"
  
  providers = {
    aws = aws.primary
  }

  name_prefix = "primary"

  db_subnet_groups = {
    "primary" = {
      subnet_ids = ["subnet-primary-1", "subnet-primary-2"]
    }
  }

  rds_instances = {
    "mysql-primary" = {
      allocated_storage   = 100
      engine             = "mysql"
      engine_version     = "8.0.35"
      instance_class     = "db.r5.large"
      
      multi_az           = true
      storage_encrypted  = true
      
      backup_retention_period = 35
      copy_tags_to_snapshot  = true
      
      # Cross-region automated backups
      backup_window = "03:00-04:00"
    }
  }
}

# Disaster recovery region
module "rds_dr" {
  source = "./modules/rds"
  
  providers = {
    aws = aws.dr_region
  }

  name_prefix = "dr"

  # Read replica for disaster recovery
  rds_instances = {
    "mysql-replica" = {
      replicate_source_db = module.rds_primary.rds_instance_arns["mysql-primary"]
      instance_class      = "db.r5.large"
      
      storage_encrypted   = true
      kms_key_id         = module.kms_dr.key_arns["rds"]
      
      backup_retention_period = 7
      skip_final_snapshot    = false
      final_snapshot_identifier = "mysql-replica-final-snapshot"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Name prefix for RDS resources | `string` | `"app"` | no |
| tags | A map of tags to assign to RDS resources | `map(string)` | `{}` | no |
| db_subnet_groups | Map of DB subnet groups to create | `map(object)` | `{}` | no |
| db_parameter_groups | Map of DB parameter groups to create | `map(object)` | `{}` | no |
| db_option_groups | Map of DB option groups to create | `map(object)` | `{}` | no |
| rds_cluster_parameter_groups | Map of RDS cluster parameter groups to create | `map(object)` | `{}` | no |
| rds_instances | Map of RDS instances to create | `map(object)` | `{}` | no |
| rds_clusters | Map of RDS clusters to create | `map(object)` | `{}` | no |
| rds_cluster_instances | Map of RDS cluster instances to create | `map(object)` | `{}` | no |
| rds_proxies | Map of RDS proxies to create | `map(object)` | `{}` | no |

### RDS Instance Configuration Options

Each RDS instance in the `rds_instances` map supports the following configuration options:

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `allocated_storage` | Initial storage allocation in GB | `number` | Required |
| `max_allocated_storage` | Maximum storage for auto-scaling | `number` | `null` |
| `storage_type` | Storage type (gp2, gp3, io1, io2) | `string` | `"gp3"` |
| `storage_encrypted` | Enable storage encryption | `bool` | `true` |
| `engine` | Database engine | `string` | Required |
| `engine_version` | Database engine version | `string` | `null` |
| `instance_class` | RDS instance class | `string` | Required |
| `multi_az` | Enable Multi-AZ deployment | `bool` | `false` |
| `backup_retention_period` | Backup retention period in days | `number` | `7` |
| `performance_insights_enabled` | Enable Performance Insights | `bool` | `false` |
| `deletion_protection` | Enable deletion protection | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| rds_instances | Map of RDS instance information |
| rds_instance_endpoints | RDS instance endpoints |
| rds_instance_arns | RDS instance ARNs |
| rds_clusters | Map of RDS cluster information |
| rds_cluster_endpoints | RDS cluster endpoints |
| rds_cluster_reader_endpoints | RDS cluster reader endpoints |
| rds_proxies | Map of RDS proxy information |
| rds_proxy_endpoints | RDS proxy endpoints |
| connection_info | Connection information for all RDS resources |

## Supported Database Engines

### RDS Instances
- **MySQL**: 5.7, 8.0
- **PostgreSQL**: 11, 12, 13, 14, 15, 16
- **MariaDB**: 10.3, 10.4, 10.5, 10.6, 10.11
- **Oracle**: SE2, EE (12c, 19c, 21c)
- **SQL Server**: Express, Web, Standard, Enterprise (2017, 2019, 2022)

### Aurora Clusters
- **Aurora MySQL**: 5.7, 8.0 compatible
- **Aurora PostgreSQL**: 11, 12, 13, 14, 15, 16 compatible

## Security Best Practices

### 1. Network Security
- **VPC Integration**: All databases deployed in private subnets
- **Security Groups**: Restrictive security group rules
- **SSL/TLS**: Encrypted connections enforced by default
- **Private Access**: No public accessibility by default

### 2. Encryption
- **At-Rest**: KMS encryption enabled by default
- **In-Transit**: SSL/TLS connections required
- **Key Management**: Customer-managed KMS keys supported
- **Backup Encryption**: Encrypted backups and snapshots

### 3. Access Control
- **IAM Integration**: IAM database authentication support
- **Master User Management**: AWS-managed master user passwords
- **Secrets Management**: Integration with AWS Secrets Manager
- **Principle of Least Privilege**: Minimal required permissions

### 4. Monitoring and Auditing
- **CloudTrail**: API call logging enabled
- **Performance Insights**: Query-level performance monitoring
- **CloudWatch Logs**: Database log exports to CloudWatch
- **Enhanced Monitoring**: OS-level metrics collection

## High Availability Patterns

### 1. Multi-AZ Deployment
```hcl
rds_instances = {
  "highly-available" = {
    multi_az = true
    backup_retention_period = 30
    deletion_protection = true
  }
}
```

### 2. Aurora Cluster with Multiple Instances
```hcl
rds_clusters = {
  "aurora-ha" = {
    availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
}

rds_cluster_instances = {
  "writer" = {
    cluster_identifier = "aurora-ha"
    instance_class = "db.r6g.large"
  }
  "reader-1" = {
    cluster_identifier = "aurora-ha"
    instance_class = "db.r6g.large"
  }
  "reader-2" = {
    cluster_identifier = "aurora-ha"
    instance_class = "db.r6g.large"
  }
}
```

### 3. Cross-Region Read Replicas
```hcl
# Primary instance
rds_instances = {
  "primary" = {
    engine = "mysql"
    backup_retention_period = 7
  }
}

# Read replica in different region
rds_instances = {
  "cross-region-replica" = {
    replicate_source_db = "arn:aws:rds:us-west-2:123456789012:db:primary"
    instance_class = "db.t3.medium"
  }
}
```

## Performance Optimization

### 1. Parameter Tuning
```hcl
db_parameter_groups = {
  "performance-tuned" = {
    family = "mysql8.0"
    parameters = [
      {
        name = "innodb_buffer_pool_size"
        value = "{DBInstanceClassMemory*3/4}"
      },
      {
        name = "innodb_log_file_size"
        value = "268435456"  # 256MB
      },
      {
        name = "max_connections"
        value = "1000"
      }
    ]
  }
}
```

### 2. Storage Optimization
```hcl
rds_instances = {
  "performance-optimized" = {
    storage_type = "gp3"
    iops = 3000
    storage_throughput = 125
    max_allocated_storage = 1000  # Auto-scaling
  }
}
```

### 3. Connection Pooling
```hcl
rds_proxies = {
  "connection-pool" = {
    connection_pool_config = {
      max_connections_percent = 100
      max_idle_connections_percent = 50
      connection_borrow_timeout = 120
    }
  }
}
```

## Cost Optimization

### 1. Aurora Serverless for Variable Workloads
```hcl
rds_clusters = {
  "cost-optimized" = {
    engine_mode = "serverless"
    scaling_configuration = {
      auto_pause = true
      max_capacity = 2
      min_capacity = 1
      seconds_until_auto_pause = 300
    }
  }
}
```

### 2. Storage Auto-Scaling
```hcl
rds_instances = {
  "auto-scaling" = {
    allocated_storage = 20      # Start small
    max_allocated_storage = 100  # Scale as needed
    storage_type = "gp3"        # Cost-effective storage
  }
}
```

### 3. Development Environment Optimization
```hcl
rds_instances = {
  "development" = {
    instance_class = "db.t3.micro"
    allocated_storage = 20
    backup_retention_period = 1
    skip_final_snapshot = true
    deletion_protection = false
  }
}
```

## Monitoring and Alerting

### 1. Performance Insights
```hcl
rds_instances = {
  "monitored" = {
    performance_insights_enabled = true
    performance_insights_retention_period = 93  # 3 months
    monitoring_interval = 60
    monitoring_role_arn = aws_iam_role.enhanced_monitoring.arn
  }
}
```

### 2. CloudWatch Log Exports
```hcl
# MySQL
enabled_cloudwatch_logs_exports = ["error", "general", "slow"]

# PostgreSQL
enabled_cloudwatch_logs_exports = ["postgresql"]

# Aurora MySQL
enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
```

### 3. CloudWatch Alarms Example
```hcl
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "rds-high-cpu-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  
  dimensions = {
    DBInstanceIdentifier = module.rds.rds_instance_ids[each.key]
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Backup and Recovery

### 1. Automated Backups
```hcl
rds_instances = {
  "production" = {
    backup_retention_period = 30        # 30 days retention
    backup_window = "03:00-04:00"      # Low-traffic window
    copy_tags_to_snapshot = true
    delete_automated_backups = false
  }
}
```

### 2. Final Snapshots
```hcl
rds_instances = {
  "important-data" = {
    skip_final_snapshot = false
    final_snapshot_identifier = "final-snapshot-${timestamp()}"
    deletion_protection = true
  }
}
```

### 3. Cross-Region Backup Replication
```hcl
# Enable automated backups in primary region
backup_retention_period = 35

# Create read replica in different region for DR
rds_instances = {
  "dr-replica" = {
    replicate_source_db = module.primary_rds.rds_instance_arns["primary"]
    backup_retention_period = 7
  }
}
```

## Maintenance and Updates

### 1. Maintenance Windows
```hcl
rds_instances = {
  "production" = {
    maintenance_window = "sun:04:00-sun:05:00"  # Sunday 4-5 AM UTC
    auto_minor_version_upgrade = true
    allow_major_version_upgrade = false
    apply_immediately = false
  }
}
```

### 2. Parameter Group Changes
```hcl
db_parameter_groups = {
  "custom" = {
    parameters = [
      {
        name = "slow_query_log"
        value = "1"
        apply_method = "immediate"  # or "pending-reboot"
      }
    ]
  }
}
```

## Compliance and Governance

### 1. Encryption Requirements
```hcl
# All databases encrypted with customer-managed keys
storage_encrypted = true
kms_key_id = module.kms.key_arns["rds"]

# Backup encryption
copy_tags_to_snapshot = true
```

### 2. Tagging Strategy
```hcl
tags = {
  Environment     = "production"
  Project         = "enterprise-app"
  Owner          = "database-team"
  CostCenter     = "engineering"
  DataClass      = "confidential"
  Compliance     = "sox-pci"
  BackupRequired = "true"
  RetentionDays  = "2555"  # 7 years
}
```

### 3. Deletion Protection
```hcl
rds_instances = {
  "critical-data" = {
    deletion_protection = true
    skip_final_snapshot = false
    final_snapshot_identifier = "critical-data-final-${timestamp()}"
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Connection Timeouts
```
Error: Could not connect to database
```
**Solutions**:
- Check security group rules allow database port
- Verify subnet routing and NACLs
- Ensure RDS instance is in correct subnet group
- Check if RDS Proxy is needed for connection pooling

#### 2. Performance Issues
```
Slow query performance
```
**Solutions**:
- Enable Performance Insights for query analysis
- Review and tune parameter group settings
- Consider read replicas for read-heavy workloads
- Upgrade instance class if CPU/memory constrained

#### 3. Backup Failures
```
Backup window conflicts with maintenance window
```
**Solutions**:
- Ensure backup window doesn't overlap with maintenance window
- Verify sufficient storage space for backups
- Check IAM permissions for backup operations

#### 4. Encryption Key Issues
```
Error: KMS key not found or access denied
```
**Solutions**:
- Verify KMS key exists and is active
- Check IAM permissions for KMS key usage
- Ensure key policy allows RDS service access

### Debugging Commands

```bash
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier instance-name

# Monitor RDS events
aws rds describe-events --source-identifier instance-name --source-type db-instance

# Check parameter group parameters
aws rds describe-db-parameters --db-parameter-group-name group-name

# View cluster status (Aurora)
aws rds describe-db-clusters --db-cluster-identifier cluster-name

# Check proxy status
aws rds describe-db-proxies --db-proxy-name proxy-name

# Monitor performance insights
aws pi get-resource-metrics --service-type RDS --identifier resource-id
```

## Migration Strategies

### 1. MySQL to Aurora MySQL Migration
```hcl
# Step 1: Create Aurora cluster
rds_clusters = {
  "aurora-target" = {
    engine = "aurora-mysql"
    database_name = var.source_db_name
    storage_encrypted = true
  }
}

# Step 2: Create read replica from MySQL to Aurora
# Use AWS DMS or native replication
```

### 2. On-Premises to RDS Migration
```bash
# Using AWS Database Migration Service (DMS)
# 1. Create replication instance
# 2. Create source and target endpoints
# 3. Create replication task
# 4. Monitor migration progress
```

### 3. Cross-Region Migration
```hcl
# Create cross-region read replica
rds_instances = {
  "migration-replica" = {
    replicate_source_db = "arn:aws:rds:source-region:account:db:source-instance"
    storage_encrypted = true
    kms_key_id = module.target_kms.key_arn
  }
}
```

## Integration Examples

### Application Configuration
```yaml
# Database configuration for applications
database:
  host: ${module.rds.rds_instance_endpoints["mysql-primary"]}
  port: 3306
  name: appdb
  ssl_mode: require
  
  # Use RDS Proxy for connection pooling
  proxy_endpoint: ${module.rds.rds_proxy_endpoints["mysql-proxy"]}
```

### Lambda Function Integration
```hcl
resource "aws_lambda_function" "db_function" {
  vpc_config {
    subnet_ids = var.private_subnet_ids
    security_group_ids = [
      module.security_groups.lambda_sg_id
    ]
  }
  
  environment {
    variables = {
      DB_HOST = module.rds.rds_instance_endpoints["mysql-primary"]
      DB_PORT = module.rds.rds_instance_ports["mysql-primary"]
    }
  }
}
```

### ECS Service Integration
```hcl
resource "aws_ecs_service" "app" {
  task_definition = aws_ecs_task_definition.app.arn
  
  # Environment variables for database connection
  # Passed through task definition
}

resource "aws_ecs_task_definition" "app" {
  container_definitions = jsonencode([
    {
      name = "app"
      environment = [
        {
          name = "DB_HOST"
          value = module.rds.rds_proxy_endpoints["mysql-proxy"]
        }
      ]
    }
  ])
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

### Development Guidelines

- Follow Terraform best practices
- Use meaningful variable names and descriptions
- Add comprehensive validation rules
- Include examples in documentation
- Test with multiple database engines
- Ensure backward compatibility

## License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for full details.

## Authors

- **Diego A. Zarate** - *Initial work* - [GitHub Profile](https://github.com/dzarate)

## Acknowledgments

- AWS RDS documentation and best practices
- Terraform AWS Provider documentation
- AWS Well-Architected Framework
- Community feedback and contributions

---

**Note**: This module follows semantic versioning. Please check the [CHANGELOG](CHANGELOG.md) for version-specific changes and migration guides.