# RDS Terraform Module

## Overview

This Terraform module creates **Amazon Relational Database Service (RDS)** instances with enterprise-grade features including automated backups, high availability, security, and performance optimization. The module supports multiple database engines and provides comprehensive configuration options for production workloads.

## Features

### 🗄️ **Database Engines Supported**
- **MySQL** - Latest versions with InnoDB storage engine
- **PostgreSQL** - Advanced open-source database with JSON support
- **MariaDB** - MySQL-compatible with enhanced features
- **Oracle** - Enterprise database with advanced features
- **SQL Server** - Microsoft SQL Server with Windows authentication
- **Aurora** - AWS-native database with MySQL/PostgreSQL compatibility

### 🔒 **Security Features**
- **Encryption at Rest**: AES-256 encryption with customer-managed KMS keys
- **Encryption in Transit**: SSL/TLS encryption for database connections
- **Network Isolation**: VPC deployment with private subnets
- **IAM Integration**: Database authentication with IAM roles
- **Parameter Groups**: Custom database configuration and security settings
- **Secrets Manager**: Automatic password rotation and secure storage

### 📈 **High Availability & Performance**
- **Multi-AZ Deployment**: Automatic failover for high availability
- **Read Replicas**: Scale read operations across multiple instances
- **Performance Insights**: Advanced database performance monitoring
- **Enhanced Monitoring**: Detailed CloudWatch metrics and logging
- **Automated Backups**: Point-in-time recovery with customizable retention

### 💰 **Cost Optimization**
- **Storage Autoscaling**: Automatically increase storage when needed
- **Reserved Instances**: Cost savings for predictable workloads
- **Instance Right-Sizing**: Performance-based instance recommendations
- **Storage Types**: Optimized storage options (gp2, gp3, io1, io2)

## Architecture

### 🏗️ **RDS Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                         VPC                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   App Subnet    │  │   App Subnet    │  │   App Subnet    │ │
│  │    (AZ-1)       │  │    (AZ-2)       │  │    (AZ-3)       │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │    App      │ │  │ │    App      │ │  │ │    App      │ │ │
│  │ │  Servers    │ │  │ │  Servers    │ │  │ │  Servers    │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                      │                      │      │
│           └──────────────────────┼──────────────────────┘      │
│                                  │                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   DB Subnet     │  │   DB Subnet     │  │   DB Subnet     │ │
│  │    (AZ-1)       │  │    (AZ-2)       │  │    (AZ-3)       │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │    RDS      │ │  │ │    RDS      │ │  │ │ Read Replica│ │ │
│  │ │  Primary    │◄─┼──┼►│  Standby    │ │  │ │             │ │ │
│  │ │             │ │  │ │  (Multi-AZ) │ │  │ │             │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Database Backup                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │  Automated  │  │   Manual    │  │    Point    │     │   │
│  │  │   Backup    │  │ Snapshots   │  │  in Time    │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 📊 **Multi-AZ vs Read Replicas**

#### **Multi-AZ Deployment**
- **Purpose**: High availability and automatic failover
- **Synchronization**: Synchronous replication to standby
- **Failover**: Automatic failover (1-2 minutes)
- **Use Case**: Production workloads requiring high availability

#### **Read Replicas**
- **Purpose**: Scale read operations and reduce primary load
- **Synchronization**: Asynchronous replication
- **Failover**: Manual promotion to primary
- **Use Case**: Read-heavy workloads and reporting

## Usage Examples

### Basic MySQL Database

```hcl
module "mysql_db" {
  source = "../../modules/rds"

  # Basic configuration
  db_instance_identifier = "my-mysql-db"
  engine                = "mysql"
  engine_version        = "8.0.35"
  instance_class        = "db.t3.micro"

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true

  # Database configuration
  db_name  = "myapp"
  username = "admin"

  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_groups.database_sg_id]

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Deletion protection
  deletion_protection = false  # Set to true for production

  tags = {
    Environment = "development"
    Project     = "my-app"
  }
}
```

### Production PostgreSQL with High Availability

