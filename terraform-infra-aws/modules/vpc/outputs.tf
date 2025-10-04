# VPC Module Outputs
# Author: Diego A. Zarate

# VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = aws_vpc.this.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = aws_vpc.this.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = aws_vpc.this.instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = aws_vpc.this.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = aws_vpc.this.enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = aws_vpc.this.main_route_table_id
}

output "vpc_ipv6_association_id" {
  description = "The association ID for the IPv6 CIDR block"
  value       = try(aws_vpc.this.ipv6_association_id, null)
}

output "vpc_ipv6_cidr_block" {
  description = "The IPv6 CIDR block"
  value       = try(aws_vpc.this.ipv6_cidr_block, null)
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = []
}

output "vpc_owner_id" {
  description = "The ID of the AWS account that owns the VPC"
  value       = aws_vpc.this.owner_id
}

# DHCP Options Set
output "dhcp_options_id" {
  description = "The ID of the DHCP options"
  value       = try(aws_vpc_dhcp_options.this[0].id, null)
}

# Internet Gateway
output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = try(aws_internet_gateway.this[0].arn, null)
}

# VPN Gateway
output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = try(aws_vpn_gateway.this[0].id, null)
}

output "vgw_arn" {
  description = "The ARN of the VPN Gateway"
  value       = try(aws_vpn_gateway.this[0].arn, null)
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = compact(aws_subnet.private[*].cidr_block)
}

output "private_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of private subnets in an IPv6 enabled VPC"
  value       = compact(aws_subnet.private[*].ipv6_cidr_block)
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = compact(aws_subnet.public[*].cidr_block)
}

output "public_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of public subnets in an IPv6 enabled VPC"
  value       = compact(aws_subnet.public[*].ipv6_cidr_block)
}

# Database subnets
output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = []
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = []
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = []
}

output "database_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of database subnets in an IPv6 enabled VPC"
  value       = []
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = null
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = null
}

# Elasticache subnets
output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = []
}

output "elasticache_subnet_arns" {
  description = "List of ARNs of elasticache subnets"
  value       = []
}

output "elasticache_subnets_cidr_blocks" {
  description = "List of cidr_blocks of elasticache subnets"
  value       = []
}

output "elasticache_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of elasticache subnets in an IPv6 enabled VPC"
  value       = []
}

output "elasticache_subnet_group" {
  description = "ID of elasticache subnet group"
  value       = null
}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value       = null
}

# Intra subnets
output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = []
}

output "intra_subnet_arns" {
  description = "List of ARNs of intra subnets"
  value       = []
}

output "intra_subnets_cidr_blocks" {
  description = "List of cidr_blocks of intra subnets"
  value       = []
}

output "intra_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of intra subnets in an IPv6 enabled VPC"
  value       = []
}

# Route tables
output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = []
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = []
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = []
}

output "elasticache_route_table_ids" {
  description = "List of IDs of the elasticache route tables"
  value       = []
}

output "intra_route_table_ids" {
  description = "List of IDs of the intra route tables"
  value       = []
}

output "public_internet_gateway_route_id" {
  description = "ID of the internet gateway route"
  value       = null
}

output "public_internet_gateway_ipv6_route_id" {
  description = "ID of the IPv6 internet gateway route"
  value       = null
}

# NAT gateways
output "nat_ids" {
  description = "List of IDs of the NAT gateways"
  value       = []
}

output "nat_public_ips" {
  description = "List of public Elastic IPs associated with the NAT gateways"
  value       = []
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = []
}

# Egress-only Internet Gateway
output "egress_only_internet_gateway_id" {
  description = "The ID of the egress only Internet Gateway"
  value       = null
}

# VPC Endpoint for S3
output "vpc_endpoint_s3_id" {
  description = "The ID of VPC endpoint for S3"
  value       = null
}

output "vpc_endpoint_s3_pl_id" {
  description = "The prefix list for the S3 VPC endpoint"
  value       = null
}

# VPC Endpoint for DynamoDB
output "vpc_endpoint_dynamodb_id" {
  description = "The ID of VPC endpoint for DynamoDB"
  value       = null
}

output "vpc_endpoint_dynamodb_pl_id" {
  description = "The prefix list for the DynamoDB VPC endpoint"
  value       = null
}

# VPC flow log
output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = null
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = null
}

output "vpc_flow_log_destination_type" {
  description = "The type of the destination for VPC Flow Logs"
  value       = null
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN of the IAM role for publishing flow logs to CloudWatch Logs"
  value       = null
}

# Static values (arguments)
output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = var.azs
}

output "name" {
  description = "The name of the VPC specified as argument to this module"
  value       = var.name
}