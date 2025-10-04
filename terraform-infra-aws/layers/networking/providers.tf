# AWS Provider Configuration
# Author: Diego A. Zarate

terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {
    # Configuration loaded from backend.conf file
    # Example:
    # bucket         = "terraform-state-aws-infra-{environment}"
    # key            = "layers/networking/{environment}/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "terraform-state-lock-aws-infra-{environment}"
    # encrypt        = true
  }
}

# Primary AWS Provider
provider "aws" {
  region = var.aws_region
  
  # Default tags applied to all resources
  default_tags {
    tags = var.common_tags
  }
  
  # Assume role configuration (if needed)
  # assume_role {
  #   role_arn = var.assume_role_arn
  # }
}

# Secondary AWS Provider for cross-region resources (if needed)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  
  default_tags {
    tags = merge(var.common_tags, {
      Region = var.secondary_region
    })
  }
}

# AWS Provider for us-east-1 (for global resources like CloudFront, Route53)
provider "aws" {
  alias  = "global"
  region = "us-east-1"
  
  default_tags {
    tags = merge(var.common_tags, {
      Scope = "global"
    })
  }
}