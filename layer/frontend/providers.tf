# AWS Provider Configuration for Frontend Layer

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment
      Layer      = "frontend"
      ManagedBy  = "terraform"
      Project    = "salesforce-app"
    }
  }
}