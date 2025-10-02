# =============================================================================
# COMPUTE LAYER - EC2, Auto Scaling, Load Balancers, ECS, Lambda
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
# DATA SOURCES - Import other layers outputs
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

data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "security/${var.environment}/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}



# =============================================================================
# ECS CLUSTER (Optional)
# =============================================================================

module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"

  cluster_name = "${var.project_name}-${var.environment}"
  
  # Capacity providers
  capacity_providers = var.ecs_capacity_providers
  
  # Container insights
  container_insights = var.enable_container_insights

  tags = local.common_tags
}

# =============================================================================
# LAMBDA FUNCTIONS (Optional)
# =============================================================================

module "lambda" {
  count  = length(var.lambda_functions) > 0 ? 1 : 0
  source = "../../modules/lambda"

  functions = var.lambda_functions
  
  # VPC configuration for Lambda functions that need VPC access
  vpc_config = {
    subnet_ids         = data.terraform_remote_state.networking.outputs.private_subnets
    security_group_ids = [data.terraform_remote_state.security.outputs.security_group_ids["lambda"]]
  }

  # IAM role
  execution_role_arn = data.terraform_remote_state.security.outputs.service_roles["lambda"].arn

  tags = local.common_tags
}

# =============================================================================
# EKS CLUSTER (Optional)
# =============================================================================

module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "../../modules/eks"

  # Basic cluster configuration
  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.eks_cluster_version
  
  # Network configuration
  vpc_id         = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids     = data.terraform_remote_state.networking.outputs.private_subnets
  
  # Control plane configuration
  endpoint_private_access = var.eks_endpoint_private_access
  endpoint_public_access  = var.eks_endpoint_public_access
  
  # Public access CIDRs (restrict as needed)
  endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs
  
  # Logging configuration
  cluster_enabled_log_types    = var.eks_cluster_log_types
  cloudwatch_log_group_retention_in_days = var.eks_log_retention_days
  
  # Encryption configuration
  cluster_encryption_config_enabled = var.eks_encryption_enabled
  cluster_encryption_config_kms_key_id = var.eks_kms_key_id
  
  # Node groups configuration
  node_groups = var.eks_node_groups
  
  # Fargate profiles configuration  
  fargate_profiles = var.eks_fargate_profiles
  
  # EKS Addons configuration
  cluster_addons = var.eks_addons
  
  # Marketplace Addons configuration
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  enable_cluster_autoscaler           = var.enable_cluster_autoscaler
  enable_metrics_server               = var.enable_metrics_server
  enable_aws_node_termination_handler = var.enable_aws_node_termination_handler
  enable_external_dns                 = var.enable_external_dns
  
  # Load balancer controller configuration
  aws_load_balancer_controller_chart_version = var.aws_load_balancer_controller_chart_version
  aws_load_balancer_controller_namespace     = var.aws_load_balancer_controller_namespace
  
  # Cluster autoscaler configuration
  cluster_autoscaler_chart_version = var.cluster_autoscaler_chart_version
  cluster_autoscaler_namespace     = var.cluster_autoscaler_namespace
  
  # Metrics server configuration
  metrics_server_chart_version = var.metrics_server_chart_version
  metrics_server_namespace     = var.metrics_server_namespace
  
  # AWS Node Termination Handler configuration
  aws_node_termination_handler_chart_version = var.aws_node_termination_handler_chart_version
  aws_node_termination_handler_namespace     = var.aws_node_termination_handler_namespace
  
  # External DNS configuration
  external_dns_chart_version = var.external_dns_chart_version
  external_dns_namespace     = var.external_dns_namespace
  external_dns_domain_name   = var.external_dns_domain_name
  
  tags = local.common_tags
}

# =============================================================================
# API GATEWAY
# =============================================================================

module "api_gateway" {
  count  = var.enable_api_gateway ? 1 : 0
  source = "../../modules/api-gateway"

  api_name        = "${var.project_name}-${var.environment}-api"
  api_description = "REST API Gateway for ${var.project_name} ${var.environment} environment"
  stage_name      = var.api_gateway_stage_name

  # Endpoint configuration
  endpoint_types                   = var.api_gateway_endpoint_types
  disable_execute_api_endpoint     = var.api_gateway_disable_execute_api_endpoint
  binary_media_types              = var.api_gateway_binary_media_types
  minimum_compression_size        = var.api_gateway_minimum_compression_size

  # Security configuration
  api_policy = var.api_gateway_policy

  # Logging configuration
  enable_access_logging     = var.api_gateway_enable_access_logging
  enable_execution_logging  = var.api_gateway_enable_execution_logging
  log_retention_days       = var.api_gateway_log_retention_days

  # Performance configuration
  enable_xray_tracing      = var.api_gateway_enable_xray_tracing
  cache_cluster_enabled    = var.api_gateway_cache_cluster_enabled
  cache_cluster_size       = var.api_gateway_cache_cluster_size

  # Throttling configuration
  throttle_settings = var.api_gateway_throttle_settings

  # Stage variables
  stage_variables = var.api_gateway_stage_variables

  # API structure
  api_resources        = var.api_gateway_resources
  api_methods          = var.api_gateway_methods
  request_validators   = var.api_gateway_request_validators
  api_models          = var.api_gateway_models
  api_authorizers     = var.api_gateway_authorizers

  # Usage plans and API keys
  usage_plans        = var.api_gateway_usage_plans
  api_keys          = var.api_gateway_api_keys
  usage_plan_keys   = var.api_gateway_usage_plan_keys

  # Custom domain configuration
  domain_name              = var.api_gateway_domain_name
  certificate_arn          = var.api_gateway_certificate_arn
  domain_security_policy   = var.api_gateway_domain_security_policy
  domain_endpoint_types    = var.api_gateway_domain_endpoint_types
  base_path               = var.api_gateway_base_path

  # WAF integration
  waf_acl_arn = var.api_gateway_waf_acl_arn

  tags = local.common_tags
}
