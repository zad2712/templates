# ElastiCache Module Configuration
locals {
  # Common tags
  common_tags = merge(var.common_tags, {
    Module = "elasticache"
    ManagedBy = "terraform"
  })
  
  # Redis configurations
  redis_clusters = {
    for cluster_key, cluster in var.redis_clusters : cluster_key => merge(cluster, {
      cluster_key = cluster_key
      name = "${var.name_prefix}-redis-${cluster_key}"
      
      # Set defaults
      node_type = cluster.node_type
      engine_version = lookup(cluster, "engine_version", "7.0")
      port = lookup(cluster, "port", 6379)
      parameter_group_name = lookup(cluster, "parameter_group_name", null)
      
      # Cluster mode configuration
      cluster_mode = lookup(cluster, "cluster_mode", {
        replicas_per_node_group = 1
        num_node_groups = 1
      })
      
      # Security and networking
      subnet_group_name = lookup(cluster, "subnet_group_name", null)
      security_group_ids = lookup(cluster, "security_group_ids", [])
      
      # Backup and maintenance
      backup_retention_period = lookup(cluster, "backup_retention_period", 5)
      backup_window = lookup(cluster, "backup_window", "03:00-05:00")
      maintenance_window = lookup(cluster, "maintenance_window", "sun:05:00-sun:07:00")
      
      # Encryption
      at_rest_encryption_enabled = lookup(cluster, "at_rest_encryption_enabled", true)
      transit_encryption_enabled = lookup(cluster, "transit_encryption_enabled", true)
      auth_token = lookup(cluster, "auth_token", null)
      
      # Logging and monitoring
      log_delivery_configuration = lookup(cluster, "log_delivery_configuration", [])
      
      # Multi-AZ and failover
      multi_az_enabled = lookup(cluster, "multi_az_enabled", true)
      automatic_failover_enabled = lookup(cluster, "automatic_failover_enabled", true)
      
      # Data tiering (Redis 6.2+)
      data_tiering_enabled = lookup(cluster, "data_tiering_enabled", false)
    })
  }
  
  # Memcached configurations
  memcached_clusters = {
    for cluster_key, cluster in var.memcached_clusters : cluster_key => merge(cluster, {
      cluster_key = cluster_key
      name = "${var.name_prefix}-memcached-${cluster_key}"
      
      # Set defaults
      node_type = cluster.node_type
      num_cache_nodes = cluster.num_cache_nodes
      engine_version = lookup(cluster, "engine_version", "1.6.17")
      port = lookup(cluster, "port", 11211)
      parameter_group_name = lookup(cluster, "parameter_group_name", null)
      
      # Security and networking
      subnet_group_name = lookup(cluster, "subnet_group_name", null)
      security_group_ids = lookup(cluster, "security_group_ids", [])
      az_mode = lookup(cluster, "az_mode", "cross-az")
      preferred_availability_zones = lookup(cluster, "preferred_availability_zones", [])
      
      # Maintenance
      maintenance_window = lookup(cluster, "maintenance_window", "sun:05:00-sun:07:00")
      
      # Logging
      log_delivery_configuration = lookup(cluster, "log_delivery_configuration", [])
    })
  }
  
  # Subnet group configurations
  subnet_groups = {
    for sg_key, sg in var.subnet_groups : sg_key => merge(sg, {
      subnet_group_key = sg_key
      name = "${var.name_prefix}-${sg_key}-subnet-group"
      description = lookup(sg, "description", "ElastiCache subnet group for ${sg_key}")
      subnet_ids = sg.subnet_ids
    })
  }
  
  # Parameter group configurations
  parameter_groups = {
    for pg_key, pg in var.parameter_groups : pg_key => merge(pg, {
      parameter_group_key = pg_key
      name = "${var.name_prefix}-${pg_key}-params"
      family = pg.family
      description = lookup(pg, "description", "ElastiCache parameter group for ${pg_key}")
      parameters = lookup(pg, "parameters", {})
    })
  }
}

# ElastiCache Subnet Groups
resource "aws_elasticache_subnet_group" "subnet_groups" {
  for_each = local.subnet_groups
  
  name        = each.value.name
  description = each.value.description
  subnet_ids  = each.value.subnet_ids
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.name
    SubnetGroupKey = each.key
  })
}

# ElastiCache Parameter Groups
resource "aws_elasticache_parameter_group" "parameter_groups" {
  for_each = local.parameter_groups
  
  name        = each.value.name
  family      = each.value.family
  description = each.value.description
  
  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.name
    ParameterGroupKey = each.key
    Family = each.value.family
  })
}

