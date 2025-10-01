#####################################################################################################
# UAT Environment Configuration  
# Pre-production configuration with enhanced monitoring and security
#####################################################################################################

# General Configuration
environment  = "uat"
project_name = "salesforce-app"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr_block = "10.2.0.0/16"

# Subnet Configuration (3 AZs for high availability)
public_subnets   = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnets  = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
database_subnets = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]

# DNS Configuration
enable_dns_hostnames = true
enable_dns_support   = true

# NAT Gateway Configuration (Multi-AZ for reliability)
enable_nat_gateway = true
single_nat_gateway = false  # Multiple NAT Gateways for HA

# Internet Gateway
create_igw                = true
map_public_ip_on_launch  = true

# Database Configuration
create_database_subnet_group = true
create_database_route_table  = true

# Security Configuration (Enhanced for pre-production)
enable_flow_log                = true   # Enabled for monitoring
flow_log_traffic_type         = "ALL"
manage_default_security_group = true
create_network_acls          = false   # Disabled for UAT

# Cost Optimization
enable_s3_endpoint       = true
enable_dynamodb_endpoint = true

# Advanced Configuration
secondary_cidr_blocks               = []
enable_ipv6                        = false
assign_ipv6_address_on_creation    = false
instance_tenancy                   = "default"

# UAT-specific tagging
vpc_additional_tags = {
  "cost-center"         = "user-acceptance-testing"
  "auto-shutdown"       = "false"
  "backup-required"     = "true"
  "monitoring-level"    = "enhanced"
  "pre-production"      = "true"
  "compliance-required" = "true"
}

vpc_tags = {
  "environment-type" = "uat"
  "testing-tier"     = "user-acceptance"
  "compliance-zone"  = "pre-prod"
}

public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
  "subnet-tier"            = "public"
  "internet-access"        = "direct"
  "load-balancer-tier"     = "external"
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "subnet-tier"                     = "private"
  "internet-access"                 = "nat"
  "application-tier"                = "uat"
}

database_subnet_tags = {
  "subnet-tier"     = "database"
  "internet-access" = "none"
  "data-tier"       = "uat"
  "backup-required" = "true"
  "encryption-required" = "true"
}