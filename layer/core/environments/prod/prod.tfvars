#####################################################################################################
# Production Environment Configuration
# Full production setup with maximum security, monitoring, and high availability
#####################################################################################################

# General Configuration
environment  = "prod"
project_name = "salesforce-app"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr_block = "10.3.0.0/16"

# Subnet Configuration (3 AZs for maximum availability)
public_subnets   = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
private_subnets  = ["10.3.11.0/24", "10.3.12.0/24", "10.3.13.0/24"]
database_subnets = ["10.3.21.0/24", "10.3.22.0/24", "10.3.23.0/24"]

# DNS Configuration
enable_dns_hostnames = true
enable_dns_support   = true

# NAT Gateway Configuration (Multi-AZ for maximum availability)
enable_nat_gateway = true
single_nat_gateway = false  # Multiple NAT Gateways for HA

# Internet Gateway
create_igw                = true
map_public_ip_on_launch  = true

# Database Configuration
create_database_subnet_group = true
create_database_route_table  = true

# Security Configuration (Maximum security for production)
enable_flow_log                    = true   # Enabled for compliance
flow_log_traffic_type              = "ALL"
flow_log_cloudwatch_log_group_name = "/aws/vpc/flowlogs/salesforce-app-prod"
manage_default_security_group      = true
create_network_acls                = true   # Enabled for defense in depth

# Cost Optimization (with performance priority)
enable_s3_endpoint       = true
enable_dynamodb_endpoint = true

# Advanced Configuration
secondary_cidr_blocks               = []
enable_ipv6                        = false
assign_ipv6_address_on_creation    = false
instance_tenancy                   = "default"

# Production-specific tagging
vpc_additional_tags = {
  "cost-center"         = "production"
  "auto-shutdown"       = "false"
  "backup-required"     = "true"
  "monitoring-level"    = "maximum"
  "compliance-required" = "true"
  "business-critical"   = "true"
  "disaster-recovery"   = "enabled"
  "security-tier"       = "high"
}

vpc_tags = {
  "environment-type" = "production"
  "testing-tier"     = "none"
  "compliance-zone"  = "production"
  "business-impact"  = "critical"
}

public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
  "subnet-tier"            = "public"
  "internet-access"        = "direct"
  "load-balancer-tier"     = "external"
  "waf-enabled"            = "true"
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "subnet-tier"                     = "private"
  "internet-access"                 = "nat"
  "application-tier"                = "production"
  "auto-scaling"                    = "enabled"
}

database_subnet_tags = {
  "subnet-tier"         = "database"
  "internet-access"     = "none"
  "data-tier"           = "production"
  "backup-required"     = "true"
  "encryption-required" = "true"
  "multi-az"            = "enabled"
  "point-in-time-recovery" = "enabled"
}