```hcl
module "postgres_prod" {
  source = "../../modules/rds"

  # Production configuration
  db_instance_identifier = "prod-postgres-db"
  engine                = "postgres"
  engine_version        = "15.4"
  instance_class        = "db.r6g.xlarge"  # Performance optimized

  # High availability
  multi_az = true  # Enable Multi-AZ for automatic failover

  # Storage configuration
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type         = "gp3"
  storage_encrypted    = true
  kms_key_id           = module.kms.database_key_arn

  # Database configuration
  db_name  = "production_db"
  username = "postgres_admin"

  # Network and security
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_groups.database_sg_id]
  db_subnet_group_name   = "prod-db-subnet-group"

  # Backup and maintenance
  backup_retention_period   = 30  # 30 days for production
  backup_window            = "03:00-04:00"
  maintenance_window       = "sun:04:00-sun:06:00"
  copy_tags_to_snapshot    = true

  # Monitoring and performance
  monitoring_interval                 = 60
  monitoring_role_arn                = module.iam.rds_enhanced_monitoring_role_arn
  performance_insights_enabled       = true
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports    = ["postgresql"]

  # Security and compliance
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "prod-postgres-final-snapshot"

  # Parameter group for performance tuning
  parameter_group_name = aws_db_parameter_group.postgres_prod.name

  tags = {
    Environment = "production"
    Project     = "my-app"
    Backup      = "required"
    Compliance  = "SOC2"
  }
}

# Custom parameter group for PostgreSQL optimization
resource "aws_db_parameter_group" "postgres_prod" {
  family = "postgres15"
  name   = "prod-postgres-params"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
name  = "log_min_duration_statement"
    value = "1000"  # Log queries taking more than 1 second
  }

  tags = {
    Environment = "production"
  }
}
```

### MySQL with Read Replicas

```hcl
# Primary MySQL database
module "mysql_primary" {
  source = "../../modules/rds"

  db_instance_identifier = "mysql-primary"
  engine                = "mysql"
  engine_version        = "8.0.35"
  instance_class        = "db.r6g.large"

  # Enable automated backups (required for read replicas)
  backup_retention_period = 7
  
  # Other configuration...
  
  tags = {
    Role = "primary"
  }
}

# Read replica for scaling read operations
module "mysql_read_replica" {
  source = "../../modules/rds"

  create_db_instance     = true
  create_db_subnet_group = false  # Use existing subnet group

  db_instance_identifier = "mysql-read-replica"
  replicate_source_db    = module.mysql_primary.db_instance_id
  instance_class         = "db.r6g.large"

  # Read replica specific settings
  auto_minor_version_upgrade = false
  backup_retention_period   = 0  # Read replicas don't need backups

  # Can be in different AZ or region
  availability_zone = "us-east-1c"

  tags = {
    Role = "read-replica"
  }
}
```

### Development Database (Cost-Optimized)

```hcl
module "dev_database" {
  source = "../../modules/rds"

  # Minimal configuration for development
  db_instance_identifier = "dev-mysql-db"
  engine                = "mysql"
  engine_version        = "8.0.35"
  instance_class        = "db.t3.micro"  # Smallest instance

  # Minimal storage
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type         = "gp2"  # Standard SSD
  storage_encrypted    = false  # Optional for development

  # Database settings
  db_name  = "devdb"
  username = "dev_user"

  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_groups.database_sg_id]

  # Minimal backup (cost optimization)
  backup_retention_period = 1  # 1 day only
  backup_window          = "07:00-08:00"
  maintenance_window     = "sun:08:00-sun:09:00"

  # Development settings
  deletion_protection       = false
  skip_final_snapshot      = true
  apply_immediately        = true
  auto_minor_version_upgrade = true

  tags = {
    Environment = "development"
    CostOptimized = "true"
  }
}
```

### Oracle Enterprise Database

```hcl
module "oracle_enterprise" {
  source = "../../modules/rds"

  # Oracle configuration
  db_instance_identifier = "oracle-enterprise-db"
  engine                = "oracle-ee"
  engine_version        = "19.0.0.0.ru-2023-07.rur-2023-07.r1"
  instance_class        = "db.r5.2xlarge"  # Oracle requires larger instances

  # License model
  license_model = "bring-your-own-license"

  # Storage configuration
  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type         = "io1"  # Provisioned IOPS for Oracle
  iops                 = 3000
  storage_encrypted    = true

  # Database configuration
  db_name  = "ORCL"
  username = "oracle_admin"

  # Oracle-specific settings
  character_set_name       = "AL32UTF8"
  national_character_set_name = "AL16UTF16"
  timezone                = "UTC"

  # High availability
  multi_az = true

  # Network and security
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_groups.oracle_sg_id]

  # Backup configuration
  backup_retention_period = 35  # Extended retention for Oracle
  backup_window          = "03:00-05:00"
  maintenance_window     = "sun:05:00-sun:07:00"

  # Monitoring
  monitoring_interval = 60
  performance_insights_enabled = true

  # Security
  deletion_protection = true

  tags = {
    Environment = "production"
    Database    = "oracle"
    License     = "enterprise"
  }
}
```

### SQL Server with Windows Authentication

