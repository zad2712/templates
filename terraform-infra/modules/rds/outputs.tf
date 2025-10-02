output "db_instance_id" {
  description = "RDS instance ID"
  value       = var.create_db_instance ? aws_db_instance.main[0].id : null
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = var.create_db_instance ? aws_db_instance.main[0].arn : null
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_db_instance ? aws_db_instance.main[0].endpoint : null
}

output "db_subnet_group_id" {
  description = "DB subnet group ID"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.main[0].id : null
}
