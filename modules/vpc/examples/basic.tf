#####################################################################################################
# Basic VPC Example
# Demonstrates the simplest usage of the VPC module
#####################################################################################################

terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = "vpc-example"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Basic VPC module usage
module "vpc" {
  source = "../"  # Path to the VPC module

  name_prefix = "basic-example"
  cidr_block  = "10.0.0.0/16"

  # Simple subnet configuration
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  # Basic NAT Gateway setup
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost-effective for development

  # Basic tagging
  common_tags = {
    Environment = var.environment
    Example     = "basic"
  }
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "nat_gateway_ips" {
  description = "Public IPs of NAT Gateways"
  value       = module.vpc.nat_public_ips
}