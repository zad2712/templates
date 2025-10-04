# RDS Module - Outputs
# Author: Diego A. Zarate

# DB Subnet Groups Outputs
output "db_subnet_groups" {
  description = "Map of DB subnet group information"
  value = {
    for group_name, subnet_group in aws_db_subnet_group.this : group_name => {
      id          = subnet_group.id
      arn         = subnet_group.arn
      name        = subnet_group.name
      description = subnet_group.description
      subnet_ids  = subnet_group.subnet_ids
      tags        = subnet_group.tags_all
    }
  }
}

output "db_subnet_group_names" {
  description = "Names of the DB subnet groups"
  value       = { for group_name, subnet_group in aws_db_subnet_group.this : group_name => subnet_group.name }
}

output "db_subnet_group_arns" {
  description = "ARNs of the DB subnet groups"
  value       = { for group_name, subnet_group in aws_db_subnet_group.this : group_name => subnet_group.arn }
}

# DB Parameter Groups Outputs
output "db_parameter_groups" {
  description = "Map of DB parameter group information"
  value = {
    for group_name, param_group in aws_db_parameter_group.this : group_name => {
      id          = param_group.id
      arn         = param_group.arn
      name        = param_group.name
      family      = param_group.family
      description = param_group.description
      tags        = param_group.tags_all
    }
  }
}

output "db_parameter_group_names" {
  description = "Names of the DB parameter groups"
  value       = { for group_name, param_group in aws_db_parameter_group.this : group_name => param_group.name }
}

output "db_parameter_group_arns" {
  description = "ARNs of the DB parameter groups"
  value       = { for group_name, param_group in aws_db_parameter_group.this : group_name => param_group.arn }
}

# DB Option Groups Outputs
output "db_option_groups" {
  description = "Map of DB option group information"
  value = {
    for group_name, option_group in aws_db_option_group.this : group_name => {
      id                   = option_group.id
      arn                  = option_group.arn
      name                 = option_group.name
      engine_name          = option_group.engine_name
      major_engine_version = option_group.major_engine_version
      tags                 = option_group.tags_all
    }
  }
}

output "db_option_group_names" {
  description = "Names of the DB option groups"
  value       = { for group_name, option_group in aws_db_option_group.this : group_name => option_group.name }
}

output "db_option_group_arns" {
  description = "ARNs of the DB option groups"
  value       = { for group_name, option_group in aws_db_option_group.this : group_name => option_group.arn }
}

# RDS Cluster Parameter Groups Outputs
output "rds_cluster_parameter_groups" {
  description = "Map of RDS cluster parameter group information"
  value = {
    for group_name, cluster_param_group in aws_rds_cluster_parameter_group.this : group_name => {
      id          = cluster_param_group.id
      arn         = cluster_param_group.arn
      name        = cluster_param_group.name
      family      = cluster_param_group.family
      description = cluster_param_group.description
      tags        = cluster_param_group.tags_all
    }
  }
}

output "rds_cluster_parameter_group_names" {
  description = "Names of the RDS cluster parameter groups"
  value       = { for group_name, cluster_param_group in aws_rds_cluster_parameter_group.this : group_name => cluster_param_group.name }
}

output "rds_cluster_parameter_group_arns" {
  description = "ARNs of the RDS cluster parameter groups"
  value       = { for group_name, cluster_param_group in aws_rds_cluster_parameter_group.this : group_name => cluster_param_group.arn }
}

# RDS Instances Outputs
output "rds_instances" {
  description = "Map of RDS instance information"
  value = {
    for instance_name, instance in aws_db_instance.this : instance_name => {
      arn                    = instance.arn
      id                     = instance.id
      identifier             = instance.identifier
      address                = instance.address
      endpoint               = instance.endpoint
      hosted_zone_id         = instance.hosted_zone_id
      port                   = instance.port
      engine                 = instance.engine
      engine_version         = instance.engine_version
      instance_class         = instance.instance_class
      availability_zone      = instance.availability_zone
      multi_az              = instance.multi_az
      publicly_accessible    = instance.publicly_accessible
      storage_encrypted      = instance.storage_encrypted
      allocated_storage      = instance.allocated_storage
      max_allocated_storage  = instance.max_allocated_storage
      storage_type           = instance.storage_type
      backup_retention_period = instance.backup_retention_period
      backup_window          = instance.backup_window
      maintenance_window     = instance.maintenance_window
      deletion_protection    = instance.deletion_protection
      tags                   = instance.tags_all
    }
  }
}

output "rds_instance_endpoints" {
  description = "RDS instance endpoints"
  value       = { for instance_name, instance in aws_db_instance.this : instance_name => instance.endpoint }
}

