# Local values for ECS module
locals {
  # Cluster configuration
  cluster_name_formatted = replace(lower(var.cluster_name), "_", "-")

  # Determine cluster to use
  cluster_id         = var.create_cluster ? aws_ecs_cluster.this[0].id : var.existing_cluster_name
  cluster_name_final = var.create_cluster ? aws_ecs_cluster.this[0].name : var.existing_cluster_name

  # Default cluster settings
  default_cluster_settings = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]

  # Merged cluster settings
  cluster_settings = length(var.cluster_settings) > 0 ? var.cluster_settings : local.default_cluster_settings

  # Capacity provider strategy
  has_capacity_providers = length(var.capacity_providers) > 0
  has_default_strategy   = length(var.default_capacity_provider_strategy) > 0

  # Service configurations
  services_with_fargate = {
    for k, v in var.services : k => v
    if lookup(v, "launch_type", "FARGATE") == "FARGATE"
  }

  services_with_ec2 = {
    for k, v in var.services : k => v
    if lookup(v, "launch_type", "FARGATE") == "EC2"
  }

  services_with_autoscaling = {
    for k, v in var.services : k => v
    if lookup(v, "autoscaling", null) != null
  }

  # Task definition configurations
  task_definitions_with_fargate = {
    for k, v in var.task_definitions : k => v
    if contains(v.requires_compatibilities, "FARGATE")
  }

  task_definitions_with_ec2 = {
    for k, v in var.task_definitions : k => v
    if contains(v.requires_compatibilities, "EC2")
  }

  # Network configurations
  services_with_vpc_config = {
    for k, v in var.services : k => v
    if lookup(v, "network_configuration", null) != null
  }

  services_with_load_balancer = {
    for k, v in var.services : k => v
    if length(lookup(v, "load_balancers", [])) > 0
  }

  # CloudWatch configurations
  log_groups_to_create = var.cloudwatch_log_groups

  # Monitoring configuration
  monitoring_config = {
    enable_alarms    = var.enable_cloudwatch_alarms
    cpu_threshold    = var.cpu_alarm_threshold
    memory_threshold = var.memory_alarm_threshold
    alarm_actions    = var.cloudwatch_alarm_actions
  }

  # Auto scaling configurations
  autoscaling_services = {
    for k, v in var.services : k => v.autoscaling
    if lookup(v, "autoscaling", null) != null
  }

  cpu_scaling_services = {
    for k, v in local.autoscaling_services : k => v
    if lookup(v, "cpu_scaling", null) != null
  }

  memory_scaling_services = {
    for k, v in local.autoscaling_services : k => v
    if lookup(v, "memory_scaling", null) != null
  }

  # Service Connect configurations
  services_with_service_connect = {
    for k, v in var.services : k => v
    if lookup(v, "service_connect_configuration", null) != null
  }

  # Execute command configurations
  services_with_exec_command = {
    for k, v in var.services : k => v
    if lookup(v, "enable_execute_command", false) == true
  }

  # Placement configurations
  services_with_placement_constraints = {
    for k, v in var.services : k => v
    if length(lookup(v, "placement_constraints", [])) > 0
  }

  services_with_placement_strategy = {
    for k, v in var.services : k => v
    if length(lookup(v, "placement_strategy", [])) > 0
  }

  # Default tags
  default_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Service     = "ecs"
    ClusterName = var.cluster_name
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }

  # Merged tags
  tags = merge(local.default_tags, var.tags)

  # Container insights enabled check
  container_insights_enabled = anytrue([
    for setting in local.cluster_settings :
    setting.name == "containerInsights" && setting.value == "enabled"
  ])

  # Security configurations
  task_definitions_with_execution_role = {
    for k, v in var.task_definitions : k => v
    if lookup(v, "execution_role_arn", null) != null
  }

  task_definitions_with_task_role = {
    for k, v in var.task_definitions : k => v
    if lookup(v, "task_role_arn", null) != null
  }

  # Volume configurations
  task_definitions_with_efs = {
    for k, v in var.task_definitions : k => v
    if length([
      for vol in lookup(v, "volumes", []) : vol
      if lookup(vol, "efs_volume_configuration", null) != null
    ]) > 0
  }

  task_definitions_with_fsx = {
    for k, v in var.task_definitions : k => v
    if length([
      for vol in lookup(v, "volumes", []) : vol
      if lookup(vol, "fsx_windows_file_server_volume_configuration", null) != null
    ]) > 0
  }

  # Platform configurations
  task_definitions_with_runtime_platform = {
    for k, v in var.task_definitions : k => v
    if lookup(v, "runtime_platform", null) != null
  }

  # Ephemeral storage configurations
  task_definitions_with_ephemeral_storage = {
    for k, v in var.task_definitions : k => v
    if lookup(v, "ephemeral_storage", null) != null
  }

  # Validation flags
  validation = {
    # Ensure task definitions exist for services
    services_have_task_definitions = alltrue([
      for k, v in var.services :
      contains(keys(var.task_definitions), v.task_definition)
    ])

    # Ensure Fargate services have awsvpc network mode
    fargate_services_use_awsvpc = alltrue([
      for k, v in local.services_with_fargate :
      lookup(var.task_definitions[v.task_definition], "network_mode", "awsvpc") == "awsvpc"
    ])

    # Ensure Fargate services have CPU and memory defined
    fargate_services_have_resources = alltrue([
      for k, v in local.services_with_fargate :
      lookup(var.task_definitions[v.task_definition], "cpu", null) != null &&
      lookup(var.task_definitions[v.task_definition], "memory", null) != null
    ])
  }
}
