# Example: Minimal Landing Zone Configuration
# This example shows the minimum configuration needed for a basic landing zone

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Minimal Landing Zone Module
module "aws_landing_zone_minimal" {
  source = "../../"

  # Required variables only
  environment       = "dev"
  organization_name = "mycompany"

  # Optional: Override defaults if needed
  vpc_cidr = "10.1.0.0/16"
  
  # Enable only essential features
  enable_nat_gateway   = false  # Save costs in dev
  enable_cloudtrail    = false  # Minimal setup
  enable_config        = false  # Minimal setup
  enable_guardduty     = false  # Minimal setup
  enable_backup_vault  = false  # Minimal setup
  
  # Minimal monitoring
  enable_cloudwatch_alarms = false
}

output "vpc_id" {
  value = module.aws_landing_zone_minimal.vpc_id
}

output "private_subnet_ids" {
  value = module.aws_landing_zone_minimal.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.aws_landing_zone_minimal.public_subnet_ids
}