output "rds_instance_addresses" {
  description = "RDS instance addresses"
  value       = { for instance_name, instance in aws_db_instance.this : instance_name => instance.address }
}

output "rds_instance_arns" {
  description = "RDS instance ARNs"
  value       = { for instance_name, instance in aws_db_instance.this : instance_name => instance.arn }
}

output "rds_instance_ids" {
  description = "RDS instance IDs"
  value       = { for instance_name, instance in aws_db_instance.this : instance_name => instance.id }
}

output "rds_instance_ports" {
  description = "RDS instance ports"
  value       = { for instance_name, instance in aws_db_instance.this : instance_name => instance.port }
}

# RDS Clusters Outputs (Aurora)
output "rds_clusters" {
  description = "Map of RDS cluster information"
  value = {
    for cluster_name, cluster in aws_rds_cluster.this : cluster_name => {
      arn                         = cluster.arn
      id                         = cluster.id
      cluster_identifier         = cluster.cluster_identifier
      endpoint                   = cluster.endpoint
      reader_endpoint            = cluster.reader_endpoint
      hosted_zone_id             = cluster.hosted_zone_id
      port                       = cluster.port
      engine                     = cluster.engine
      engine_version             = cluster.engine_version
      engine_mode               = cluster.engine_mode
      availability_zones        = cluster.availability_zones
      storage_encrypted         = cluster.storage_encrypted
      backup_retention_period   = cluster.backup_retention_period
      preferred_backup_window   = cluster.preferred_backup_window
      preferred_maintenance_window = cluster.preferred_maintenance_window
      deletion_protection       = cluster.deletion_protection
      cluster_members           = cluster.cluster_members
      tags                      = cluster.tags_all
    }
  }
}

output "rds_cluster_endpoints" {
  description = "RDS cluster endpoints"
  value       = { for cluster_name, cluster in aws_rds_cluster.this : cluster_name => cluster.endpoint }
}

output "rds_cluster_reader_endpoints" {
  description = "RDS cluster reader endpoints"
  value       = { for cluster_name, cluster in aws_rds_cluster.this : cluster_name => cluster.reader_endpoint }
}

output "rds_cluster_arns" {
  description = "RDS cluster ARNs"
  value       = { for cluster_name, cluster in aws_rds_cluster.this : cluster_name => cluster.arn }
}

output "rds_cluster_ids" {
  description = "RDS cluster IDs"
  value       = { for cluster_name, cluster in aws_rds_cluster.this : cluster_name => cluster.id }
}

output "rds_cluster_ports" {
  description = "RDS cluster ports"
  value       = { for cluster_name, cluster in aws_rds_cluster.this : cluster_name => cluster.port }
}

# RDS Cluster Instances Outputs
output "rds_cluster_instances" {
  description = "Map of RDS cluster instance information"
  value = {
    for instance_name, instance in aws_rds_cluster_instance.this : instance_name => {
      arn                    = instance.arn
      id                     = instance.id
      identifier             = instance.identifier
      endpoint               = instance.endpoint
      port                   = instance.port
      engine                 = instance.engine
      engine_version         = instance.engine_version
      instance_class         = instance.instance_class
      cluster_identifier     = instance.cluster_identifier
      availability_zone      = instance.availability_zone
      publicly_accessible    = instance.publicly_accessible
      writer                = instance.writer
      tags                  = instance.tags_all
    }
  }
}

output "rds_cluster_instance_endpoints" {
  description = "RDS cluster instance endpoints"
  value       = { for instance_name, instance in aws_rds_cluster_instance.this : instance_name => instance.endpoint }
}

output "rds_cluster_instance_arns" {
  description = "RDS cluster instance ARNs"
  value       = { for instance_name, instance in aws_rds_cluster_instance.this : instance_name => instance.arn }
}

output "rds_cluster_instance_ids" {
  description = "RDS cluster instance IDs"
  value       = { for instance_name, instance in aws_rds_cluster_instance.this : instance_name => instance.id }
}

# RDS Proxy Outputs
output "rds_proxies" {
  description = "Map of RDS proxy information"
  value = {
    for proxy_name, proxy in aws_db_proxy.this : proxy_name => {
      arn        = proxy.arn
      id         = proxy.id
      name       = proxy.name
      endpoint   = proxy.endpoint
      engine_family = proxy.engine_family
      role_arn   = proxy.role_arn
      tags       = proxy.tags_all
    }
  }
}

output "rds_proxy_endpoints" {
  description = "RDS proxy endpoints"
  value       = { for proxy_name, proxy in aws_db_proxy.this : proxy_name => proxy.endpoint }
}