```hcl
module "sql_server" {
  source = "../../modules/rds"

  # SQL Server configuration
  db_instance_identifier = "sqlserver-prod"
  engine                = "sqlserver-ex"  # Express edition
  engine_version        = "15.00.4316.3.v1"
  instance_class        = "db.t3.small"

  # License model
  license_model = "license-included"

  # Storage
  allocated_storage = 20
  max_allocated_storage = 100
  storage_type     = "gp2"
  storage_encrypted = true

  # Database settings
  username = "sa"
  
  # SQL Server specific
  character_set_name = "SQL_Latin1_General_CP1_CI_AS"
  timezone          = "UTC"

  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_groups.sqlserver_sg_id]

  # Backup settings
  backup_retention_period = 7
  backup_window          = "04:00-05:00"
  maintenance_window     = "sun:05:00-sun:06:00"

  # Windows Authentication Domain (optional)
  domain               = "corp.example.com"
  domain_iam_role_name = "rds-directoryservice-role"

  tags = {
    Environment = "production"
    Database    = "sqlserver"
  }
}
```

## Configuration Options

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `db_instance_identifier` | `string` | Unique identifier for the DB instance |
| `engine` | `string` | Database engine (mysql, postgres, etc.) |
| `instance_class` | `string` | RDS instance class (db.t3.micro, etc.) |

### Database Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `engine_version` | `string` | `"8.0"` | Database engine version |
| `allocated_storage` | `number` | `20` | Initial storage allocation (GB) |
| `max_allocated_storage` | `number` | `100` | Maximum storage for autoscaling (GB) |
| `storage_type` | `string` | `"gp2"` | Storage type (gp2, gp3, io1, io2) |
| `storage_encrypted` | `bool` | `false` | Enable storage encryption |
| `db_name` | `string` | `null` | Initial database name |
| `username` | `string` | `"admin"` | Master username |

### High Availability

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `multi_az` | `bool` | `false` | Enable Multi-AZ deployment |
| `availability_zone` | `string` | `null` | Specific AZ for single-AZ deployment |
| `replicate_source_db` | `string` | `null` | Source DB for read replica |

### Backup & Maintenance

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `backup_retention_period` | `number` | `0` | Backup retention in days (0-35) |
| `backup_window` | `string` | `null` | Daily backup window (UTC) |
| `maintenance_window` | `string` | `null` | Weekly maintenance window |
| `copy_tags_to_snapshot` | `bool` | `false` | Copy tags to snapshots |

### Security

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_security_group_ids` | `list(string)` | `[]` | Security group IDs |
| `kms_key_id` | `string` | `null` | KMS key ID for encryption |
| `deletion_protection` | `bool` | `false` | Enable deletion protection |
| `publicly_accessible` | `bool` | `false` | Make DB publicly accessible |

### Monitoring

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `monitoring_interval` | `number` | `0` | Enhanced monitoring interval (0, 1, 5, 10, 15, 30, 60) |
| `monitoring_role_arn` | `string` | `null` | IAM role for enhanced monitoring |
| `performance_insights_enabled` | `bool` | `false` | Enable Performance Insights |
| `enabled_cloudwatch_logs_exports` | `list(string)` | `[]` | Log types to export to CloudWatch |

## Outputs

### Database Connection

| Output | Description |
|--------|-------------|
| `db_instance_id` | RDS instance identifier |
| `db_instance_arn` | RDS instance ARN |
| `db_instance_endpoint` | RDS instance connection endpoint |
| `db_instance_hosted_zone_id` | Route 53 hosted zone ID |
| `db_instance_port` | Database port number |

### Database Information

| Output | Description |
|--------|-------------|
| `db_instance_name` | Database name |
| `db_instance_username` | Master username |
| `db_instance_engine` | Database engine |
| `db_instance_engine_version` | Database engine version |
| `db_instance_class` | Database instance class |

### Network & Security

| Output | Description |
|--------|-------------|
| `db_subnet_group_id` | Database subnet group identifier |
| `db_subnet_group_arn` | Database subnet group ARN |
| `db_instance_availability_zone` | Availability zone of the instance |

## Best Practices

### 🔒 **Security Best Practices**

1. **Network Security**
   - Deploy RDS in private subnets only
   - Use security groups to restrict database access to application tiers
   - Enable VPC Flow Logs to monitor network traffic

2. **Encryption**
   - Enable encryption at rest for all production databases
   - Use customer-managed KMS keys for additional control
   - Enable encryption in transit with SSL/TLS certificates

3. **Access Control**
   - Use IAM database authentication where supported
   - Implement least-privilege access principles
   - Regularly rotate database passwords using Secrets Manager

4. **Monitoring & Auditing**
   - Enable database activity streams for audit compliance
   - Export database logs to CloudWatch for centralized monitoring
   - Set up CloudWatch alarms for critical metrics

### ⚡ **Performance Best Practices**

1. **Instance Sizing**
   - Monitor CPU, memory, and I/O utilization regularly
   - Use Performance Insights to identify performance bottlenecks
   - Right-size instances based on actual workload patterns

2. **Storage Optimization**
   - Use gp3 storage for better performance and cost efficiency
   - Enable storage autoscaling to handle growth automatically
   - Consider Provisioned IOPS (io1/io2) for I/O intensive workloads

3. **Connection Management**
   - Implement connection pooling in applications
   - Monitor database connections and configure appropriate limits
   - Use read replicas to distribute read workload

### 💰 **Cost Optimization**

1. **Instance Management**
   - **Development**: Use smaller instances (db.t3.micro, db.t3.small)
   - **Production**: Consider Reserved Instances for predictable workloads
   - **Staging**: Use Aurora Serverless for variable workloads

2. **Storage Optimization**
   - Enable storage autoscaling to avoid over-provisioning
   - Use gp3 storage for better price-performance ratio
   - Implement automated snapshot cleanup policies

3. **Backup Strategy**
   - Set appropriate backup retention periods (7-30 days typical)
   - Use cross-region backups only when required for compliance
   - Monitor backup storage costs and optimize retention policies

### 📈 **High Availability Best Practices**

1. **Multi-AZ Deployment**
   - Enable Multi-AZ for production databases
   - Test failover procedures regularly
   - Monitor failover metrics and RTO/RPO

2. **Read Replicas**
   - Use read replicas to scale read operations
   - Place read replicas in different AZs or regions
   - Monitor replication lag and performance

3. **Backup & Recovery**
   - Test backup restoration procedures regularly
   - Implement point-in-time recovery for critical databases
   - Document recovery procedures and RTO/RPO requirements

## Integration Examples

### Application Integration

```python
# Python application connection example
import pymysql
import boto3
from botocore.exceptions import ClientError

