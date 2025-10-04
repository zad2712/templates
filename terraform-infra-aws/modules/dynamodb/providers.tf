# Provider Configuration
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  # Provider configuration will be set by the root module
}

# Additional provider for cross-region global tables if needed
# This should be configured in the root module for specific use cases