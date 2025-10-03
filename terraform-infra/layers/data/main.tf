# =============================================================================
# DATA LAYER - RDS, ElastiCache, DynamoDB, S3, and Data Services
# =============================================================================

terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  backend "s3" {}
}

# =============================================================================
# DATA SOURCES - Import other layers outputs
# =============================================================================

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "networking/${var.environment}/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "security/${var.environment}/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}

# =============================================================================
# RDS DATABASE
# =============================================================================

module "rds" {
  count  = var.enable_rds ? 1 : 0
  source = "../../modules/rds"

  identifier = "${var.project_name}-${var.environment}"

  # Database configuration
  engine         = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class
  
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_encrypted     = true
  kms_key_id           = data.terraform_remote_state.security.outputs.kms_keys["rds"].arn

  # Database credentials
  db_name  = var.rds_database_name
  username = var.rds_username
  password = var.rds_password

  # Network configuration
  vpc_security_group_ids = [
    data.terraform_remote_state.security.outputs.security_group_ids["rds"]
  ]
  
  db_subnet_group_name = module.rds_subnet_group.name

  # Backup configuration
  backup_retention_period = var.rds_backup_retention_period
  backup_window          = var.rds_backup_window
  maintenance_window     = var.rds_maintenance_window

  # Multi-AZ deployment for production
  multi_az = var.environment == "prod" ? true : false

  # Monitoring
  monitoring_interval = var.rds_monitoring_interval
  monitoring_role_arn = data.terraform_remote_state.security.outputs.service_roles["rds-monitoring"].arn

  # Performance Insights
  performance_insights_enabled = var.enable_performance_insights

  tags = local.common_tags
}

# RDS Subnet Group
module "rds_subnet_group" {
  count  = var.enable_rds ? 1 : 0
  source = "../../modules/rds-subnet-group"

  name       = "${var.project_name}-${var.environment}-rds"
  subnet_ids = data.terraform_remote_state.networking.outputs.database_subnets

  tags = local.common_tags
}

# =============================================================================
# ELASTICACHE REDIS
# =============================================================================

module "elasticache_redis" {
  count  = var.enable_elasticache ? 1 : 0
  source = "../../modules/elasticache"

  cluster_id = "${var.project_name}-${var.environment}-redis"

  # Redis configuration
  engine         = "redis"
  node_type      = var.redis_node_type
  num_cache_nodes = var.redis_num_nodes
  parameter_group_name = var.redis_parameter_group

  # Network configuration
  subnet_group_name = module.elasticache_subnet_group[0].name
  security_group_ids = [
    data.terraform_remote_state.security.outputs.security_group_ids["redis"]
  ]

  # Backup configuration
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  snapshot_window         = var.redis_snapshot_window

  # Multi-AZ
  multi_az_enabled = var.environment == "prod" ? true : false

  tags = local.common_tags
}

# ElastiCache Subnet Group
module "elasticache_subnet_group" {
  count  = var.enable_elasticache ? 1 : 0
  source = "../../modules/elasticache-subnet-group"

  name       = "${var.project_name}-${var.environment}-elasticache"
  subnet_ids = data.terraform_remote_state.networking.outputs.private_subnets

  tags = local.common_tags
}

# =============================================================================
# DYNAMODB TABLES
# =============================================================================

module "dynamodb" {
  count  = length(var.dynamodb_tables) > 0 ? 1 : 0
  source = "../../modules/dynamodb"

  tables = var.dynamodb_tables

  # KMS encryption
  server_side_encryption = {
    enabled     = true
    kms_key_arn = data.terraform_remote_state.security.outputs.kms_keys["general"].arn
  }

  # Point-in-time recovery for production
  point_in_time_recovery_enabled = var.environment == "prod" ? true : false

  tags = local.common_tags
}

# =============================================================================
# S3 BUCKETS
# =============================================================================

module "s3_buckets" {
  count  = length(var.s3_buckets) > 0 ? 1 : 0
  source = "../../modules/s3"

  buckets = var.s3_buckets

  # Default encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.terraform_remote_state.security.outputs.kms_keys["s3"].arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # Versioning for production buckets
  versioning_enabled = var.environment == "prod" ? true : false

  tags = local.common_tags
}
