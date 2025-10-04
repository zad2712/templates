# Output values for AWS Networking Layer
# Author: Diego A. Zarate

# VPC Outputs
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

# Internet Gateway Outputs
output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].id, null)
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].arn, null)
}

# Subnet Outputs
output "public_subnets" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnets" {
  description = "List of IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnets" {
  description = "List of IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of the database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "management_subnets" {
  description = "List of IDs of the management subnets"
  value       = aws_subnet.management[*].id
}

output "management_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the management subnets"
  value       = aws_subnet.management[*].cidr_block
}

output "cache_subnets" {
  description = "List of IDs of the cache subnets"
  value       = aws_subnet.cache[*].id
}

output "cache_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the cache subnets"
  value       = aws_subnet.cache[*].cidr_block
}

# NAT Gateway Outputs
output "nat_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs associated with the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

# Route Table Outputs
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

# Security Group Outputs
output "security_group_ids" {
  description = "Map of security group names to their IDs"
  value = {
    for name, sg in aws_security_group.main : name => sg.id
  }
}

output "security_groups" {
  description = "Map of security group names to their full objects"
  value = {
    for name, sg in aws_security_group.main : name => {
      id          = sg.id
      arn         = sg.arn
      name        = sg.name
      description = sg.description
    }
  }
}

# Network ACL Outputs
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

# Subnet Group Outputs
output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = try(aws_db_subnet_group.main[0].id, null)
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = try(aws_db_subnet_group.main[0].name, null)
}

output "database_subnet_group_arn" {
  description = "ARN of the database subnet group"
  value       = try(aws_db_subnet_group.main[0].arn, null)
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = try(aws_elasticache_subnet_group.main[0].name, null)
}

# Availability Zone Outputs
output "azs" {
  description = "List of availability zones used"
  value       = local.azs
}

# DHCP Options Outputs
output "dhcp_options_id" {
  description = "ID of the DHCP options"
  value       = try(aws_vpc_dhcp_options.main[0].id, null)
}

# Computed Values
output "vpc_cidr_block_associations" {
  description = "List of CIDR blocks associated with the VPC"
  value       = [aws_vpc.main.cidr_block]
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = length(aws_nat_gateway.main)
}

output "public_subnet_count" {
  description = "Number of public subnets created"
  value       = length(aws_subnet.public)
}

output "private_subnet_count" {
  description = "Number of private subnets created"
  value       = length(aws_subnet.private)
}

output "database_subnet_count" {
  description = "Number of database subnets created"
  value       = length(aws_subnet.database)
}

# Environment and Configuration Outputs
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

# Network Configuration Summary
output "network_summary" {
  description = "Summary of network configuration"
  value = {
    vpc_id              = aws_vpc.main.id
    vpc_cidr            = aws_vpc.main.cidr_block
    public_subnets      = aws_subnet.public[*].id
    private_subnets     = aws_subnet.private[*].id
    database_subnets    = aws_subnet.database[*].id
    nat_gateways        = aws_nat_gateway.main[*].id
    internet_gateway    = try(aws_internet_gateway.main[0].id, null)
    availability_zones  = local.azs
    environment        = var.environment
  }
}