# RDS Module - Main Configuration
# Author: Diego A. Zarate

terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Locals for resource naming and configuration
locals {
  # Common tags
  common_tags = merge(var.tags, {
    Module      = "rds"
    Terraform   = "true"
    Environment = var.tags.Environment
    ManagedBy   = "terraform"
  })

  # DB Subnet Group configuration
  db_subnet_groups = {
    for group_name, group_config in var.db_subnet_groups : group_name => {
      name        = "${var.name_prefix}-${group_name}-db-subnet-group"
      subnet_ids  = group_config.subnet_ids
      description = group_config.description
      tags = merge(local.common_tags, group_config.tags, {
        Name = "${var.name_prefix}-${group_name}-db-subnet-group"
        Type = "db-subnet-group"
      })
    }
  }

  # DB Parameter Groups configuration
  db_parameter_groups = {
    for group_name, group_config in var.db_parameter_groups : group_name => {
      name        = "${var.name_prefix}-${group_name}"
      family      = group_config.family
      description = group_config.description
      parameters  = group_config.parameters
      tags = merge(local.common_tags, group_config.tags, {
        Name   = "${var.name_prefix}-${group_name}"
        Type   = "db-parameter-group"
        Family = group_config.family
      })
    }
  }

  # DB Option Groups configuration
  db_option_groups = {
    for group_name, group_config in var.db_option_groups : group_name => {
      name                     = "${var.name_prefix}-${group_name}"
      option_group_description = group_config.description
      engine_name             = group_config.engine_name
      major_engine_version    = group_config.major_engine_version
      options                 = group_config.options
      tags = merge(local.common_tags, group_config.tags, {
        Name    = "${var.name_prefix}-${group_name}"
        Type    = "db-option-group"
        Engine  = group_config.engine_name
        Version = group_config.major_engine_version
      })
    }
  }

  # RDS Instances configuration
  rds_instances = {
    for instance_name, instance_config in var.rds_instances : instance_name => {
      # Basic Configuration
      identifier             = "${var.name_prefix}-${instance_name}"
      allocated_storage     = instance_config.allocated_storage
      max_allocated_storage = instance_config.max_allocated_storage
      storage_type          = instance_config.storage_type
      storage_encrypted     = instance_config.storage_encrypted
      kms_key_id           = instance_config.kms_key_id
      iops                 = instance_config.iops
      storage_throughput   = instance_config.storage_throughput

      # Engine Configuration
      engine                = instance_config.engine
      engine_version        = instance_config.engine_version
      instance_class        = instance_config.instance_class
      db_name              = instance_config.db_name
      username             = instance_config.username
      password             = instance_config.password
      manage_master_user_password = instance_config.manage_master_user_password

      # Network Configuration
      db_subnet_group_name   = instance_config.db_subnet_group_name != null ? aws_db_subnet_group.this[instance_config.db_subnet_group_name].name : null
      vpc_security_group_ids = instance_config.vpc_security_group_ids
      publicly_accessible    = instance_config.publicly_accessible
      port                   = instance_config.port

      # High Availability
      multi_az               = instance_config.multi_az
      availability_zone      = instance_config.availability_zone

      # Parameter and Option Groups
      parameter_group_name = instance_config.parameter_group_name != null ? aws_db_parameter_group.this[instance_config.parameter_group_name].name : null
      option_group_name    = instance_config.option_group_name != null ? aws_db_option_group.this[instance_config.option_group_name].name : null

      # Backup Configuration
      backup_retention_period = instance_config.backup_retention_period
      backup_window          = instance_config.backup_window
      delete_automated_backups = instance_config.delete_automated_backups
      copy_tags_to_snapshot   = instance_config.copy_tags_to_snapshot
      final_snapshot_identifier = instance_config.final_snapshot_identifier
      skip_final_snapshot    = instance_config.skip_final_snapshot

      # Maintenance
      maintenance_window         = instance_config.maintenance_window
      auto_minor_version_upgrade = instance_config.auto_minor_version_upgrade
      allow_major_version_upgrade = instance_config.allow_major_version_upgrade

      # Monitoring
      monitoring_interval = instance_config.monitoring_interval
      monitoring_role_arn = instance_config.monitoring_role_arn
      enabled_cloudwatch_logs_exports = instance_config.enabled_cloudwatch_logs_exports
      performance_insights_enabled = instance_config.performance_insights_enabled
      performance_insights_retention_period = instance_config.performance_insights_retention_period

      # Security
      deletion_protection = instance_config.deletion_protection
      
      # Lifecycle
      apply_immediately = instance_config.apply_immediately
      
      tags = merge(local.common_tags, instance_config.tags, {
        Name    = "${var.name_prefix}-${instance_name}"
        Type    = "rds-instance"
        Engine  = instance_config.engine
        Class   = instance_config.instance_class
        MultiAZ = tostring(instance_config.multi_az)
      })
    }
  }

  # RDS Clusters configuration (for Aurora)
  rds_clusters = {
    for cluster_name, cluster_config in var.rds_clusters : cluster_name => {
      # Basic Configuration
      cluster_identifier      = "${var.name_prefix}-${cluster_name}"
      engine                 = cluster_config.engine
      engine_version         = cluster_config.engine_version
      engine_mode           = cluster_config.engine_mode
      database_name         = cluster_config.database_name
      master_username       = cluster_config.master_username
      master_password       = cluster_config.master_password
      manage_master_user_password = cluster_config.manage_master_user_password

      # Network Configuration
      db_subnet_group_name   = cluster_config.db_subnet_group_name != null ? aws_db_subnet_group.this[cluster_config.db_subnet_group_name].name : null
      vpc_security_group_ids = cluster_config.vpc_security_group_ids
      port                   = cluster_config.port
      availability_zones     = cluster_config.availability_zones

      # Parameter Group
      db_cluster_parameter_group_name = cluster_config.db_cluster_parameter_group_name != null ? aws_rds_cluster_parameter_group.this[cluster_config.db_cluster_parameter_group_name].name : null

      # Backup Configuration
      backup_retention_period = cluster_config.backup_retention_period
      preferred_backup_window = cluster_config.preferred_backup_window
      copy_tags_to_snapshot   = cluster_config.copy_tags_to_snapshot
      final_snapshot_identifier = cluster_config.final_snapshot_identifier
      skip_final_snapshot    = cluster_config.skip_final_snapshot

      # Maintenance
      preferred_maintenance_window = cluster_config.preferred_maintenance_window

      # Storage
      storage_encrypted = cluster_config.storage_encrypted
      kms_key_id       = cluster_config.kms_key_id
      storage_type     = cluster_config.storage_type
      allocated_storage = cluster_config.allocated_storage
      iops            = cluster_config.iops

      # Monitoring
      enabled_cloudwatch_logs_exports = cluster_config.enabled_cloudwatch_logs_exports

      # Security and Lifecycle
      deletion_protection = cluster_config.deletion_protection
      apply_immediately  = cluster_config.apply_immediately

      # Serverless Configuration
      scaling_configuration = cluster_config.scaling_configuration

      tags = merge(local.common_tags, cluster_config.tags, {
        Name   = "${var.name_prefix}-${cluster_name}"
        Type   = "rds-cluster"
        Engine = cluster_config.engine
        Mode   = cluster_config.engine_mode
      })
    }
  }

  # RDS Cluster Instances configuration
  rds_cluster_instances = {
    for instance_name, instance_config in var.rds_cluster_instances : instance_name => {
      identifier         = "${var.name_prefix}-${instance_name}"
      cluster_identifier = aws_rds_cluster.this[instance_config.cluster_identifier].id
      instance_class     = instance_config.instance_class
      engine            = instance_config.engine
      engine_version    = instance_config.engine_version

      # Monitoring
      monitoring_interval = instance_config.monitoring_interval
      monitoring_role_arn = instance_config.monitoring_role_arn
      performance_insights_enabled = instance_config.performance_insights_enabled

      # Maintenance
      auto_minor_version_upgrade = instance_config.auto_minor_version_upgrade
      preferred_maintenance_window = instance_config.preferred_maintenance_window

      # Security
      publicly_accessible = instance_config.publicly_accessible
      
      # Lifecycle
      apply_immediately = instance_config.apply_immediately

      tags = merge(local.common_tags, instance_config.tags, {
        Name    = "${var.name_prefix}-${instance_name}"
        Type    = "rds-cluster-instance"
        Cluster = instance_config.cluster_identifier
        Engine  = instance_config.engine
        Class   = instance_config.instance_class
      })
    }
  }
}

