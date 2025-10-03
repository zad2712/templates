# =============================================================================
# RDS MODULE
# =============================================================================

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

# =============================================================================
# RDS SUBNET GROUP
# =============================================================================

resource "aws_db_subnet_group" "main" {
  count = var.create_db_subnet_group ? 1 : 0
  
  name       = var.db_subnet_group_name
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = var.db_subnet_group_name
  })
}

# =============================================================================
# RDS INSTANCE
# =============================================================================

resource "aws_db_instance" "main" {
  count = var.create_db_instance ? 1 : 0

  identifier = var.db_instance_identifier
  
  # Engine settings
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  
  # Database settings
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id          = var.kms_key_id
  
  # Database credentials
  db_name  = var.db_name
  username = var.username
  password = var.password
  
  # Network settings
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.main[0].name : var.db_subnet_group_name
  
  # Backup settings
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn
  
  # Other settings
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection
  
  tags = var.tags
}
