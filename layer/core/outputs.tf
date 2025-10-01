# Core Layer - Outputs

#####################################################################################################
# VPC Outputs
#####################################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

#####################################################################################################
# Subnet Outputs
#####################################################################################################

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = module.vpc.database_subnet_group
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = module.vpc.database_subnet_group_name
}

#####################################################################################################
# Gateway and Routing Outputs
#####################################################################################################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.nat_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs associated with the NAT Gateways"
  value       = module.vpc.nat_public_ips
}

output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = module.vpc.database_route_table_ids
}

#####################################################################################################
# VPC Endpoint Outputs
#####################################################################################################

output "vpc_endpoint_s3_id" {
  description = "ID of VPC endpoint for S3"
  value       = module.vpc.vpc_endpoint_s3_id
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of VPC endpoint for DynamoDB"
  value       = module.vpc.vpc_endpoint_dynamodb_id
}

#####################################################################################################
# Security Outputs
#####################################################################################################

output "vpc_default_security_group_id" {
  description = "ID of the default security group"
  value       = module.vpc.vpc_default_security_group_id
}

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = module.vpc.vpc_flow_log_id
}

#####################################################################################################
# General Information Outputs
#####################################################################################################

output "availability_zones" {
  description = "List of availability zones names in the region"
  value       = module.vpc.azs
}

output "region" {
  description = "AWS region where the VPC is created"
  value       = module.vpc.region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}