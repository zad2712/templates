#####################################################################################################
# Fetch Data Module - Outputs Configuration
# Organized exposure of infrastructure module data with metadata and extensibility
#####################################################################################################

#####################################################################################################
# Primary Module Outputs
#####################################################################################################

output "all_data" {
  description = "All infrastructure data in the selected output format (structured, flat, or raw)"
  value       = local.final_outputs
  sensitive   = local.mark_outputs_sensitive
}

#####################################################################################################
# Core Layer (VPC) Specific Outputs
#####################################################################################################

output "vpc" {
  description = "VPC module outputs from the core layer"
  value       = local.core_enabled ? local.core_outputs : {}
  sensitive   = local.mark_outputs_sensitive
}

# VPC Core Infrastructure
output "vpc_id" {
  description = "ID of the VPC"
  value       = local.core_enabled && contains(keys(local.core_outputs), "vpc_id") ? local.core_outputs.vpc_id : null
  sensitive   = false
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = local.core_enabled && contains(keys(local.core_outputs), "vpc_cidr_block") ? local.core_outputs.vpc_cidr_block : null
  sensitive   = false
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = local.core_enabled && contains(keys(local.core_outputs), "vpc_arn") ? local.core_outputs.vpc_arn : null
  sensitive   = false
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used by the VPC"
  value       = local.core_enabled && contains(keys(local.core_outputs), "availability_zones") ? local.core_outputs.availability_zones : []
  sensitive   = false
}

# Subnet Information
output "public_subnets" {
  description = "List of IDs of the public subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "public_subnets") ? local.core_outputs.public_subnets : []
  sensitive   = false
}

output "private_subnets" {
  description = "List of IDs of the private subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "private_subnets") ? local.core_outputs.private_subnets : []
  sensitive   = false
}

output "database_subnets" {
  description = "List of IDs of the database subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "database_subnets") ? local.core_outputs.database_subnets : []
  sensitive   = false
}

output "public_subnet_arns" {
  description = "List of ARNs of the public subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "public_subnet_arns") ? local.core_outputs.public_subnet_arns : []
  sensitive   = false
}

output "private_subnet_arns" {
  description = "List of ARNs of the private subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "private_subnet_arns") ? local.core_outputs.private_subnet_arns : []
  sensitive   = false
}

output "database_subnet_arns" {
  description = "List of ARNs of the database subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "database_subnet_arns") ? local.core_outputs.database_subnet_arns : []
  sensitive   = false
}

# CIDR Blocks
output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the public subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "public_subnets_cidr_blocks") ? local.core_outputs.public_subnets_cidr_blocks : []
  sensitive   = false
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the private subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "private_subnets_cidr_blocks") ? local.core_outputs.private_subnets_cidr_blocks : []
  sensitive   = false
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the database subnets"
  value       = local.core_enabled && contains(keys(local.core_outputs), "database_subnets_cidr_blocks") ? local.core_outputs.database_subnets_cidr_blocks : []
  sensitive   = false
}

# Gateway Information
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = local.core_enabled && contains(keys(local.core_outputs), "internet_gateway_id") ? local.core_outputs.internet_gateway_id : null
  sensitive   = false
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = local.core_enabled && contains(keys(local.core_outputs), "internet_gateway_arn") ? local.core_outputs.internet_gateway_arn : null
  sensitive   = false
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = local.core_enabled && contains(keys(local.core_outputs), "nat_gateway_ids") ? local.core_outputs.nat_gateway_ids : []
  sensitive   = false
}

output "nat_public_ips" {
  description = "List of public Elastic IPs of NAT Gateways"
  value       = local.core_enabled && contains(keys(local.core_outputs), "nat_public_ips") ? local.core_outputs.nat_public_ips : []
  sensitive   = false
}

# Route Tables
output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = local.core_enabled && contains(keys(local.core_outputs), "public_route_table_ids") ? local.core_outputs.public_route_table_ids : []
  sensitive   = false
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = local.core_enabled && contains(keys(local.core_outputs), "private_route_table_ids") ? local.core_outputs.private_route_table_ids : []
  sensitive   = false
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = local.core_enabled && contains(keys(local.core_outputs), "database_route_table_ids") ? local.core_outputs.database_route_table_ids : []
  sensitive   = false
}

