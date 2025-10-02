# =============================================================================
# DATA LAYER - UAT ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "uat"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-uat"

# RDS Configuration
enable_rds = true
rds_engine = "mysql"
rds_engine_version = "8.0"
rds_instance_class = "db.t3.medium"
rds_allocated_storage = 50
rds_max_allocated_storage = 200
rds_database_name = "appdb"
rds_username = "admin"
rds_password = "change-me-in-production!"  # Use AWS Secrets Manager in production
rds_backup_retention_period = 7
rds_backup_window = "03:00-04:00"
rds_maintenance_window = "sun:04:00-sun:05:00"
rds_monitoring_interval = 60
enable_performance_insights = true

# ElastiCache Configuration
enable_elasticache = true
redis_node_type = "cache.t3.medium"
redis_num_nodes = 2
redis_parameter_group = "default.redis7"
redis_snapshot_retention_limit = 7
redis_snapshot_window = "03:00-05:00"

# DynamoDB Configuration
dynamodb_tables = {
  sessions = {
    hash_key = "session_id"
    attributes = [
      {
        name = "session_id"
        type = "S"
      }
    ]
    ttl = {
      attribute_name = "expires_at"
      enabled        = true
    }
  }
  user_profiles = {
    hash_key = "user_id"
    range_key = "profile_type"
    attributes = [
      {
        name = "user_id"
        type = "S"
      },
      {
        name = "profile_type"
        type = "S"
      }
    ]
  }
}

# S3 Configuration
s3_buckets = {
  app-data = {
    versioning_enabled = true
    public_read_access = false
    public_write_access = false
    lifecycle_configuration = {
      rules = [
        {
          id = "intelligent_tiering"
          status = "Enabled"
          transition = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            },
            {
              days          = 90
              storage_class = "GLACIER"
            }
          ]
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
            days = 90
          }
        }
      ]
    }
  }
  app-backups = {
    versioning_enabled = true
    public_read_access = false
    public_write_access = false
  }
}

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "uat"
  CostCenter  = "Engineering"
}
