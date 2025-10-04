# =============================================================================
# DATA LAYER - RDS, DynamoDB, S3, ElastiCache, and Data Services
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

# Configure AWS Provider
provider "aws" {
  # Provider configuration will be set by environment-specific backend configuration
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Layer       = "data"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Data from other layers
  networking_outputs = data.terraform_remote_state.networking.outputs
  security_outputs   = data.terraform_remote_state.security.outputs
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Current AWS region and account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Networking layer outputs
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}"
    key    = "networking/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

# Security layer outputs
data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}"
    key    = "security/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

# =============================================================================
# S3 MODULE
# =============================================================================

module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix

  # S3 Buckets
  buckets = {
    # Application data bucket
    application_data = {
      versioning = {
        enabled = true
        mfa_delete = false
      }
      
      lifecycle_configuration = {
        rules = [
          {
            id     = "transition_to_ia"
            status = "Enabled"
            
            transitions = [
              {
                days          = 30
                storage_class = "STANDARD_IA"
              },
              {
                days          = 90
                storage_class = "GLACIER"
              },
              {
                days          = 365
                storage_class = "DEEP_ARCHIVE"
              }
            ]
          },
          {
            id     = "delete_old_versions"
            status = "Enabled"
            
            noncurrent_version_expiration = {
              noncurrent_days = 90
            }
          }
        ]
      }
      
      server_side_encryption_configuration = {
        rule = {
          apply_server_side_encryption_by_default = {
            kms_master_key_id = local.security_outputs.kms_key_ids["s3"]
            sse_algorithm     = "aws:kms"
          }
          bucket_key_enabled = true
        }
      }
      
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      
      logging = {
        target_bucket = "access-logs"
        target_prefix = "application-data/"
      }
    }

    # Static website/assets bucket
    static_assets = {
      versioning = {
        enabled = true
      }
      
      lifecycle_configuration = {
        rules = [
          {
            id     = "optimize_storage"
            status = "Enabled"
            
            transitions = [
              {
                days          = 30
                storage_class = "STANDARD_IA"
              }
            ]
          }
        ]
      }
      
      server_side_encryption_configuration = {
        rule = {
          apply_server_side_encryption_by_default = {
            kms_master_key_id = local.security_outputs.kms_key_ids["s3"]
            sse_algorithm     = "aws:kms"
          }
          bucket_key_enabled = true
        }
      }
      
      cors_configuration = {
        cors_rules = [
          {
            allowed_headers = ["*"]
            allowed_methods = ["GET", "HEAD"]
            allowed_origins = ["*"]
            expose_headers  = ["ETag"]
            max_age_seconds = 3000
          }
        ]
      }
      
      website_configuration = {
        index_document = {
          suffix = "index.html"
        }
        error_document = {
          key = "error.html"
        }
      }
    }

    # Backup bucket
    backups = {
      versioning = {
        enabled = true
      }
      
      lifecycle_configuration = {
        rules = [
          {
            id     = "backup_lifecycle"
            status = "Enabled"
            
            transitions = [
              {
                days          = 1
                storage_class = "GLACIER"
              },
              {
                days          = 30
                storage_class = "DEEP_ARCHIVE"
              }
            ]
            
            expiration = {
              days = var.backup_retention_days
            }
          }
        ]
      }
      
      server_side_encryption_configuration = {
        rule = {
          apply_server_side_encryption_by_default = {
            kms_master_key_id = local.security_outputs.kms_key_ids["s3"]
            sse_algorithm     = "aws:kms"
          }
          bucket_key_enabled = true
        }
      }
      
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    }

    # Access logs bucket
    access_logs = {
      server_side_encryption_configuration = {
        rule = {
          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      
      lifecycle_configuration = {
        rules = [
          {
            id     = "log_lifecycle"
            status = "Enabled"
            
            transitions = [
              {
                days          = 30
                storage_class = "STANDARD_IA"
              },
              {
                days          = 90
                storage_class = "GLACIER"
              }
            ]
            
            expiration = {
              days = var.log_retention_days
            }
          }
        ]
      }
      
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    }
  }

  # Cross-region replication
  replication_configuration = var.enable_cross_region_replication ? {
    application_data = {
      role_arn = module.iam_replication_role.arn
      
      rules = [
        {
          id     = "replicate_to_backup_region"
          status = "Enabled"
          
          destination = {
            bucket        = "arn:aws:s3:::${local.name_prefix}-application-data-replica"
            storage_class = "STANDARD_IA"
            
            encryption_configuration = {
              replica_kms_key_id = "arn:aws:kms:${var.backup_region}:${data.aws_caller_identity.current.account_id}:alias/${local.name_prefix}-s3"
            }
          }
        }
      ]
    }
  } : {}

  tags = local.common_tags
}

# =============================================================================
# RDS MODULE
# =============================================================================

module "rds" {
  source = "../../modules/rds"

  name_prefix = local.name_prefix

  # RDS Instances
  db_instances = var.rds_instances

  # RDS Clusters (Aurora)
  db_clusters = var.rds_clusters

  # Database subnet group
  db_subnet_group_name   = "${local.name_prefix}-db-subnet-group"
  db_subnet_group_subnet_ids = local.networking_outputs.database_subnet_ids

  # Security
  vpc_security_group_ids = [local.networking_outputs.security_group_ids["rds"]]
  kms_key_id            = local.security_outputs.kms_key_ids["rds"]

  # Secrets Manager integration
  manage_master_user_password = true
  master_user_secret_kms_key_id = local.security_outputs.kms_key_ids["secrets"]

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = local.security_outputs.iam_role_arns["rds_monitoring"]
  enabled_cloudwatch_logs_exports = var.rds_cloudwatch_logs_exports

  # Backup
  backup_retention_period = var.rds_backup_retention_period
  backup_window          = var.rds_backup_window
  maintenance_window     = var.rds_maintenance_window
  
  copy_tags_to_snapshot = true
  delete_automated_backups = false
  deletion_protection = var.environment == "prod" ? true : false

  # Parameter groups
  parameter_groups = var.rds_parameter_groups

  # Option groups  
  option_groups = var.rds_option_groups

  tags = local.common_tags
}

# =============================================================================
# DYNAMODB MODULE
# =============================================================================

module "dynamodb" {
  source = "../../modules/dynamodb"

  name_prefix = local.name_prefix

  # DynamoDB Tables
  tables = var.dynamodb_tables

  # Global Tables
  global_tables = var.dynamodb_global_tables

  # Backup configuration
  enable_backup_vault = var.enable_dynamodb_backup
  backup_vault_kms_key_arn = local.security_outputs.kms_key_arns["application"]
  
  backup_plan_rules = var.dynamodb_backup_rules

  # Stream processing
  stream_processor_functions = var.dynamodb_stream_processors

  # Monitoring
  enable_cloudwatch_alarms = var.enable_cloudwatch_alarms
  alarm_actions = [local.security_outputs.sns_topic_arns["alerts"]]
  
  enable_contributor_insights = var.environment == "prod" ? true : false

  tags = local.common_tags
}

# =============================================================================
# ELASTICACHE MODULE
# =============================================================================

module "elasticache" {
  source = "../../modules/elasticache"

  name_prefix = local.name_prefix

  # Subnet Groups
  subnet_groups = {
    default = {
      subnet_ids = local.networking_outputs.elasticache_subnet_ids
      description = "Default ElastiCache subnet group"
    }
  }

  # Parameter Groups
  parameter_groups = var.elasticache_parameter_groups

  # Redis Clusters
  redis_clusters = var.elasticache_redis_clusters

  # Memcached Clusters  
  memcached_clusters = var.elasticache_memcached_clusters

  # Redis Users and User Groups (RBAC)
  redis_users = var.elasticache_redis_users
  redis_user_groups = var.elasticache_redis_user_groups

  # Global Replication Groups
  global_replication_groups = var.elasticache_global_replication_groups

  # Monitoring
  enable_cloudwatch_alarms = var.enable_cloudwatch_alarms
  alarm_actions = [local.security_outputs.sns_topic_arns["alerts"]]

  # SNS notifications
  create_sns_topic = false  # Use the one from security layer

  tags = local.common_tags
}

# =============================================================================
# DATA PROCESSING SERVICES
# =============================================================================

# Kinesis Data Streams (if needed)
resource "aws_kinesis_stream" "data_stream" {
  for_each = var.kinesis_streams

  name             = "${local.name_prefix}-${each.key}-stream"
  shard_count      = each.value.shard_count
  retention_period = each.value.retention_period

  shard_level_metrics = each.value.shard_level_metrics

  encryption_type = "KMS"
  kms_key_id      = local.security_outputs.kms_key_ids["application"]

  stream_mode_details {
    stream_mode = each.value.stream_mode
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-stream"
  })
}