# VPC Endpoints
output "vpc_endpoint_s3_id" {
  description = "ID of VPC endpoint for S3"
  value       = local.core_enabled && contains(keys(local.core_outputs), "vpc_endpoint_s3_id") ? local.core_outputs.vpc_endpoint_s3_id : null
  sensitive   = false
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of VPC endpoint for DynamoDB"
  value       = local.core_enabled && contains(keys(local.core_outputs), "vpc_endpoint_dynamodb_id") ? local.core_outputs.vpc_endpoint_dynamodb_id : null
  sensitive   = false
}

# Security Groups
output "default_security_group_id" {
  description = "ID of the default security group"
  value       = local.core_enabled && contains(keys(local.core_outputs), "default_security_group_id") ? local.core_outputs.default_security_group_id : null
  sensitive   = false
}

# DNS Configuration
output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = local.core_enabled && contains(keys(local.core_outputs), "vpc_enable_dns_hostnames") ? local.core_outputs.vpc_enable_dns_hostnames : null
  sensitive   = false
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = local.core_enabled && contains(keys(local.core_outputs), "vpc_enable_dns_support") ? local.core_outputs.vpc_enable_dns_support : null
  sensitive   = false
}

#####################################################################################################
# Backend Layer Outputs (Future Extensibility)
#####################################################################################################

output "backend" {
  description = "Backend module outputs from the backend layer"
  value       = local.backend_enabled ? local.backend_outputs : {}
  sensitive   = local.mark_outputs_sensitive
}

#####################################################################################################
# Frontend Layer Outputs (Future Extensibility)
#####################################################################################################

output "frontend" {
  description = "Frontend module outputs from the frontend layer"
  value       = local.frontend_enabled ? local.frontend_outputs : {}
  sensitive   = local.mark_outputs_sensitive
}

#####################################################################################################
# Data Layer Outputs (Future Extensibility)
#####################################################################################################

output "data" {
  description = "Data module outputs from the data layer"
  value       = local.data_enabled ? local.data_outputs : {}
  sensitive   = local.mark_outputs_sensitive
}

#####################################################################################################
# Metadata and Configuration Information
#####################################################################################################

output "metadata" {
  description = "Module metadata including generation time, configuration, and source information"
  value       = var.include_metadata ? local.output_metadata : {}
  sensitive   = false
}

output "configuration_summary" {
  description = "Summary of module configuration for debugging and validation"
  value       = local.configuration_summary
  sensitive   = false
}

output "enabled_modules" {
  description = "List of modules that are enabled and have data available"
  value       = local.enabled_modules
  sensitive   = false
}

#####################################################################################################
# State Information
#####################################################################################################

output "state_configuration" {
  description = "Remote state configuration used for data fetching"
  value = {
    bucket = var.terraform_state_bucket
    region = local.resolved_state_bucket_region
    environment = var.environment
    use_workspace_in_state_key = var.use_workspace_in_state_key
    state_key_prefix = var.state_key_prefix
  }
  sensitive = false
}

output "state_keys" {
  description = "State keys used for each layer"
  value = {
    core = local.core_enabled ? local.core_state_key : "disabled"
    backend = local.backend_enabled ? local.backend_state_key : "disabled"
    frontend = local.frontend_enabled ? local.frontend_state_key : "disabled"
    data = local.data_enabled ? local.data_state_key : "disabled"
  }
  sensitive = false
}

#####################################################################################################
# Health Check Information
#####################################################################################################

output "health_status" {
  description = "Health status of remote state connections"
  value = {
    total_enabled_modules = length(local.enabled_modules)
    successfully_fetched = length([
      for module in local.enabled_modules : module
      if (module == "core" && local.core_enabled) ||
         (module == "backend" && local.backend_enabled) ||
         (module == "frontend" && local.frontend_enabled) ||
         (module == "data" && local.data_enabled)
    ])
    configuration_valid = local.valid_configuration
    last_updated = var.include_metadata ? timestamp() : "metadata_disabled"
  }
  sensitive = false
}