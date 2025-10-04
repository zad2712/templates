# =============================================================================
# DATA LAYER OUTPUTS
# =============================================================================

# RDS
output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = var.enable_rds ? module.rds[0].db_instance_id : null
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.enable_rds ? module.rds[0].db_instance_endpoint : null
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.enable_rds ? module.rds[0].db_instance_port : null
}

output "rds_arn" {
  description = "RDS instance ARN"
  value       = var.enable_rds ? module.rds[0].db_instance_arn : null
}

output "rds_subnet_group_name" {
  description = "Name of the RDS subnet group"
  value       = var.enable_rds ? module.rds_subnet_group[0].name : null
}

# ElastiCache Redis
output "redis_cluster_id" {
  description = "ID of the Redis cluster"
  value       = var.enable_elasticache ? module.elasticache_redis[0].cluster_id : null
}

output "redis_primary_endpoint" {
  description = "Primary endpoint of the Redis cluster"
  value       = var.enable_elasticache ? module.elasticache_redis[0].primary_endpoint_address : null
}

output "redis_port" {
  description = "Port of the Redis cluster"
  value       = var.enable_elasticache ? module.elasticache_redis[0].port : null
}

output "redis_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = var.enable_elasticache ? module.elasticache_subnet_group[0].name : null
}

# DynamoDB
output "dynamodb_table_names" {
  description = "Names of the DynamoDB tables"
  value       = length(var.dynamodb_tables) > 0 ? module.dynamodb[0].table_names : {}
}

output "dynamodb_table_arns" {
  description = "ARNs of the DynamoDB tables"
  value       = length(var.dynamodb_tables) > 0 ? module.dynamodb[0].table_arns : {}
}

output "dynamodb_table_stream_arns" {
  description = "Stream ARNs of the DynamoDB tables"
  value       = length(var.dynamodb_tables) > 0 ? module.dynamodb[0].table_stream_arns : {}
}

# S3
output "s3_bucket_names" {
  description = "Names of the S3 buckets"
  value       = length(var.s3_buckets) > 0 ? module.s3_buckets[0].bucket_names : {}
}

output "s3_bucket_arns" {
  description = "ARNs of the S3 buckets"
  value       = length(var.s3_buckets) > 0 ? module.s3_buckets[0].bucket_arns : {}
}

output "s3_bucket_domain_names" {
  description = "Domain names of the S3 buckets"
  value       = length(var.s3_buckets) > 0 ? module.s3_buckets[0].bucket_domain_names : {}
}
