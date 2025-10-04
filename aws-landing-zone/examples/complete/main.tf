# Example: Complete Landing Zone Configuration
# This example demonstrates a complete AWS Landing Zone setup with all features enabled

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
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AWS Landing Zone"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Landing Zone Module
module "aws_landing_zone" {
  source = "../"

  # Basic Configuration
  environment       = var.environment
  organization_name = var.organization_name
  aws_region       = var.aws_region

  # Network Configuration
  vpc_cidr               = "10.0.0.0/16"
  private_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs    = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnet_cidrs  = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Security Configuration
  enable_flow_logs            = true
  flow_logs_retention_days    = 14
  enable_cloudtrail           = true
  cloudtrail_retention_days   = 90
  enable_config               = true
  enable_guardduty            = true
  enable_security_hub         = true

  # Monitoring Configuration
  enable_cloudwatch_alarms = true
  sns_email_endpoints      = ["admin@yourcompany.com", "security@yourcompany.com"]

  # Cost Management
  cost_center                   = "IT-Infrastructure"
  budget_limit                  = 500
  budget_threshold_percentage   = 80

  # Backup Configuration
  enable_backup_vault     = true
  backup_retention_days   = 30

  # KMS Configuration
  kms_key_deletion_window = 10

  # Additional Tags
  additional_tags = {
    Project     = "Landing Zone"
    Owner       = "Platform Team"
    Department  = "IT"
    CreatedBy   = "terraform"
  }
}

# Example outputs for other modules to use
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.aws_landing_zone.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.aws_landing_zone.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.aws_landing_zone.public_subnet_ids
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = module.aws_landing_zone.database_subnet_ids
}

output "security_group_web_id" {
  description = "ID of the web security group"
  value       = module.aws_landing_zone.web_security_group_id
}

output "security_group_app_id" {
  description = "ID of the application security group"
  value       = module.aws_landing_zone.application_security_group_id
}

output "security_group_db_id" {
  description = "ID of the database security group"
  value       = module.aws_landing_zone.database_security_group_id
}