# =============================================================================
# DATA LAYER - DEV ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "dev"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-dev"

# RDS Configuration
enable_rds = true
rds_engine = "mysql"
rds_engine_version = "8.0"
rds_instance_class = "db.t3.micro"
rds_allocated_storage = 20
rds_max_allocated_storage = 50
rds_database_name = "appdb"
rds_username = "admin"
rds_password = "change-me-in-production!"  # Use AWS Secrets Manager in production
rds_backup_retention_period = 1
rds_backup_window = "03:00-04:00"
rds_maintenance_window = "sun:04:00-sun:05:00"
rds_monitoring_interval = 0
enable_performance_insights = false

# ElastiCache Configuration
enable_elasticache = false
redis_node_type = "cache.t3.micro"
redis_num_nodes = 1
redis_parameter_group = "default.redis7"
redis_snapshot_retention_limit = 0
redis_snapshot_window = "03:00-05:00"

# DynamoDB Configuration
dynamodb_tables = {}

# S3 Configuration
s3_buckets = {
  app-data = {
    versioning_enabled = false
    public_read_access = false
    public_write_access = false
    lifecycle_configuration = {
      rules = [
        {
          id = "cleanup_dev_files"
          status = "Enabled"
          expiration = {
            days = 30
          }
        }
      ]
    }
  }
  app-logs = {
    versioning_enabled = false
    public_read_access = false
    public_write_access = false
    lifecycle_configuration = {
      rules = [
        {
          id = "cleanup_logs"
          status = "Enabled"
          expiration = {
            days = 7
          }
        }
      ]
    }
  }
}

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "dev"
  CostCenter  = "Engineering"
}
