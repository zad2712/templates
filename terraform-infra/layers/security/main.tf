# =============================================================================
# SECURITY LAYER - IAM, Security Groups, KMS, WAF, and Security Infrastructure
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {}
}

# =============================================================================
# DATA SOURCES - Import networking layer outputs
# =============================================================================

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "networking/${var.environment}/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}

# =============================================================================
# KMS KEYS
# =============================================================================

module "kms" {
  source = "../../modules/kms"

  name        = "${var.project_name}-${var.environment}"
  description = "KMS keys for ${var.environment} environment"
  
  keys = var.kms_keys
  
  tags = local.common_tags
}

# =============================================================================
# IAM ROLES AND POLICIES
# =============================================================================

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  
  # Application roles
  application_roles = var.application_roles
  
  # Service roles (EC2, Lambda, ECS, etc.)
  service_roles = var.service_roles
  
  tags = local.common_tags
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

module "security_groups" {
  source = "../../modules/security-groups"

  name   = var.project_name
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

  security_groups = var.security_groups

  tags = local.common_tags
}

# =============================================================================
# AWS WAF (Optional)
# =============================================================================

module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "../../modules/waf"

  name        = "${var.project_name}-${var.environment}"
  description = "WAF for ${var.environment} environment"
  
  scope = var.waf_scope # CLOUDFRONT or REGIONAL
  
  # WAF rules configuration
  rules = var.waf_rules
  
  tags = local.common_tags
}

# =============================================================================
# AWS SECRETS MANAGER
# =============================================================================

module "secrets" {
  count  = length(var.secrets) > 0 ? 1 : 0
  source = "../../modules/secrets-manager"

  secrets    = var.secrets
  kms_key_id = module.kms.keys["general"].id
  
  tags = local.common_tags
}

# =============================================================================
# AWS CERTIFICATE MANAGER
# =============================================================================

module "acm" {
  count  = var.enable_ssl_certificates ? 1 : 0
  source = "../../modules/acm"

  domain_names = var.domain_names
  
  # Route53 zone for validation (optional)
  zone_id = var.route53_zone_id
  
  tags = local.common_tags
}
