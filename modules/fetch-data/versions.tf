#####################################################################################################
# Fetch Data Module - Version Requirements
# Terraform and provider version constraints following best practices
#####################################################################################################

terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}