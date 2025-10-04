terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.50.0"
    }
  }
  # Uncomment and configure for remote state backend (recommended)
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate1234"
  #   container_name       = "tfstate"
  #   key                  = "landing-zone/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_deleted_secrets_on_destroy = false
    }
  }
}

provider "azuread" {}
