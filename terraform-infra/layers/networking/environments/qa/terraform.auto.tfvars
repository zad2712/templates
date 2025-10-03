# =============================================================================
# NETWORKING LAYER - QA ENVIRONMENT CONFIGURATION
# =============================================================================

environment  = "qa"
project_name = "myproject"
aws_region   = "us-east-1"
aws_profile  = "default"

# VPC Configuration
vpc_cidr           = "10.20.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnets Configuration
public_subnets   = ["10.20.0.0/24", "10.20.64.0/24"]
private_subnets  = ["10.20.128.0/24", "10.20.192.0/24"]
database_subnets = ["10.20.240.0/28", "10.20.240.16/28"]

# Network Features
enable_nat_gateway     = true
enable_vpn_gateway     = false
enable_vpc_endpoints   = false
enable_transit_gateway = false

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "qa"
  CostCenter  = "Engineering"
}
