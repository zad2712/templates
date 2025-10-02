# =============================================================================
# NETWORKING LAYER LOCALS
# =============================================================================

locals {
  # Environment-specific configurations
  env_config = {
    dev = {
      nat_gateway_count = 1  # Single NAT for cost optimization in dev
      enable_flow_logs  = false
    }
    qa = {
      nat_gateway_count = 1
      enable_flow_logs  = false
    }
    uat = {
      nat_gateway_count = 2  # Multi-AZ for production-like testing
      enable_flow_logs  = true
    }
    prod = {
      nat_gateway_count = 2  # Multi-AZ for high availability
      enable_flow_logs  = true
    }
  }

  # Current environment configuration
  current_env = local.env_config[var.environment]

  # Availability zones - use provided or default to first 2 AZs in region
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  # Common tags for all resources in this layer
  common_tags = merge(var.common_tags, {
    Layer       = "networking"
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  })

  # VPC Flow Logs configuration
  flow_logs_config = local.current_env.enable_flow_logs ? {
    log_destination_type = "s3"
    log_destination      = "arn:aws:s3:::${var.project_name}-${var.environment}-vpc-flow-logs"
    log_format          = "$${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${windowstart} $${windowend} $${action}"
  } : {}
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
