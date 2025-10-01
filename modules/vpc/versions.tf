#####################################################################################################
# AWS VPC Module - Provider Requirements and Version Constraints
# Terraform and provider version requirements for compatibility and security
#####################################################################################################

terraform {
  # Minimum required Terraform version
  required_version = ">= 1.3.0"

  # Required providers with version constraints
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }

  # Optional: Configure backend requirements
  # backend "s3" {}  # Uncomment and configure for remote state storage
}

# AWS Provider configuration is handled by the calling module/configuration
# This module does not configure the provider to allow flexibility
provider "aws" {
  # Provider configuration should be done in the root module
  # This ensures the module can be used with different provider configurations
  
  # Common provider features that enhance the module functionality:
  # - default_tags for consistent tagging across all resources
  # - ignore_tags for managing tags external to Terraform
  
  # Example configuration (to be implemented in root module):
  # region = var.aws_region
  # 
  # default_tags {
  #   tags = {
  #     ManagedBy   = "Terraform"
  #     Environment = var.environment
  #     Project     = var.project_name
  #   }
  # }
  #
  # ignore_tags {
  #   key_prefixes = ["kubernetes.io/", "k8s.io/"]
  # }
}