#####################################################################################################
# AWS VPC Module - Outputs Configuration
# Output values for use by other modules and resources
#####################################################################################################

#####################################################################################################
# VPC Outputs
#####################################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = aws_vpc.main.instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = aws_vpc.main.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = aws_vpc.main.enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table associated with this VPC"
  value       = aws_vpc.main.main_route_table_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "vpc_default_security_group_id" {
  description = "ID of the security group created by default on VPC creation"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_default_route_table_id" {
  description = "ID of the default route table"
  value       = aws_vpc.main.default_route_table_id
}

output "vpc_owner_id" {
  description = "ID of the AWS account that owns the VPC"
  value       = aws_vpc.main.owner_id
}

#####################################################################################################
# Internet Gateway Outputs
#####################################################################################################

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].id, null)
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].arn, null)
}

#####################################################################################################
# Subnet Outputs
#####################################################################################################

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = try(aws_db_subnet_group.database[0].id, null)
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = try(aws_db_subnet_group.database[0].name, null)
}

#####################################################################################################
# Route Table Outputs
#####################################################################################################

output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = aws_route_table.database[*].id
}

#####################################################################################################
# NAT Gateway Outputs
#####################################################################################################

output "nat_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs associated with the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "natgw_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

#####################################################################################################
# VPC Endpoint Outputs
#####################################################################################################

output "vpc_endpoint_s3_id" {
  description = "ID of VPC endpoint for S3"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "vpc_endpoint_s3_prefix_list_id" {
  description = "Prefix list ID of VPC endpoint for S3"
  value       = try(aws_vpc_endpoint.s3[0].prefix_list_id, null)
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of VPC endpoint for DynamoDB"
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

output "vpc_endpoint_dynamodb_prefix_list_id" {
  description = "Prefix list ID of VPC endpoint for DynamoDB"
  value       = try(aws_vpc_endpoint.dynamodb[0].prefix_list_id, null)
}

#####################################################################################################
# Network ACL Outputs
#####################################################################################################

output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = try(aws_network_acl.public[0].id, null)
}

output "public_network_acl_arn" {
  description = "ARN of the public network ACL"
  value       = try(aws_network_acl.public[0].arn, null)
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = try(aws_network_acl.private[0].id, null)
}

output "private_network_acl_arn" {
  description = "ARN of the private network ACL"
  value       = try(aws_network_acl.private[0].arn, null)
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = try(aws_network_acl.database[0].id, null)
}

output "database_network_acl_arn" {
  description = "ARN of the database network ACL"
  value       = try(aws_network_acl.database[0].arn, null)
}

#####################################################################################################
# Availability Zone Outputs
#####################################################################################################

output "azs" {
  description = "List of availability zones names or IDs in the region"
  value       = data.aws_availability_zones.available.names
}

#####################################################################################################
# Additional Useful Outputs
#####################################################################################################

output "name_prefix" {
  description = "Name prefix used for resource naming"
  value       = var.name_prefix
}

output "tags" {
  description = "A map of tags assigned to the VPC"
  value       = aws_vpc.main.tags
}

output "region" {
  description = "AWS region where the VPC is created"
  value       = data.aws_region.current.name
}

#####################################################################################################
# Security Outputs
#####################################################################################################

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = try(aws_flow_log.vpc[0].id, null)
}

output "vpc_flow_log_destination_arn" {
  description = "ARN of the destination for VPC Flow Log"
  value       = try(aws_flow_log.vpc[0].log_destination, null)
}