# Kinesis Data Firehose (if needed)
resource "aws_kinesis_firehose_delivery_stream" "data_firehose" {
  for_each = var.kinesis_firehose_streams

  name        = "${local.name_prefix}-${each.key}-firehose"
  destination = each.value.destination

  dynamic "s3_configuration" {
    for_each = each.value.destination == "s3" ? [each.value.s3_configuration] : []
    content {
      role_arn   = aws_iam_role.firehose_delivery_role[each.key].arn
      bucket_arn = module.s3.bucket_arns[s3_configuration.value.bucket_key]
      prefix     = s3_configuration.value.prefix

      buffer_size     = s3_configuration.value.buffer_size
      buffer_interval = s3_configuration.value.buffer_interval

      compression_format = s3_configuration.value.compression_format

      kms_key_arn = local.security_outputs.kms_key_arns["s3"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-firehose"
  })
}

# IAM role for Kinesis Data Firehose
resource "aws_iam_role" "firehose_delivery_role" {
  for_each = var.kinesis_firehose_streams

  name = "${local.name_prefix}-${each.key}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "firehose_delivery_policy" {
  for_each = var.kinesis_firehose_streams

  name = "${local.name_prefix}-${each.key}-firehose-policy"
  role = aws_iam_role.firehose_delivery_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          module.s3.bucket_arns[each.value.s3_configuration.bucket_key],
          "${module.s3.bucket_arns[each.value.s3_configuration.bucket_key]}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          local.security_outputs.kms_key_arns["s3"]
        ]
      }
    ]
  })
}

