# AWS Provider Configuration for Data Layer

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
      Layer      = "data"
      ManagedBy  = "terraform"
      Project    = "salesforce-app"
    }
  }
}