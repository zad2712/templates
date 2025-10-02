# =============================================================================
# NETWORKING LAYER - PROD ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "prod"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"

# VPC Configuration
vpc_cidr           = "10.40.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Subnets Configuration
public_subnets   = ["10.40.0.0/24", "10.40.64.0/24", "10.40.128.0/24"]
private_subnets  = ["10.40.192.0/24", "10.40.224.0/24", "10.40.240.0/28"]
database_subnets = ["10.40.240.16/28", "10.40.240.32/28", "10.40.240.48/28"]

# Network Features
enable_nat_gateway      = true
enable_vpn_gateway      = false
enable_vpc_endpoints    = true
enable_transit_gateway  = true

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "prod"
  CostCenter  = "Engineering"
}
