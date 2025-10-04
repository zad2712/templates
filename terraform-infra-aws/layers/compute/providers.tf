# =============================================================================
# COMPUTE LAYER PROVIDERS
# =============================================================================

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Layer       = "compute"
      ManagedBy   = "terraform"
    }
  }
}
