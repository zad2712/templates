# =============================================================================
# DATA LAYER PROVIDERS
# =============================================================================

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Layer       = "data"
      ManagedBy   = "terraform"
    }
  }
}
