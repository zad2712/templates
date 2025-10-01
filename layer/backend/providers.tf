# AWS Provider Configuration for Backend Layer

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
      Layer      = "backend"
      ManagedBy  = "terraform"
      Project    = "salesforce-app"
    }
  }
}