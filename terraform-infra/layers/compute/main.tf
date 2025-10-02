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
# APPLICATION LOAD BALANCER
# =============================================================================

module "alb" {
  count  = var.enable_load_balancer ? 1 : 0
  source = "../../modules/alb"

  name     = "${var.project_name}-${var.environment}"
  vpc_id   = data.terraform_remote_state.networking.outputs.vpc_id
  subnets  = data.terraform_remote_state.networking.outputs.public_subnets

  # Security groups
  security_groups = [
    data.terraform_remote_state.security.outputs.security_group_ids["alb"]
  ]

  # Target groups configuration
  target_groups = var.target_groups

  # Listeners configuration
  listeners = var.alb_listeners

  # SSL certificate
  certificate_arn = var.ssl_certificate_arn

  tags = local.common_tags
}

# =============================================================================
# AUTO SCALING GROUP WITH LAUNCH TEMPLATE
# =============================================================================

module "asg" {
  count  = var.enable_auto_scaling ? 1 : 0
  source = "../../modules/asg"

  name = "${var.project_name}-${var.environment}"

  # Launch template configuration
  launch_template = {
    name_prefix   = "${var.project_name}-${var.environment}-"
    image_id      = var.ami_id
    instance_type = var.instance_type
    key_name      = var.key_pair_name
    
    vpc_security_group_ids = [
      data.terraform_remote_state.security.outputs.security_group_ids["ec2"]
    ]
    
    iam_instance_profile = data.terraform_remote_state.security.outputs.service_roles["ec2"].instance_profile_name
    
    user_data = base64encode(var.user_data_script)
    
    block_device_mappings = var.ebs_volumes
  }

  # Auto Scaling configuration
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  
  vpc_zone_identifier = data.terraform_remote_state.networking.outputs.private_subnets
  
  # Target group ARNs for ALB integration
  target_group_arns = var.enable_load_balancer ? [module.alb[0].target_group_arns["app"]] : []

  # Health check configuration
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tags = local.common_tags
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
