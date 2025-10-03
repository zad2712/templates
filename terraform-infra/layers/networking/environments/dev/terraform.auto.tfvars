# =============================================================================
# NETWORKING LAYER - DEV ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "dev"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"

# VPC Configuration
vpc_cidr           = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnets Configuration
public_subnets   = ["10.10.0.0/24", "10.10.64.0/24"]
private_subnets  = ["10.10.128.0/24", "10.10.192.0/24"]
database_subnets = ["10.10.240.0/28", "10.10.240.16/28"]

# Network Features
enable_nat_gateway      = true
enable_vpn_gateway      = false
enable_vpc_endpoints    = false
enable_transit_gateway  = false

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "dev"
  CostCenter  = "Engineering"
}
