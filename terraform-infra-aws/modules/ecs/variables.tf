# ECS Module Variables

# Cluster Configuration
variable "create_cluster" {
  description = "Whether to create an ECS cluster"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "existing_cluster_name" {
  description = "Name of existing cluster to use if create_cluster is false"
  type        = string
  default     = null
}

variable "cluster_settings" {
  description = "Configuration block(s) with cluster settings"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]
}

# Capacity Providers
variable "capacity_providers" {
  description = "List of short names of one or more capacity providers"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Configuration block for default capacity provider strategy"
  type = list(object({
    capacity_provider = string
    weight            = optional(number)
    base              = optional(number)
  }))
  default = []
}

variable "capacity_provider_asg" {
  description = "Map of capacity provider configurations for Auto Scaling Groups"
  type = map(object({
    auto_scaling_group_arn         = string
    managed_termination_protection = optional(string, "DISABLED")
    managed_scaling = optional(object({
      maximum_scaling_step_size = optional(number)
      minimum_scaling_step_size = optional(number)
      status                    = optional(string)
      target_capacity           = optional(number)
      instance_warmup_period    = optional(number)
    }))
  }))
  default = {}
}

# Execute Command Configuration
variable "execute_command_configuration" {
  description = "Configuration block for execute command"
  type = object({
    kms_key_id = optional(string)
    logging    = optional(string, "DEFAULT")
    log_configuration = optional(object({
      cloud_watch_encryption_enabled = optional(bool)
      cloud_watch_log_group_name     = optional(string)
      s3_bucket_name                 = optional(string)
      s3_bucket_encryption_enabled   = optional(bool)
      s3_key_prefix                  = optional(string)
    }))
  })
  default = null
}

# Service Connect
variable "service_connect_defaults" {
  description = "Configures a default Service Connect namespace"
  type = object({
    namespace = string
  })
  default = null
}

# Task Definitions
variable "task_definitions" {
  description = "Map of task definition configurations"
  type = map(object({
    container_definitions    = list(any)
    requires_compatibilities = list(string)
    network_mode             = optional(string, "awsvpc")
    cpu                      = optional(string)
    memory                   = optional(string)
    execution_role_arn       = optional(string)
    task_role_arn            = optional(string)
    pid_mode                 = optional(string)
    ipc_mode                 = optional(string)

    placement_constraints = optional(list(object({
      type       = string
      expression = optional(string)
    })), [])

    proxy_configuration = optional(object({
      type           = optional(string, "APPMESH")
      container_name = string
      properties     = optional(map(string))
    }))

    volumes = optional(list(object({
      name      = string
      host_path = optional(string)

      docker_volume_configuration = optional(object({
        scope         = optional(string)
        autoprovision = optional(bool)
        driver        = optional(string)
        driver_opts   = optional(map(string))
        labels        = optional(map(string))
      }))

      efs_volume_configuration = optional(object({
        file_system_id          = string
        root_directory          = optional(string)
        transit_encryption      = optional(string)
        transit_encryption_port = optional(number)

        authorization_config = optional(object({
          access_point_id = optional(string)
          iam             = optional(string)
        }))
      }))

      fsx_windows_file_server_volume_configuration = optional(object({
        file_system_id = string
        root_directory = string

        authorization_config = object({
          credentials_parameter = string
          domain                = string
        })
      }))
    })), [])

    runtime_platform = optional(object({
      operating_system_family = optional(string)
      cpu_architecture        = optional(string)
    }))

    ephemeral_storage = optional(object({
      size_in_gib = number
    }))
  }))
  default = {}
}

# Services
variable "services" {
  description = "Map of service configurations"
  type = map(object({
    task_definition  = string
    desired_count    = optional(number, 1)
    launch_type      = optional(string)
    platform_version = optional(string)

    capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      weight            = optional(number)
      base              = optional(number)
    })), [])

    deployment_configuration = optional(object({
      maximum_percent         = optional(number)
      minimum_healthy_percent = optional(number)

      deployment_circuit_breaker = optional(object({
        enable   = bool
        rollback = bool
      }))
    }))

    network_configuration = optional(object({
      subnets          = list(string)
      security_groups  = optional(list(string))
      assign_public_ip = optional(bool, false)
    }))

    load_balancers = optional(list(object({
      target_group_arn = optional(string)
      container_name   = string
      container_port   = number
    })), [])

    service_registries = optional(object({
      registry_arn   = string
      port           = optional(number)
      container_name = optional(string)
      container_port = optional(number)
    }))

    placement_constraints = optional(list(object({
      type       = string
      expression = optional(string)
    })), [])

    placement_strategy = optional(list(object({
      type  = string
      field = optional(string)
    })), [])

    service_connect_configuration = optional(object({
      enabled   = optional(bool, true)
      namespace = optional(string)

      log_configuration = optional(object({
        log_driver = string
        options    = optional(map(string))

        secret_option = optional(list(object({
          name       = string
          value_from = string
        })), [])
      }))

      service = optional(list(object({
        port_name             = string
        discovery_name        = optional(string)
        ingress_port_override = optional(number)

        client_alias = optional(list(object({
          port     = number
          dns_name = optional(string)
        })), [])
      })), [])
    }))

    deployment_controller = optional(object({
      type = string
    }))

    enable_execute_command            = optional(bool, false)
    health_check_grace_period_seconds = optional(number)
    propagate_tags                    = optional(string)
    enable_ecs_managed_tags           = optional(bool, false)

    # Auto Scaling Configuration
    autoscaling = optional(object({
      max_capacity = number
      min_capacity = number

      cpu_scaling = optional(object({
        target_value       = number
        scale_in_cooldown  = optional(number, 300)
        scale_out_cooldown = optional(number, 300)
      }))

      memory_scaling = optional(object({
        target_value       = number
        scale_in_cooldown  = optional(number, 300)
        scale_out_cooldown = optional(number, 300)
      }))
    }))
  }))
  default = {}
}

# CloudWatch Log Groups
variable "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group configurations"
  type = map(object({
    retention_in_days = optional(number, 14)
    kms_key_id        = optional(string)
  }))
  default = {}
}

# CloudWatch Alarms
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for ECS services"
  type        = bool
  default     = true
}

variable "cloudwatch_alarm_actions" {
  description = "List of actions to take when alarms are triggered"
  type        = list(string)
  default     = []
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarms"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for alarms"
  type        = number
  default     = 80
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
