# =============================================================================
# NETWORKING LAYER - VPC, Subnets, Gateways, and Network Infrastructure
# =============================================================================

terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  backend "s3" {}
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Layer       = "networking"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# =============================================================================
# VPC MODULE
# =============================================================================

module "vpc" {
  source = "../../modules/vpc"

  name                = "${var.project_name}-${var.environment}"
  cidr                = var.vpc_cidr
  availability_zones  = var.availability_zones
  
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  database_subnets    = var.database_subnets
  
  enable_nat_gateway  = var.enable_nat_gateway
  enable_vpn_gateway  = var.enable_vpn_gateway
  enable_dns_hostnames = true
  enable_dns_support  = true
  
  tags = local.common_tags
}

# =============================================================================
# VPC ENDPOINTS (Optional)
# =============================================================================

module "vpc_endpoints" {
  count  = var.enable_vpc_endpoints ? 1 : 0
  source = "../../modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  
  endpoints = var.vpc_endpoints
  
  tags = local.common_tags
}

# =============================================================================
# TRANSIT GATEWAY (Optional for multi-VPC connectivity)
# =============================================================================

module "transit_gateway" {
  count  = var.enable_transit_gateway ? 1 : 0
  source = "../../modules/transit-gateway"

  name        = "${var.project_name}-${var.environment}-tgw"
  description = "Transit Gateway for ${var.environment} environment"
  
  vpc_attachments = {
    vpc = {
      vpc_id     = module.vpc.vpc_id
      subnet_ids = module.vpc.private_subnets
    }
  }
  
  tags = local.common_tags
}
