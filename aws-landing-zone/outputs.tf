# AWS Landing Zone Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Subnet Outputs
output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "database_subnet_ids" {
  description = "List of IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "database_subnet_cidrs" {
  description = "List of CIDR blocks of the database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

# Database Subnet Group
output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.database.name
}

output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = aws_db_subnet_group.database.id
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# NAT Gateway
output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs of the NAT Gateways"
  value       = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}

# Route Tables
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = var.enable_nat_gateway ? aws_route_table.private[*].id : [aws_route_table.private[0].id]
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = aws_route_table.database[*].id
}

# Security Groups
output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_security_group.default.id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "management_security_group_id" {
  description = "ID of the management security group"
  value       = aws_security_group.management.id
}

# Network ACLs
output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = aws_network_acl.public.id
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = aws_network_acl.private.id
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = aws_network_acl.database.id
}

# IAM Roles and Policies
output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

# KMS
output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.landing_zone.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.landing_zone.arn
}

output "kms_alias_name" {
  description = "Name of the KMS key alias"
  value       = aws_kms_alias.landing_zone.name
}

# Monitoring and Logging
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_s3_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].bucket : null
}

output "vpc_flow_logs_log_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch Log Group"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "config_configuration_recorder_name" {
  description = "Name of the AWS Config configuration recorder"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = var.enable_cloudwatch_alarms && length(var.sns_email_endpoints) > 0 ? aws_sns_topic.alerts[0].arn : null
}

# Backup
output "backup_vault_name" {
  description = "Name of the AWS Backup vault"
  value       = var.enable_backup_vault ? aws_backup_vault.main[0].name : null
}

output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault"
  value       = var.enable_backup_vault ? aws_backup_vault.main[0].arn : null
}

output "backup_plan_id" {
  description = "ID of the AWS Backup plan"
  value       = var.enable_backup_vault ? aws_backup_plan.main[0].id : null
}

# Cost Management
output "budget_name" {
  description = "Name of the AWS Budget"
  value       = aws_budgets_budget.monthly.name
}

output "cost_anomaly_detector_arn" {
  description = "ARN of the Cost Anomaly Detector"
  value       = aws_ce_anomaly_detector.main.arn
}

# Resource Groups
output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = aws_resourcegroups_group.main.name
}

output "resource_group_arn" {
  description = "ARN of the Resource Group"
  value       = aws_resourcegroups_group.main.arn
}

# Systems Manager Parameters
output "ssm_parameter_vpc_id" {
  description = "SSM Parameter name for VPC ID"
  value       = aws_ssm_parameter.vpc_id.name
}

output "ssm_parameter_private_subnet_ids" {
  description = "SSM Parameter name for private subnet IDs"
  value       = aws_ssm_parameter.private_subnet_ids.name
}

output "ssm_parameter_public_subnet_ids" {
  description = "SSM Parameter name for public subnet IDs"
  value       = aws_ssm_parameter.public_subnet_ids.name
}

output "ssm_parameter_database_subnet_ids" {
  description = "SSM Parameter name for database subnet IDs"
  value       = aws_ssm_parameter.database_subnet_ids.name
}

# Service Catalog
output "service_catalog_portfolio_id" {
  description = "ID of the Service Catalog portfolio"
  value       = aws_servicecatalog_portfolio.main.id
}

# Common Tags
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}