# ECS Cluster
resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0

  name = var.cluster_name

  # Cluster settings
  dynamic "setting" {
    for_each = var.cluster_settings
    content {
      name  = setting.value.name
      value = setting.value.value
    }
  }

  # Configuration block
  dynamic "configuration" {
    for_each = var.execute_command_configuration != null ? [var.execute_command_configuration] : []
    content {
      execute_command_configuration {
        kms_key_id = lookup(configuration.value, "kms_key_id", null)
        logging    = lookup(configuration.value, "logging", "DEFAULT")

        dynamic "log_configuration" {
          for_each = lookup(configuration.value, "log_configuration", null) != null ? [configuration.value.log_configuration] : []
          content {
            cloud_watch_encryption_enabled = lookup(log_configuration.value, "cloud_watch_encryption_enabled", null)
            cloud_watch_log_group_name     = lookup(log_configuration.value, "cloud_watch_log_group_name", null)
            s3_bucket_name                 = lookup(log_configuration.value, "s3_bucket_name", null)
            s3_bucket_encryption_enabled   = lookup(log_configuration.value, "s3_bucket_encryption_enabled", null)
            s3_key_prefix                  = lookup(log_configuration.value, "s3_key_prefix", null)
          }
        }
      }
    }
  }

  # Service Connect defaults
  dynamic "service_connect_defaults" {
    for_each = var.service_connect_defaults != null ? [var.service_connect_defaults] : []
    content {
      namespace = service_connect_defaults.value.namespace
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "this" {
  count = var.create_cluster && length(var.capacity_providers) > 0 ? 1 : 0

  cluster_name       = aws_ecs_cluster.this[0].name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = lookup(default_capacity_provider_strategy.value, "weight", null)
      base              = lookup(default_capacity_provider_strategy.value, "base", null)
    }
  }

  depends_on = [aws_ecs_cluster.this]
}

