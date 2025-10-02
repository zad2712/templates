# =============================================================================
# VPC MODULE OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# Subnet IDs
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = [for subnet in aws_subnet.database : subnet.id]
}

# Subnet CIDR blocks
output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.cidr_block]
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = [for subnet in aws_subnet.private : subnet.cidr_block]
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = [for subnet in aws_subnet.database : subnet.cidr_block]
}

# NAT Gateways
output "natgw_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = [for nat in aws_nat_gateway.main : nat.id]
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = [for eip in aws_eip.nat : eip.public_ip]
}

# Route Tables
output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = [aws_route_table.public.id]
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = [for rt in aws_route_table.private : rt.id]
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = length(aws_route_table.database) > 0 ? [aws_route_table.database[0].id] : []
}
