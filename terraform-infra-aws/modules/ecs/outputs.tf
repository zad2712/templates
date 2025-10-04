# ECS Cluster Outputs

# Cluster Information
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = try(aws_ecs_cluster.this[0].id, "")
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = try(aws_ecs_cluster.this[0].name, "")
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = try(aws_ecs_cluster.this[0].arn, "")
}

# Cluster Configuration
output "cluster_capacity_providers" {
  description = "Map of cluster capacity providers attributes"
  value       = try(aws_ecs_cluster_capacity_providers.this[0], {})
}

# Capacity Provider Information
output "capacity_provider_arns" {
  description = "ARNs of the capacity providers"
  value       = { for k, v in aws_ecs_capacity_provider.asg : k => v.arn }
}

output "capacity_provider_ids" {
  description = "IDs of the capacity providers"
  value       = { for k, v in aws_ecs_capacity_provider.asg : k => v.id }
}

# Task Definition Information
output "task_definition_arns" {
  description = "Full ARNs of the task definitions"
  value       = { for k, v in aws_ecs_task_definition.this : k => v.arn }
}

output "task_definition_families" {
  description = "Family names of the task definitions"
  value       = { for k, v in aws_ecs_task_definition.this : k => v.family }
}

output "task_definition_revisions" {
  description = "Revisions of the task definitions"
  value       = { for k, v in aws_ecs_task_definition.this : k => v.revision }
}

# Service Information
output "service_ids" {
  description = "IDs of the ECS services"
  value       = { for k, v in aws_ecs_service.this : k => v.id }
}

output "service_names" {
  description = "Names of the ECS services"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "service_cluster_arns" {
  description = "Amazon Resource Name (ARN) of cluster which the service runs on"
  value       = { for k, v in aws_ecs_service.this : k => v.cluster }
}

output "service_desired_count" {
  description = "Number of instances of the task definition"
  value       = { for k, v in aws_ecs_service.this : k => v.desired_count }
}

output "service_iam_role" {
  description = "ARN of IAM role used for ELB"
  value       = { for k, v in aws_ecs_service.this : k => v.iam_role }
}

output "service_launch_type" {
  description = "Launch type on which to run the service"
  value       = { for k, v in aws_ecs_service.this : k => v.launch_type }
}

output "service_platform_version" {
  description = "Platform version on which to run the service"
  value       = { for k, v in aws_ecs_service.this : k => v.platform_version }
}

output "service_task_definition" {
  description = "Family and revision (family:revision) or full ARN of the task definition"
  value       = { for k, v in aws_ecs_service.this : k => v.task_definition }
}

# Auto Scaling Information
output "autoscaling_target_resource_ids" {
  description = "Resource IDs of the autoscaling targets"
  value       = { for k, v in aws_appautoscaling_target.ecs_target : k => v.resource_id }
}

output "autoscaling_policy_cpu_arns" {
  description = "ARNs of the CPU autoscaling policies"
  value       = { for k, v in aws_appautoscaling_policy.ecs_policy_cpu : k => v.arn }
}

output "autoscaling_policy_memory_arns" {
  description = "ARNs of the memory autoscaling policies"
  value       = { for k, v in aws_appautoscaling_policy.ecs_policy_memory : k => v.arn }
}

# CloudWatch Log Groups
output "cloudwatch_log_group_names" {
  description = "Names of the CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.name }
}

output "cloudwatch_log_group_arns" {
  description = "ARNs of the CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.arn }
}

# CloudWatch Alarms
output "cloudwatch_cpu_alarms" {
  description = "CloudWatch CPU utilization alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.cpu_utilization : k => v.arn }
}

output "cloudwatch_memory_alarms" {
  description = "CloudWatch memory utilization alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.memory_utilization : k => v.arn }
}