def get_secret_value(secret_name, region_name="us-east-1"):
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e
    
    return get_secret_value_response['SecretString']

def connect_to_rds():
    # Get database credentials from Secrets Manager
    secret = json.loads(get_secret_value("prod/mysql/credentials"))
    
    connection = pymysql.connect(
        host=secret['host'],
        user=secret['username'],
        password=secret['password'],
        database=secret['dbname'],
        port=secret['port'],
        ssl={'ssl_ca': '/opt/rds-ca-2019-root.pem'},
        ssl_verify_cert=True,
        ssl_verify_identity=True
    )
    
    return connection
```

### Backup Automation

```hcl
# Lambda function for automated snapshots
resource "aws_lambda_function" "db_snapshot" {
  filename         = "db_snapshot.zip"
  function_name    = "rds-automated-snapshot"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"

  environment {
    variables = {
      DB_INSTANCE_ID = module.mysql_db.db_instance_id
    }
  }
}

# CloudWatch Event Rule for daily snapshots
resource "aws_cloudwatch_event_rule" "daily_snapshot" {
  name                = "daily-db-snapshot"
  description         = "Trigger daily RDS snapshot"
  schedule_expression = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_snapshot.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.db_snapshot.arn
}
```

### Monitoring Setup

```hcl
# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = module.mysql_db.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS connection count"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = module.mysql_db.db_instance_id
  }
}
```

## Troubleshooting

### Common Issues

#### **Connection Problems**
```bash
# Test database connectivity
mysql -h mydb.cluster-xyz.us-east-1.rds.amazonaws.com -u admin -p

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxx

# Verify subnet group configuration
aws rds describe-db-subnet-groups --db-subnet-group-name mydb-subnet-group
```

#### **Performance Issues**
```bash
# Check Performance Insights
aws rds describe-db-instances --db-instance-identifier mydb

# Monitor key metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=mydb \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

#### **Backup and Recovery**
```bash
# List available snapshots
aws rds describe-db-snapshots --db-instance-identifier mydb

# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier mydb \
  --db-snapshot-identifier mydb-manual-snapshot-$(date +%Y%m%d)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier mydb-restored \
  --db-snapshot-identifier mydb-snapshot-20240101
```

## Requirements

- **Terraform**: >= 1.6.0
- **AWS Provider**: ~> 5.70
- **Minimum Permissions**: RDS management, VPC access, KMS (if using encryption)

## Related Documentation

- [Amazon RDS User Guide](https://docs.aws.amazon.com/rds/latest/userguide/)
- [RDS Performance Best Practices](https://docs.aws.amazon.com/rds/latest/userguide/CHAP_BestPractices.html)
- [RDS Security Best Practices](https://docs.aws.amazon.com/rds/latest/userguide/CHAP_BestPractices.Security.html)
- [Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)

---

> 🗄️ **Database Excellence**: This RDS module provides enterprise-grade database infrastructure with high availability, security, performance optimization, and comprehensive monitoring built-in.