output "rds_proxy_arns" {
  description = "RDS proxy ARNs"
  value       = { for proxy_name, proxy in aws_db_proxy.this : proxy_name => proxy.arn }
}

# Engine-specific Outputs
output "mysql_instances" {
  description = "List of MySQL RDS instances"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if instance_config.engine == "mysql"
  ]
}

output "postgresql_instances" {
  description = "List of PostgreSQL RDS instances"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if instance_config.engine == "postgres"
  ]
}

output "oracle_instances" {
  description = "List of Oracle RDS instances"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if can(regex("^oracle-", instance_config.engine))
  ]
}

output "sqlserver_instances" {
  description = "List of SQL Server RDS instances"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if can(regex("^sqlserver-", instance_config.engine))
  ]
}

output "aurora_mysql_clusters" {
  description = "List of Aurora MySQL clusters"
  value = [
    for cluster_name, cluster_config in var.rds_clusters : cluster_name
    if cluster_config.engine == "aurora-mysql"
  ]
}

output "aurora_postgresql_clusters" {
  description = "List of Aurora PostgreSQL clusters"
  value = [
    for cluster_name, cluster_config in var.rds_clusters : cluster_name
    if cluster_config.engine == "aurora-postgresql"
  ]
}

# High Availability Outputs
output "multi_az_instances" {
  description = "List of Multi-AZ RDS instances"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if instance_config.multi_az
  ]
}

output "encrypted_instances" {
  description = "List of encrypted RDS instances"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if instance_config.storage_encrypted
  ]
}

output "encrypted_clusters" {
  description = "List of encrypted RDS clusters"
  value = [
    for cluster_name, cluster_config in var.rds_clusters : cluster_name
    if cluster_config.storage_encrypted
  ]
}

# Backup Configuration Outputs
output "instances_with_backup" {
  description = "List of RDS instances with backup enabled"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if instance_config.backup_retention_period > 0
  ]
}

output "clusters_with_backup" {
  description = "List of RDS clusters with backup enabled"
  value = [
    for cluster_name, cluster_config in var.rds_clusters : cluster_name
    if cluster_config.backup_retention_period > 0
  ]
}

# Performance Insights Outputs
output "instances_with_performance_insights" {
  description = "List of RDS instances with Performance Insights enabled"
  value = [
    for instance_name, instance_config in var.rds_instances : instance_name
    if instance_config.performance_insights_enabled
  ]
}

output "cluster_instances_with_performance_insights" {
  description = "List of RDS cluster instances with Performance Insights enabled"
  value = [
    for instance_name, instance_config in var.rds_cluster_instances : instance_name
    if instance_config.performance_insights_enabled
  ]
}

# Summary Outputs
output "total_rds_instances" {
  description = "Total number of RDS instances created"
  value       = length(aws_db_instance.this)
}

output "total_rds_clusters" {
  description = "Total number of RDS clusters created"
  value       = length(aws_rds_cluster.this)
}

output "total_rds_cluster_instances" {
  description = "Total number of RDS cluster instances created"
  value       = length(aws_rds_cluster_instance.this)
}

output "total_rds_proxies" {
  description = "Total number of RDS proxies created"
  value       = length(aws_db_proxy.this)
}

output "total_db_subnet_groups" {
  description = "Total number of DB subnet groups created"
  value       = length(aws_db_subnet_group.this)
}

output "total_db_parameter_groups" {
  description = "Total number of DB parameter groups created"
  value       = length(aws_db_parameter_group.this)
}

output "total_db_option_groups" {
  description = "Total number of DB option groups created"
  value       = length(aws_db_option_group.this)
}

# Connection Information
output "connection_info" {
  description = "Connection information for RDS resources"
  value = {
    instances = {
      for instance_name, instance in aws_db_instance.this : instance_name => {
        endpoint = instance.endpoint
        port     = instance.port
        engine   = instance.engine
      }
    }
    clusters = {
      for cluster_name, cluster in aws_rds_cluster.this : cluster_name => {
        writer_endpoint = cluster.endpoint
        reader_endpoint = cluster.reader_endpoint
        port           = cluster.port
        engine         = cluster.engine
      }
    }
    proxies = {
      for proxy_name, proxy in aws_db_proxy.this : proxy_name => {
        endpoint = proxy.endpoint
        engine_family = proxy.engine_family
      }
    }
  }
  sensitive = false
}

# Module Information
output "module_info" {
  description = "RDS module information"
  value = {
    module_name       = "rds"
    module_version    = "1.0.0"
    created_at        = timestamp()
    provider_version  = "~> 5.0"
    terraform_version = ">= 1.9.0"
  }
}