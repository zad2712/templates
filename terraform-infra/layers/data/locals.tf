# =============================================================================
# DATA LAYER LOCALS
# =============================================================================

locals {
  # Common tags for all resources in this layer
  common_tags = merge(var.common_tags, {
    Layer       = "data"
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  })

  # Environment-specific data configurations
  env_data_config = {
    dev = {
      rds_instance_class    = "db.t3.micro"
      rds_multi_az         = false
      redis_node_type      = "cache.t3.micro"
      enable_backups       = false
      backup_retention_days = 1
    }
    qa = {
      rds_instance_class    = "db.t3.small"
      rds_multi_az         = false
      redis_node_type      = "cache.t3.small"
      enable_backups       = true
      backup_retention_days = 3
    }
    uat = {
      rds_instance_class    = "db.t3.medium"
      rds_multi_az         = true
      redis_node_type      = "cache.t3.medium"
      enable_backups       = true
      backup_retention_days = 7
    }
    prod = {
      rds_instance_class    = "db.t3.large"
      rds_multi_az         = true
      redis_node_type      = "cache.t3.large"
      enable_backups       = true
      backup_retention_days = 30
    }
  }

  # Current environment data configuration
  current_data_config = local.env_data_config[var.environment]
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