# Auto Scaling Group Capacity Provider
resource "aws_ecs_capacity_provider" "asg" {
  for_each = var.capacity_provider_asg

  name = each.key

  auto_scaling_group_provider {
    auto_scaling_group_arn         = each.value.auto_scaling_group_arn
    managed_termination_protection = lookup(each.value, "managed_termination_protection", "DISABLED")

    dynamic "managed_scaling" {
      for_each = lookup(each.value, "managed_scaling", null) != null ? [each.value.managed_scaling] : []
      content {
        maximum_scaling_step_size = lookup(managed_scaling.value, "maximum_scaling_step_size", null)
        minimum_scaling_step_size = lookup(managed_scaling.value, "minimum_scaling_step_size", null)
        status                    = lookup(managed_scaling.value, "status", null)
        target_capacity           = lookup(managed_scaling.value, "target_capacity", null)
        instance_warmup_period    = lookup(managed_scaling.value, "instance_warmup_period", null)
      }
    }
  }

  tags = var.tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  for_each = var.task_definitions

  family                   = each.key
  container_definitions    = jsonencode(each.value.container_definitions)
  requires_compatibilities = each.value.requires_compatibilities
  network_mode             = lookup(each.value, "network_mode", "awsvpc")
  cpu                      = lookup(each.value, "cpu", null)
  memory                   = lookup(each.value, "memory", null)
  execution_role_arn       = lookup(each.value, "execution_role_arn", null)
  task_role_arn            = lookup(each.value, "task_role_arn", null)
  pid_mode                 = lookup(each.value, "pid_mode", null)
  ipc_mode                 = lookup(each.value, "ipc_mode", null)

  # Placement constraints
  dynamic "placement_constraints" {
    for_each = lookup(each.value, "placement_constraints", [])
    content {
      type       = placement_constraints.value.type
      expression = lookup(placement_constraints.value, "expression", null)
    }
  }

  # Proxy configuration
  dynamic "proxy_configuration" {
    for_each = lookup(each.value, "proxy_configuration", null) != null ? [each.value.proxy_configuration] : []
    content {
      type           = lookup(proxy_configuration.value, "type", "APPMESH")
      container_name = proxy_configuration.value.container_name
      properties     = lookup(proxy_configuration.value, "properties", null)
    }
  }

  # Volume configuration
  dynamic "volume" {
    for_each = lookup(each.value, "volumes", [])
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", null) != null ? [volume.value.docker_volume_configuration] : []
        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null)
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", null) != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)

          dynamic "authorization_config" {
            for_each = lookup(efs_volume_configuration.value, "authorization_config", null) != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }

      dynamic "fsx_windows_file_server_volume_configuration" {
        for_each = lookup(volume.value, "fsx_windows_file_server_volume_configuration", null) != null ? [volume.value.fsx_windows_file_server_volume_configuration] : []
        content {
          file_system_id = fsx_windows_file_server_volume_configuration.value.file_system_id
          root_directory = fsx_windows_file_server_volume_configuration.value.root_directory

          authorization_config {
            credentials_parameter = fsx_windows_file_server_volume_configuration.value.authorization_config.credentials_parameter
            domain                = fsx_windows_file_server_volume_configuration.value.authorization_config.domain
          }
        }
      }
    }
  }

  # Runtime platform
  dynamic "runtime_platform" {
    for_each = lookup(each.value, "runtime_platform", null) != null ? [each.value.runtime_platform] : []
    content {
      operating_system_family = lookup(runtime_platform.value, "operating_system_family", null)
      cpu_architecture        = lookup(runtime_platform.value, "cpu_architecture", null)
    }
  }

  # Ephemeral storage
  dynamic "ephemeral_storage" {
    for_each = lookup(each.value, "ephemeral_storage", null) != null ? [each.value.ephemeral_storage] : []
    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }
  }

  tags = merge(
    var.tags,
    {
      Name = each.key
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Service
resource "aws_ecs_service" "this" {
  for_each = var.services

  name             = each.key
  cluster          = var.create_cluster ? aws_ecs_cluster.this[0].id : var.existing_cluster_name
  task_definition  = "${aws_ecs_task_definition.this[each.value.task_definition].family}:${max(aws_ecs_task_definition.this[each.value.task_definition].revision, aws_ecs_task_definition.this[each.value.task_definition].revision)}"
  desired_count    = lookup(each.value, "desired_count", 1)
  launch_type      = lookup(each.value, "launch_type", null)
  platform_version = lookup(each.value, "platform_version", null)

  # Capacity provider strategy
  dynamic "capacity_provider_strategy" {
    for_each = lookup(each.value, "capacity_provider_strategy", [])
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = lookup(capacity_provider_strategy.value, "weight", null)
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  # Deployment configuration
  dynamic "deployment_configuration" {
    for_each = lookup(each.value, "deployment_configuration", null) != null ? [each.value.deployment_configuration] : []
    content {
      maximum_percent         = lookup(deployment_configuration.value, "maximum_percent", null)
      minimum_healthy_percent = lookup(deployment_configuration.value, "minimum_healthy_percent", null)

      dynamic "deployment_circuit_breaker" {
        for_each = lookup(deployment_configuration.value, "deployment_circuit_breaker", null) != null ? [deployment_configuration.value.deployment_circuit_breaker] : []
        content {
          enable   = deployment_circuit_breaker.value.enable
          rollback = deployment_circuit_breaker.value.rollback
        }
      }
    }
  }

  # Network configuration
  dynamic "network_configuration" {
    for_each = lookup(each.value, "network_configuration", null) != null ? [each.value.network_configuration] : []
    content {
      subnets          = network_configuration.value.subnets
      security_groups  = lookup(network_configuration.value, "security_groups", null)
      assign_public_ip = lookup(network_configuration.value, "assign_public_ip", false)
    }
  }

  # Load balancer configuration
  dynamic "load_balancer" {
    for_each = lookup(each.value, "load_balancers", [])
    content {
      target_group_arn = lookup(load_balancer.value, "target_group_arn", null)
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  # Service registries
  dynamic "service_registries" {
    for_each = lookup(each.value, "service_registries", null) != null ? [each.value.service_registries] : []
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }

  # Placement constraints
  dynamic "placement_constraints" {
    for_each = lookup(each.value, "placement_constraints", [])
    content {
      type       = placement_constraints.value.type
      expression = lookup(placement_constraints.value, "expression", null)
    }
  }

  # Placement strategy
  dynamic "placement_strategy" {
    for_each = lookup(each.value, "placement_strategy", [])
    content {
      type  = placement_strategy.value.type
      field = lookup(placement_strategy.value, "field", null)
    }
  }

  # Service Connect
  dynamic "service_connect_configuration" {
    for_each = lookup(each.value, "service_connect_configuration", null) != null ? [each.value.service_connect_configuration] : []
    content {
      enabled   = lookup(service_connect_configuration.value, "enabled", true)
      namespace = lookup(service_connect_configuration.value, "namespace", null)

      dynamic "log_configuration" {
        for_each = lookup(service_connect_configuration.value, "log_configuration", null) != null ? [service_connect_configuration.value.log_configuration] : []
        content {
          log_driver = log_configuration.value.log_driver
          options    = lookup(log_configuration.value, "options", null)

          dynamic "secret_option" {
            for_each = lookup(log_configuration.value, "secret_option", [])
            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }

      dynamic "service" {
        for_each = lookup(service_connect_configuration.value, "service", [])
        content {
          port_name             = service.value.port_name
          discovery_name        = lookup(service.value, "discovery_name", null)
          ingress_port_override = lookup(service.value, "ingress_port_override", null)

          dynamic "client_alias" {
            for_each = lookup(service.value, "client_alias", [])
            content {
              port     = client_alias.value.port
              dns_name = lookup(client_alias.value, "dns_name", null)
            }
          }
        }
      }
    }
  }

  # Deployment controller
  dynamic "deployment_controller" {
    for_each = lookup(each.value, "deployment_controller", null) != null ? [each.value.deployment_controller] : []
    content {
      type = deployment_controller.value.type
    }
  }

  # Enable execute command
  enable_execute_command = lookup(each.value, "enable_execute_command", false)

  # Health check grace period
  health_check_grace_period_seconds = lookup(each.value, "health_check_grace_period_seconds", null)

  # Propagate tags
  propagate_tags = lookup(each.value, "propagate_tags", null)

  # Enable ECS managed tags
  enable_ecs_managed_tags = lookup(each.value, "enable_ecs_managed_tags", false)

  tags = merge(
    var.tags,
    {
      Name = each.key
    }
  )

  depends_on = [
    aws_ecs_task_definition.this,
    aws_ecs_cluster.this
  ]

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = { for k, v in var.services : k => v if lookup(v, "autoscaling", null) != null }

  max_capacity       = each.value.autoscaling.max_capacity
  min_capacity       = each.value.autoscaling.min_capacity
  resource_id        = "service/${var.create_cluster ? aws_ecs_cluster.this[0].name : var.existing_cluster_name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  for_each = { for k, v in var.services : k => v if lookup(v, "autoscaling", null) != null && lookup(v.autoscaling, "cpu_scaling", null) != null }

  name               = "${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = each.value.autoscaling.cpu_scaling.target_value
    scale_in_cooldown  = lookup(each.value.autoscaling.cpu_scaling, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value.autoscaling.cpu_scaling, "scale_out_cooldown", 300)
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  for_each = { for k, v in var.services : k => v if lookup(v, "autoscaling", null) != null && lookup(v.autoscaling, "memory_scaling", null) != null }

  name               = "${each.key}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = each.value.autoscaling.memory_scaling.target_value
    scale_in_cooldown  = lookup(each.value.autoscaling.memory_scaling, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value.autoscaling.memory_scaling, "scale_out_cooldown", 300)
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "this" {
  for_each = var.cloudwatch_log_groups

  name              = each.key
  retention_in_days = lookup(each.value, "retention_in_days", 14)
  kms_key_id        = lookup(each.value, "kms_key_id", null)

  tags = merge(
    var.tags,
    {
      Name = each.key
    }
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  for_each = { for k, v in var.services : k => v if var.enable_cloudwatch_alarms }

  alarm_name          = "${each.key}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This metric monitors ECS service CPU utilization"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    ServiceName = each.key
    ClusterName = var.create_cluster ? aws_ecs_cluster.this[0].name : var.existing_cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  for_each = { for k, v in var.services : k => v if var.enable_cloudwatch_alarms }

  alarm_name          = "${each.key}-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "This metric monitors ECS service memory utilization"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    ServiceName = each.key
    ClusterName = var.create_cluster ? aws_ecs_cluster.this[0].name : var.existing_cluster_name
  }

  tags = var.tags
}