# Redis Replication Groups (Cluster Mode Enabled)
resource "aws_elasticache_replication_group" "redis_clusters" {
  for_each = local.redis_clusters
  
  replication_group_id       = each.value.name
  description                = lookup(each.value, "description", "Redis cluster ${each.key}")
  
  # Engine configuration
  engine               = "redis"
  engine_version       = each.value.engine_version
  node_type           = each.value.node_type
  port                = each.value.port
  parameter_group_name = each.value.parameter_group_name != null ? 
                        each.value.parameter_group_name : 
                        try(aws_elasticache_parameter_group.parameter_groups[each.value.parameter_group_key].name, null)
  
  # Cluster configuration
  num_cache_clusters = each.value.cluster_mode.num_node_groups == null ? 
                      lookup(each.value, "num_cache_clusters", 1) : null
  
  # Cluster mode configuration
  dynamic "num_cache_clusters" {
    for_each = each.value.cluster_mode.num_node_groups != null ? [] : [1]
    content {
      num_cache_clusters = lookup(each.value, "num_cache_clusters", 1)
    }
  }
  
  # Cluster mode (sharding) configuration
  num_node_groups         = each.value.cluster_mode.num_node_groups
  replicas_per_node_group = each.value.cluster_mode.replicas_per_node_group
  
  # Data tiering (Redis 6.2+)
  data_tiering_enabled = each.value.data_tiering_enabled
  
  # Network and security
  subnet_group_name   = each.value.subnet_group_name != null ? 
                       each.value.subnet_group_name : 
                       try(aws_elasticache_subnet_group.subnet_groups[each.value.subnet_group_key].name, null)
  security_group_ids  = each.value.security_group_ids
  
  # Backup configuration
  snapshot_retention_limit = each.value.backup_retention_period
  snapshot_window         = each.value.backup_window
  final_snapshot_identifier = "${each.value.name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmmss", timestamp())}"
  
  # Maintenance
  maintenance_window          = each.value.maintenance_window
  notification_topic_arn      = lookup(each.value, "notification_topic_arn", null)
  
  # High availability
  multi_az_enabled           = each.value.multi_az_enabled
  automatic_failover_enabled = each.value.automatic_failover_enabled && each.value.cluster_mode.num_node_groups != null ? true : 
                              each.value.automatic_failover_enabled && lookup(each.value, "num_cache_clusters", 1) > 1 ? true : false
  
  # Encryption
  at_rest_encryption_enabled = each.value.at_rest_encryption_enabled
  transit_encryption_enabled = each.value.transit_encryption_enabled
  auth_token                = each.value.transit_encryption_enabled ? each.value.auth_token : null
  kms_key_id               = lookup(each.value, "kms_key_id", null)
  
  # User group for RBAC (Redis 6.0+)
  user_group_ids = lookup(each.value, "user_group_ids", null)
  
  # Global datastore (for cross-region replication)
  global_replication_group_id = lookup(each.value, "global_replication_group_id", null)
  
  # Log delivery configuration
  dynamic "log_delivery_configuration" {
    for_each = each.value.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format      = log_delivery_configuration.value.log_format
      log_type        = log_delivery_configuration.value.log_type
    }
  }
  
  # Auto minor version upgrade
  auto_minor_version_upgrade = lookup(each.value, "auto_minor_version_upgrade", true)
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.name
    ClusterKey = each.key
    Engine = "redis"
    EngineVersion = each.value.engine_version
    NodeType = each.value.node_type
    ClusterMode = each.value.cluster_mode.num_node_groups != null ? "enabled" : "disabled"
  })
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore auth_token changes to prevent unnecessary updates
      auth_token,
    ]
  }
}

# Memcached Clusters
resource "aws_elasticache_cluster" "memcached_clusters" {
  for_each = local.memcached_clusters
  
  cluster_id           = each.value.name
  engine              = "memcached"
  engine_version      = each.value.engine_version
  node_type          = each.value.node_type
  num_cache_nodes    = each.value.num_cache_nodes
  parameter_group_name = each.value.parameter_group_name != null ? 
                        each.value.parameter_group_name : 
                        try(aws_elasticache_parameter_group.parameter_groups[each.value.parameter_group_key].name, null)
  port               = each.value.port
  
  # Network and security
  subnet_group_name  = each.value.subnet_group_name != null ? 
                      each.value.subnet_group_name : 
                      try(aws_elasticache_subnet_group.subnet_groups[each.value.subnet_group_key].name, null)
  security_group_ids = each.value.security_group_ids
  
  # Availability zone configuration
  az_mode                    = each.value.az_mode
  preferred_availability_zones = length(each.value.preferred_availability_zones) > 0 ? 
                                each.value.preferred_availability_zones : null
  
  # Maintenance
  maintenance_window     = each.value.maintenance_window
  notification_topic_arn = lookup(each.value, "notification_topic_arn", null)
  
  # Log delivery configuration
  dynamic "log_delivery_configuration" {
    for_each = each.value.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format      = log_delivery_configuration.value.log_format
      log_type        = log_delivery_configuration.value.log_type
    }
  }
  
  # Auto minor version upgrade
  auto_minor_version_upgrade = lookup(each.value, "auto_minor_version_upgrade", true)
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.name
    ClusterKey = each.key
    Engine = "memcached"
    EngineVersion = each.value.engine_version
    NodeType = each.value.node_type
    NumCacheNodes = each.value.num_cache_nodes
  })
}

