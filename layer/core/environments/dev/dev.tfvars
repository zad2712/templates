#####################################################################################################
# Development Environment Configuration
# Optimized for cost and development flexibility
#####################################################################################################

# General Configuration
environment  = "dev"
project_name = "salesforce-app"
aws_region   = "us-east-1"

# VPC Configuration - Development optimized with single NAT Gateway
vpc_cidr_block = "10.0.0.0/16"

# Subnet Configuration (2 AZs for development)
public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

# DNS Configuration
enable_dns_hostnames = true
enable_dns_support   = true

# NAT Gateway Configuration (Cost-optimized for dev)
enable_nat_gateway = true
single_nat_gateway = true  # Single NAT Gateway to reduce costs

# Internet Gateway
create_igw                = true
map_public_ip_on_launch  = true

# Database Configuration
create_database_subnet_group = true
create_database_route_table  = true

# Security Configuration (Basic for development)
enable_flow_log                = false  # Disabled to reduce costs
flow_log_traffic_type         = "ALL"
manage_default_security_group = true
create_network_acls          = false   # Disabled for development

# Cost Optimization
enable_s3_endpoint       = true
enable_dynamodb_endpoint = true

# Advanced Configuration
secondary_cidr_blocks               = []
enable_ipv6                        = false
assign_ipv6_address_on_creation    = false
instance_tenancy                   = "default"

# Development-specific tagging
vpc_additional_tags = {
  "cost-center"         = "development"
  "auto-shutdown"       = "true"
  "backup-required"     = "false"
  "monitoring-level"    = "basic"
}

vpc_tags = {
  "environment-type" = "development"
  "cost-optimized"   = "true"
}

public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
  "subnet-tier"            = "public"
  "internet-access"        = "direct"
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "subnet-tier"                     = "private" 
  "internet-access"                 = "nat"
}

database_subnet_tags = {
  "subnet-tier"     = "database"
  "internet-access" = "none"
  "data-tier"       = "development"
}