# =============================================================================
# BACKUP AND DISASTER RECOVERY
# =============================================================================

# AWS Backup Vault
resource "aws_backup_vault" "data_backup_vault" {
  count = var.enable_aws_backup ? 1 : 0

  name        = "${local.name_prefix}-data-backup-vault"
  kms_key_arn = local.security_outputs.kms_key_arns["application"]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-data-backup-vault"
  })
}

# AWS Backup Plan
resource "aws_backup_plan" "data_backup_plan" {
  count = var.enable_aws_backup ? 1 : 0

  name = "${local.name_prefix}-data-backup-plan"

  dynamic "rule" {
    for_each = var.backup_rules
    content {
      rule_name         = rule.value.rule_name
      target_vault_name = aws_backup_vault.data_backup_vault[0].name
      schedule          = rule.value.schedule

      start_window      = rule.value.start_window
      completion_window = rule.value.completion_window

      dynamic "lifecycle" {
        for_each = rule.value.lifecycle != null ? [rule.value.lifecycle] : []
        content {
          cold_storage_after = lifecycle.value.cold_storage_after
          delete_after      = lifecycle.value.delete_after
        }
      }

      dynamic "copy_action" {
        for_each = rule.value.copy_actions
        content {
          destination_vault_arn = copy_action.value.destination_vault_arn

          dynamic "lifecycle" {
            for_each = copy_action.value.lifecycle != null ? [copy_action.value.lifecycle] : []
            content {
              cold_storage_after = lifecycle.value.cold_storage_after
              delete_after      = lifecycle.value.delete_after
            }
          }
        }
      }

      recovery_point_tags = rule.value.recovery_point_tags
    }
  }

  tags = local.common_tags
}

# AWS Backup Selection
resource "aws_backup_selection" "data_backup_selection" {
  count = var.enable_aws_backup ? 1 : 0

  iam_role_arn = aws_iam_role.backup_role[0].arn
  name         = "${local.name_prefix}-data-backup-selection"
  plan_id      = aws_backup_plan.data_backup_plan[0].id

  # RDS resources
  dynamic "resources" {
    for_each = module.rds.db_instance_arns
    content {
      arn = resources.value
    }
  }

  dynamic "resources" {
    for_each = module.rds.db_cluster_arns
    content {
      arn = resources.value
    }
  }

  # DynamoDB resources are handled by the DynamoDB module

  # Conditional selection based on tags
  dynamic "condition" {
    for_each = var.backup_selection_conditions
    content {
      string_equals = condition.value.string_equals
      string_like   = condition.value.string_like
    }
  }
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup_role" {
  count = var.enable_aws_backup ? 1 : 0

  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  count = var.enable_aws_backup ? 1 : 0

  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  count = var.enable_aws_backup ? 1 : 0

  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}