# Redis Users (for RBAC - Redis 6.0+)
resource "aws_elasticache_user" "redis_users" {
  for_each = var.redis_users
  
  user_id       = each.value.user_id
  user_name     = each.value.user_name
  engine        = "REDIS"
  access_string = each.value.access_string
  
  # Authentication
  no_password_required = lookup(each.value, "no_password_required", false)
  passwords           = lookup(each.value, "passwords", null)
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.user_name
    UserKey = each.key
    Engine = "redis"
  })
}

# Redis User Groups (for RBAC - Redis 6.0+)
resource "aws_elasticache_user_group" "redis_user_groups" {
  for_each = var.redis_user_groups
  
  engine          = "REDIS"
  user_group_id   = each.value.user_group_id
  user_ids        = each.value.user_ids
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = each.value.user_group_id
    UserGroupKey = each.key
    Engine = "redis"
  })
  
  depends_on = [aws_elasticache_user.redis_users]
}

# Global Replication Groups (for cross-region Redis replication)
resource "aws_elasticache_global_replication_group" "global_redis" {
  for_each = var.global_replication_groups
  
  global_replication_group_id_suffix = each.value.global_replication_group_id_suffix
  primary_replication_group_id       = each.value.primary_replication_group_id
  
  description = lookup(each.value, "description", "Global replication group for ${each.key}")
  
  # Cache node type must be consistent across regions
  cache_node_type           = each.value.cache_node_type
  engine_version           = lookup(each.value, "engine_version", null)
  
  # Auto minor version upgrade
  automatic_failover_enabled = lookup(each.value, "automatic_failover_enabled", true)
  
  tags = merge(local.common_tags, lookup(each.value, "tags", {}), {
    Name = "${var.name_prefix}-global-${each.key}"
    GlobalReplicationGroupKey = each.key
    Engine = "redis"
  })
}

# CloudWatch Alarms for Redis monitoring
resource "aws_cloudwatch_metric_alarm" "redis_cpu_utilization" {
  for_each = var.enable_cloudwatch_alarms ? local.redis_clusters : {}
  
  alarm_name          = "${each.value.name}-redis-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = lookup(each.value, "cpu_threshold", 80)
  alarm_description   = "This metric monitors Redis CPU utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.redis_clusters[each.key].id
  }
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_utilization" {
  for_each = var.enable_cloudwatch_alarms ? local.redis_clusters : {}
  
  alarm_name          = "${each.value.name}-redis-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = lookup(each.value, "memory_threshold", 80)
  alarm_description   = "This metric monitors Redis memory utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.redis_clusters[each.key].id
  }
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "redis_connection_count" {
  for_each = var.enable_cloudwatch_alarms ? local.redis_clusters : {}
  
  alarm_name          = "${each.value.name}-redis-connection-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = lookup(each.value, "connection_threshold", 100)
  alarm_description   = "This metric monitors Redis connection count"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.redis_clusters[each.key].id
  }
  
  tags = local.common_tags
}

# CloudWatch Alarms for Memcached monitoring
resource "aws_cloudwatch_metric_alarm" "memcached_cpu_utilization" {
  for_each = var.enable_cloudwatch_alarms ? local.memcached_clusters : {}
  
  alarm_name          = "${each.value.name}-memcached-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = lookup(each.value, "cpu_threshold", 80)
  alarm_description   = "This metric monitors Memcached CPU utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    CacheClusterId = aws_elasticache_cluster.memcached_clusters[each.key].cluster_id
  }
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "memcached_memory_utilization" {
  for_each = var.enable_cloudwatch_alarms ? local.memcached_clusters : {}
  
  alarm_name          = "${each.value.name}-memcached-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = lookup(each.value, "memory_threshold", 80)
  alarm_description   = "This metric monitors Memcached memory utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    CacheClusterId = aws_elasticache_cluster.memcached_clusters[each.key].cluster_id
  }
  
  tags = local.common_tags
}

# SNS topic for ElastiCache notifications (optional)
resource "aws_sns_topic" "elasticache_notifications" {
  count = var.create_sns_topic ? 1 : 0
  
  name = "${var.name_prefix}-elasticache-notifications"
  
  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-elasticache-notifications"
    Service = "ElastiCache"
  })
}

resource "aws_sns_topic_policy" "elasticache_notifications_policy" {
  count = var.create_sns_topic ? 1 : 0
  
  arn = aws_sns_topic.elasticache_notifications[0].arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "elasticache-notifications-policy"
    Statement = [
      {
        Sid    = "AllowElastiCachePublish"
        Effect = "Allow"
        Principal = {
          Service = "elasticache.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.elasticache_notifications[0].arn
      }
    ]
  })
}

# Data sources for current AWS context
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}