# DB Subnet Groups
resource "aws_db_subnet_group" "this" {
  for_each = local.db_subnet_groups

  name        = each.value.name
  subnet_ids  = each.value.subnet_ids
  description = each.value.description
  tags        = each.value.tags

  lifecycle {
    create_before_destroy = true
  }
}

# DB Parameter Groups
resource "aws_db_parameter_group" "this" {
  for_each = local.db_parameter_groups

  name        = each.value.name
  family      = each.value.family
  description = each.value.description
  tags        = each.value.tags

  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DB Option Groups
resource "aws_db_option_group" "this" {
  for_each = local.db_option_groups

  name                     = each.value.name
  option_group_description = each.value.option_group_description
  engine_name             = each.value.engine_name
  major_engine_version    = each.value.major_engine_version
  tags                    = each.value.tags

  dynamic "option" {
    for_each = each.value.options
    content {
      option_name                    = option.value.option_name
      port                          = option.value.port
      version                       = option.value.version
      db_security_group_memberships = option.value.db_security_group_memberships
      vpc_security_group_memberships = option.value.vpc_security_group_memberships

      dynamic "option_settings" {
        for_each = option.value.option_settings
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Cluster Parameter Groups (for Aurora)
resource "aws_rds_cluster_parameter_group" "this" {
  for_each = var.rds_cluster_parameter_groups

  name        = "${var.name_prefix}-${each.key}"
  family      = each.value.family
  description = each.value.description
  tags = merge(local.common_tags, each.value.tags, {
    Name   = "${var.name_prefix}-${each.key}"
    Type   = "rds-cluster-parameter-group"
    Family = each.value.family
  })

  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instances
resource "aws_db_instance" "this" {
  for_each = local.rds_instances

  # Basic Configuration
  identifier             = each.value.identifier
  allocated_storage     = each.value.allocated_storage
  max_allocated_storage = each.value.max_allocated_storage
  storage_type          = each.value.storage_type
  storage_encrypted     = each.value.storage_encrypted
  kms_key_id           = each.value.kms_key_id
  iops                 = each.value.iops
  storage_throughput   = each.value.storage_throughput

  # Engine Configuration
  engine         = each.value.engine
  engine_version = each.value.engine_version
  instance_class = each.value.instance_class
  db_name       = each.value.db_name
  username      = each.value.username
  password      = each.value.password
  manage_master_user_password = each.value.manage_master_user_password

  # Network Configuration
  db_subnet_group_name   = each.value.db_subnet_group_name
  vpc_security_group_ids = each.value.vpc_security_group_ids
  publicly_accessible    = each.value.publicly_accessible
  port                   = each.value.port

  # High Availability
  multi_az          = each.value.multi_az
  availability_zone = each.value.availability_zone

  # Parameter and Option Groups
  parameter_group_name = each.value.parameter_group_name
  option_group_name    = each.value.option_group_name

  # Backup Configuration
  backup_retention_period = each.value.backup_retention_period
  backup_window          = each.value.backup_window
  delete_automated_backups = each.value.delete_automated_backups
  copy_tags_to_snapshot   = each.value.copy_tags_to_snapshot
  final_snapshot_identifier = each.value.final_snapshot_identifier
  skip_final_snapshot    = each.value.skip_final_snapshot

  # Maintenance
  maintenance_window         = each.value.maintenance_window
  auto_minor_version_upgrade = each.value.auto_minor_version_upgrade
  allow_major_version_upgrade = each.value.allow_major_version_upgrade

  # Monitoring
  monitoring_interval = each.value.monitoring_interval
  monitoring_role_arn = each.value.monitoring_role_arn
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports
  performance_insights_enabled = each.value.performance_insights_enabled
  performance_insights_retention_period = each.value.performance_insights_retention_period

  # Security
  deletion_protection = each.value.deletion_protection
  
  # Lifecycle
  apply_immediately = each.value.apply_immediately

  tags = each.value.tags

  depends_on = [
    aws_db_subnet_group.this,
    aws_db_parameter_group.this,
    aws_db_option_group.this
  ]

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
  }
}

# RDS Clusters (Aurora)
resource "aws_rds_cluster" "this" {
  for_each = local.rds_clusters

  # Basic Configuration
  cluster_identifier      = each.value.cluster_identifier
  engine                 = each.value.engine
  engine_version         = each.value.engine_version
  engine_mode           = each.value.engine_mode
  database_name         = each.value.database_name
  master_username       = each.value.master_username
  master_password       = each.value.master_password
  manage_master_user_password = each.value.manage_master_user_password

  # Network Configuration
  db_subnet_group_name   = each.value.db_subnet_group_name
  vpc_security_group_ids = each.value.vpc_security_group_ids
  port                   = each.value.port
  availability_zones     = each.value.availability_zones

  # Parameter Group
  db_cluster_parameter_group_name = each.value.db_cluster_parameter_group_name

  # Backup Configuration
  backup_retention_period = each.value.backup_retention_period
  preferred_backup_window = each.value.preferred_backup_window
  copy_tags_to_snapshot   = each.value.copy_tags_to_snapshot
  final_snapshot_identifier = each.value.final_snapshot_identifier
  skip_final_snapshot    = each.value.skip_final_snapshot

  # Maintenance
  preferred_maintenance_window = each.value.preferred_maintenance_window

  # Storage
  storage_encrypted = each.value.storage_encrypted
  kms_key_id       = each.value.kms_key_id
  storage_type     = each.value.storage_type
  allocated_storage = each.value.allocated_storage
  iops            = each.value.iops

  # Monitoring
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports

  # Security and Lifecycle
  deletion_protection = each.value.deletion_protection
  apply_immediately  = each.value.apply_immediately

  # Serverless Configuration
  dynamic "scaling_configuration" {
    for_each = each.value.scaling_configuration != null ? [each.value.scaling_configuration] : []
    content {
      auto_pause               = scaling_configuration.value.auto_pause
      max_capacity            = scaling_configuration.value.max_capacity
      min_capacity            = scaling_configuration.value.min_capacity
      seconds_until_auto_pause = scaling_configuration.value.seconds_until_auto_pause
      timeout_action          = scaling_configuration.value.timeout_action
    }
  }

  tags = each.value.tags

  depends_on = [
    aws_db_subnet_group.this,
    aws_rds_cluster_parameter_group.this
  ]

  lifecycle {
    ignore_changes = [
      master_password,
      final_snapshot_identifier
    ]
  }
}

# RDS Cluster Instances
resource "aws_rds_cluster_instance" "this" {
  for_each = local.rds_cluster_instances

  identifier         = each.value.identifier
  cluster_identifier = each.value.cluster_identifier
  instance_class     = each.value.instance_class
  engine            = each.value.engine
  engine_version    = each.value.engine_version

  # Monitoring
  monitoring_interval = each.value.monitoring_interval
  monitoring_role_arn = each.value.monitoring_role_arn
  performance_insights_enabled = each.value.performance_insights_enabled

  # Maintenance
  auto_minor_version_upgrade = each.value.auto_minor_version_upgrade
  preferred_maintenance_window = each.value.preferred_maintenance_window

  # Security
  publicly_accessible = each.value.publicly_accessible
  
  # Lifecycle
  apply_immediately = each.value.apply_immediately

  tags = each.value.tags

  depends_on = [
    aws_rds_cluster.this
  ]
}

# RDS Proxy (for connection pooling)
resource "aws_db_proxy" "this" {
  for_each = var.rds_proxies

  name                   = "${var.name_prefix}-${each.key}-proxy"
  engine_family         = each.value.engine_family
  auth                  = each.value.auth
  role_arn              = each.value.role_arn
  vpc_subnet_ids        = each.value.vpc_subnet_ids
  vpc_security_group_ids = each.value.vpc_security_group_ids

  require_tls = each.value.require_tls
  idle_client_timeout = each.value.idle_client_timeout
  debug_logging      = each.value.debug_logging

  tags = merge(local.common_tags, each.value.tags, {
    Name   = "${var.name_prefix}-${each.key}-proxy"
    Type   = "rds-proxy"
    Engine = each.value.engine_family
  })
}

# RDS Proxy Targets
resource "aws_db_proxy_default_target_group" "this" {
  for_each = var.rds_proxies

  db_proxy_name = aws_db_proxy.this[each.key].name

  connection_pool_config {
    connection_borrow_timeout    = each.value.connection_pool_config.connection_borrow_timeout
    init_query                  = each.value.connection_pool_config.init_query
    max_connections_percent     = each.value.connection_pool_config.max_connections_percent
    max_idle_connections_percent = each.value.connection_pool_config.max_idle_connections_percent
    session_pinning_filters     = each.value.connection_pool_config.session_pinning_filters
  }
}

# RDS Proxy Target Associations
resource "aws_db_proxy_target" "this" {
  for_each = {
    for target in flatten([
      for proxy_name, proxy_config in var.rds_proxies : [
        for target in proxy_config.targets : {
          proxy_name = proxy_name
          target_key = "${proxy_name}-${target.db_instance_identifier != null ? target.db_instance_identifier : target.db_cluster_identifier}"
          db_instance_identifier = target.db_instance_identifier
          db_cluster_identifier  = target.db_cluster_identifier
        }
      ]
    ]) : target.target_key => target
  }

  db_proxy_name          = aws_db_proxy.this[each.value.proxy_name].name
  target_group_name      = aws_db_proxy_default_target_group.this[each.value.proxy_name].name
  db_instance_identifier = each.value.db_instance_identifier
  db_cluster_identifier  = each.value.db_cluster_identifier
}