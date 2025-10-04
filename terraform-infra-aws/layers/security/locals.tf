# =============================================================================
# SECURITY LAYER LOCALS
# =============================================================================

locals {
  # Common tags for all resources in this layer
  common_tags = merge(var.common_tags, {
    Layer       = "security"
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  })

  # Environment-specific security configurations
  env_security_config = {
    dev = {
      enable_cloudtrail = false
      enable_config     = false
      enable_guardduty  = false
    }
    qa = {
      enable_cloudtrail = false
      enable_config     = false
      enable_guardduty  = false
    }
    uat = {
      enable_cloudtrail = true
      enable_config     = true
      enable_guardduty  = true
    }
    prod = {
      enable_cloudtrail = true
      enable_config     = true
      enable_guardduty  = true
    }
  }

  # Current environment security configuration
  current_security_config = local.env_security_config[var.environment]
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
