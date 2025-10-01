#####################################################################################################
# QA Environment Configuration
# Balanced configuration for testing and quality assurance
#####################################################################################################

# General Configuration
environment  = "qa"
project_name = "salesforce-app"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr_block = "10.1.0.0/16"

# Subnet Configuration (2 AZs for QA)
public_subnets   = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]
database_subnets = ["10.1.21.0/24", "10.1.22.0/24"]

# DNS Configuration
enable_dns_hostnames = true
enable_dns_support   = true

# NAT Gateway Configuration (Cost-optimized but reliable)
enable_nat_gateway = true
single_nat_gateway = true  # Single NAT Gateway for QA

# Internet Gateway
create_igw                = true
map_public_ip_on_launch  = true

# Database Configuration
create_database_subnet_group = true
create_database_route_table  = true

# Security Configuration (Enhanced for testing)
enable_flow_log                = false  # Disabled to reduce costs
flow_log_traffic_type         = "ALL"
manage_default_security_group = true
create_network_acls          = false   # Disabled for QA

# Cost Optimization
enable_s3_endpoint       = true
enable_dynamodb_endpoint = true

# Advanced Configuration
secondary_cidr_blocks               = []
enable_ipv6                        = false
assign_ipv6_address_on_creation    = false
instance_tenancy                   = "default"

# QA-specific tagging
vpc_additional_tags = {
  "cost-center"         = "quality-assurance"
  "auto-shutdown"       = "true"
  "backup-required"     = "true"
  "monitoring-level"    = "enhanced"
  "testing-environment" = "true"
}

vpc_tags = {
  "environment-type" = "qa"
  "testing-tier"     = "integration"
}

public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
  "subnet-tier"            = "public"
  "internet-access"        = "direct"
  "load-testing"           = "enabled"
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "subnet-tier"                     = "private"
  "internet-access"                 = "nat"
  "application-tier"                = "testing"
}

database_subnet_tags = {
  "subnet-tier"     = "database"
  "internet-access" = "none"
  "data-tier"       = "qa"
  "backup-required" = "true"
}