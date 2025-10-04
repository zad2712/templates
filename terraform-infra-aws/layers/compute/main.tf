# =============================================================================
# COMPUTE LAYER - EKS, ECS, Lambda, API Gateway, and Application Services
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

# Configure AWS Provider
provider "aws" {
  # Provider configuration will be set by environment-specific backend configuration
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Layer       = "compute"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Data from other layers
  networking_outputs = data.terraform_remote_state.networking.outputs
  security_outputs   = data.terraform_remote_state.security.outputs
  data_outputs       = data.terraform_remote_state.data.outputs
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Current AWS region and account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Networking layer outputs
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}"
    key    = "networking/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

# Security layer outputs
data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}"
    key    = "security/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

# Data layer outputs
data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}"
    key    = "data/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

# =============================================================================
# EKS MODULE
# =============================================================================

module "eks" {
  count = var.enable_eks ? 1 : 0
  
  source = "../../modules/eks"

  # Basic Configuration
  cluster_name = "${local.name_prefix}-eks"
  cluster_version = var.eks_cluster_version

  # Network Configuration
  vpc_id     = local.networking_outputs.vpc_id
  subnet_ids = local.networking_outputs.private_subnet_ids

  # Control Plane Configuration
  cluster_endpoint_private_access = var.eks_cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.eks_cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks_cluster_endpoint_public_access_cidrs

  # Security Configuration
  cluster_service_role_arn = local.security_outputs.iam_role_arns["eks_cluster"]
  
  cluster_encryption_config = {
    provider_key_arn = local.security_outputs.kms_key_arns["application"]
    resources        = ["secrets"]
  }

  # Add-ons
  cluster_addons = var.eks_cluster_addons

  # Node Groups
  node_groups = {
    for node_group_key, node_group in var.eks_node_groups : node_group_key => merge(node_group, {
      node_role_arn = local.security_outputs.iam_role_arns["eks_node_group"]
      subnet_ids    = local.networking_outputs.private_subnet_ids
      
      # Launch template configuration
      launch_template = merge(
        lookup(node_group, "launch_template", {}),
        {
          # User data for node group
          user_data = base64encode(templatefile("${path.module}/user-data/eks-node-userdata.sh", {
            cluster_name        = "${local.name_prefix}-eks"
            cluster_endpoint    = module.eks[0].cluster_endpoint
            cluster_ca_data     = module.eks[0].cluster_certificate_authority_data
            bootstrap_arguments = lookup(node_group, "bootstrap_arguments", "")
          }))
        }
      )
    })
  }

  # Fargate Profiles
  fargate_profiles = var.eks_fargate_profiles

  # OIDC Identity Provider
  enable_oidc_provider = var.eks_enable_oidc_provider
  
  # Logging
  cluster_enabled_log_types = var.eks_cluster_log_types
  cloudwatch_log_group_retention_in_days = var.log_retention_days
  cloudwatch_log_group_kms_key_id = local.security_outputs.kms_key_ids["logs"]

  tags = local.common_tags
}

# =============================================================================
# ECS MODULE (Alternative to EKS)
# =============================================================================

module "ecs" {
  count = var.enable_ecs ? 1 : 0
  
  source = "../../modules/ecs"

  # Basic Configuration
  cluster_name = "${local.name_prefix}-ecs"

  # Capacity Providers
  capacity_providers = var.ecs_capacity_providers
  
  default_capacity_provider_strategy = var.ecs_default_capacity_provider_strategy

  # Container Insights
  container_insights = var.ecs_enable_container_insights ? "enabled" : "disabled"

  # Service Configuration
  services = {
    for service_key, service in var.ecs_services : service_key => merge(service, {
      # Task Definition
      task_definition = merge(service.task_definition, {
        execution_role_arn = local.security_outputs.iam_role_arns["ecs_task_execution"]
        task_role_arn     = local.security_outputs.iam_role_arns["ecs_task"]
        
        # Container definitions with logging
        container_definitions = jsonencode([
          for container in service.task_definition.containers : merge(container, {
            logConfiguration = {
              logDriver = "awslogs"
              options = {
                "awslogs-group"         = local.security_outputs.cloudwatch_log_group_names["ecs"]
                "awslogs-region"        = data.aws_region.current.name
                "awslogs-stream-prefix" = "ecs"
              }
            }
            
            # Secrets from Secrets Manager
            secrets = [
              for secret_key, secret_arn in lookup(container, "secrets", {}) : {
                name      = secret_key
                valueFrom = secret_arn
              }
            ]
          })
        ])
      })
      
      # Network Configuration
      network_configuration = {
        subnets          = local.networking_outputs.private_subnet_ids
        security_groups  = [local.networking_outputs.security_group_ids["ecs"]]
        assign_public_ip = false
      }
      
      # Load Balancer Configuration
      load_balancers = lookup(service, "load_balancer", null) != null ? [
        {
          target_group_arn = module.alb[service.load_balancer.alb_key].target_group_arns[service.load_balancer.target_group_key]
          container_name   = service.load_balancer.container_name
          container_port   = service.load_balancer.container_port
        }
      ] : []
    })
  }

  tags = local.common_tags
}

# =============================================================================
# APPLICATION LOAD BALANCER
# =============================================================================

module "alb" {
  for_each = var.application_load_balancers
  
  source = "../../modules/alb"

  # Basic Configuration
  name = "${local.name_prefix}-${each.key}-alb"
  
  load_balancer_type = "application"
  scheme            = each.value.scheme
  
  # Network Configuration
  vpc_id  = local.networking_outputs.vpc_id
  subnets = each.value.scheme == "internet-facing" ? 
            local.networking_outputs.public_subnet_ids : 
            local.networking_outputs.private_subnet_ids

  security_groups = [local.networking_outputs.security_group_ids["alb"]]

  # SSL Configuration
  certificate_arn = each.value.certificate_arn

  # Target Groups
  target_groups = each.value.target_groups

  # Listeners
  listeners = each.value.listeners

  # Access Logs
  enable_access_logs = true
  access_logs_bucket = local.data_outputs.s3_bucket_names["access-logs"]
  access_logs_prefix = "alb/${each.key}"

  # WAF Association
  web_acl_arn = var.enable_waf ? local.security_outputs.waf_web_acl_arns["application"] : null

  tags = local.common_tags
}

# =============================================================================
# LAMBDA MODULE
# =============================================================================

module "lambda" {
  source = "../../modules/lambda"

  name_prefix = local.name_prefix

  # Lambda Functions
  functions = {
    for function_key, function in var.lambda_functions : function_key => merge(function, {
      # IAM Configuration
      role_arn = local.security_outputs.iam_role_arns["lambda_execution"]
      
      # Network Configuration (if VPC access is needed)
      vpc_config = lookup(function, "vpc_config", null) != null ? {
        subnet_ids         = local.networking_outputs.private_subnet_ids
        security_group_ids = [local.networking_outputs.security_group_ids["lambda"]]
      } : null
      
      # Environment Variables
      environment_variables = merge(
        lookup(function, "environment_variables", {}),
        {
          LOG_LEVEL = var.lambda_log_level
          REGION    = data.aws_region.current.name
        }
      )
      
      # KMS Encryption
      kms_key_arn = local.security_outputs.kms_key_arns["lambda"]
      
      # CloudWatch Logs
      cloudwatch_logs_retention_in_days = var.log_retention_days
      cloudwatch_logs_kms_key_id = local.security_outputs.kms_key_ids["logs"]
    })
  }

  # Lambda Layers
  layers = var.lambda_layers

  # Event Source Mappings
  event_source_mappings = var.lambda_event_source_mappings

  # Function URLs
  function_urls = var.lambda_function_urls

  tags = local.common_tags
}

# =============================================================================
# API GATEWAY MODULE
# =============================================================================

module "api_gateway" {
  count = var.enable_api_gateway ? 1 : 0
  
  source = "../../modules/api-gateway"

  name_prefix = local.name_prefix

  # REST APIs
  rest_apis = var.api_gateway_rest_apis

  # HTTP APIs
  http_apis = var.api_gateway_http_apis

  # Custom Domains
  rest_api_custom_domains = var.api_gateway_rest_custom_domains
  http_api_custom_domains = var.api_gateway_http_custom_domains

  # VPC Links
  vpc_links = var.api_gateway_vpc_links

  # CloudWatch Logging
  enable_cloudwatch_logs = true
  log_retention_days     = var.log_retention_days
  log_kms_key_id        = local.security_outputs.kms_key_ids["logs"]

  tags = local.common_tags
}

# =============================================================================
# AUTO SCALING GROUPS (for ECS EC2 capacity provider)
# =============================================================================

module "ecs_asg" {
  for_each = var.enable_ecs ? var.ecs_auto_scaling_groups : {}
  
  source = "../../modules/asg"

  # Basic Configuration
  name = "${local.name_prefix}-${each.key}-ecs-asg"

  # Launch Template Configuration
  launch_template = {
    name_prefix   = "${local.name_prefix}-${each.key}-ecs-"
    image_id      = each.value.ami_id
    instance_type = each.value.instance_type
    key_name      = each.value.key_name
    
    vpc_security_group_ids = [local.networking_outputs.security_group_ids["ecs"]]
    
    iam_instance_profile = {
      name = aws_iam_instance_profile.ecs_instance_profile[each.key].name
    }
    
    user_data = base64encode(templatefile("${path.module}/user-data/ecs-userdata.sh", {
      cluster_name = module.ecs[0].cluster_name
    }))
    
    block_device_mappings = [
      {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = each.value.root_volume_size
          volume_type = "gp3"
          encrypted   = true
          kms_key_id  = local.security_outputs.kms_key_ids["application"]
        }
      }
    ]
    
    tag_specifications = [
      {
        resource_type = "instance"
        tags = merge(local.common_tags, {
          Name = "${local.name_prefix}-${each.key}-ecs-instance"
        })
      }
    ]
  }

  # Auto Scaling Group Configuration
  vpc_zone_identifier = local.networking_outputs.private_subnet_ids
  
  min_size         = each.value.min_size
  max_size         = each.value.max_size
  desired_capacity = each.value.desired_capacity

  # Scaling Policies
  scaling_policies = each.value.scaling_policies

  # Health Checks
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tags = local.common_tags
}

# IAM Instance Profile for ECS Instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  for_each = var.enable_ecs ? var.ecs_auto_scaling_groups : {}
  
  name = "${local.name_prefix}-${each.key}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role[each.key].name

  tags = local.common_tags
}

resource "aws_iam_role" "ecs_instance_role" {
  for_each = var.enable_ecs ? var.ecs_auto_scaling_groups : {}
  
  name = "${local.name_prefix}-${each.key}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  for_each = var.enable_ecs ? var.ecs_auto_scaling_groups : {}
  
  role       = aws_iam_role.ecs_instance_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# =============================================================================
# CLOUDFRONT DISTRIBUTION (for static content)
# =============================================================================

module "cloudfront" {
  for_each = var.cloudfront_distributions
  
  source = "../../modules/cloudfront"

  # Basic Configuration
  distribution_name = "${local.name_prefix}-${each.key}"
  
  # Origin Configuration
  origins = each.value.origins

  # Cache Behaviors
  default_cache_behavior = each.value.default_cache_behavior
  ordered_cache_behaviors = lookup(each.value, "ordered_cache_behaviors", [])

  # SSL Configuration
  viewer_certificate = each.value.viewer_certificate

  # Geographic Restrictions
  geo_restriction = lookup(each.value, "geo_restriction", null)

  # WAF Integration
  web_acl_id = var.enable_waf ? local.security_outputs.waf_web_acl_arns["application"] : null

  # Logging
  logging_config = {
    bucket          = "${local.data_outputs.s3_bucket_names["access-logs"]}.s3.amazonaws.com"
    prefix          = "cloudfront/${each.key}/"
    include_cookies = false
  }

  tags = local.common_tags
}

# =============================================================================
# ELASTIC BEANSTALK (Optional)
# =============================================================================

module "elastic_beanstalk" {
  for_each = var.elastic_beanstalk_applications
  
  source = "../../modules/elastic-beanstalk"

  # Application Configuration
  application_name = "${local.name_prefix}-${each.key}-app"
  application_description = each.value.description

  # Environment Configuration
  environments = {
    for env_key, env in each.value.environments : env_key => merge(env, {
      # Network Configuration
      vpc_id     = local.networking_outputs.vpc_id
      subnet_ids = local.networking_outputs.private_subnet_ids
      elb_subnets = local.networking_outputs.public_subnet_ids
      
      # Security Groups
      security_groups = [local.networking_outputs.security_group_ids["web"]]
      
      # IAM Roles
      instance_profile = local.security_outputs.iam_role_names["ecs_task"]
      service_role     = local.security_outputs.iam_role_names["ecs_task_execution"]
      
      # Monitoring
      enable_managed_actions = true
      preferred_start_time   = "Sun:10:00"
      update_level          = "minor"
      instance_refresh_enabled = true
    })
  }

  tags = local.common_tags
}

# =============================================================================
# BATCH COMPUTE ENVIRONMENTS (for batch processing)
# =============================================================================

module "batch" {
  for_each = var.batch_compute_environments
  
  source = "../../modules/batch"

  # Compute Environment Configuration
  compute_environment_name = "${local.name_prefix}-${each.key}-batch"
  
  compute_resources = merge(each.value.compute_resources, {
    # Network Configuration
    vpc_id  = local.networking_outputs.vpc_id
    subnets = local.networking_outputs.private_subnet_ids
    
    # Security Groups
    security_group_ids = [local.networking_outputs.security_group_ids["batch"]]
    
    # IAM Roles
    instance_role = aws_iam_instance_profile.batch_instance_profile[each.key].arn
    service_role  = aws_iam_role.batch_service_role[each.key].arn
    spot_iam_fleet_request_role = lookup(each.value.compute_resources, "type", "") == "EC2" && 
                                  lookup(each.value.compute_resources, "allocation_strategy", "") == "SPOT_CAPACITY_OPTIMIZED" ? 
                                  aws_iam_role.batch_spot_fleet_role[each.key].arn : null
  })

  # Job Queues
  job_queues = each.value.job_queues

  # Job Definitions
  job_definitions = each.value.job_definitions

  tags = local.common_tags
}

# IAM roles for AWS Batch
resource "aws_iam_role" "batch_service_role" {
  for_each = var.batch_compute_environments
  
  name = "${local.name_prefix}-${each.key}-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  for_each = var.batch_compute_environments
  
  role       = aws_iam_role.batch_service_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_instance_profile" "batch_instance_profile" {
  for_each = var.batch_compute_environments
  
  name = "${local.name_prefix}-${each.key}-batch-instance-profile"
  role = aws_iam_role.batch_instance_role[each.key].name
}

resource "aws_iam_role" "batch_instance_role" {
  for_each = var.batch_compute_environments
  
  name = "${local.name_prefix}-${each.key}-batch-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "batch_instance_role_policy" {
  for_each = var.batch_compute_environments
  
  role       = aws_iam_role.batch_instance_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Spot Fleet Role (if using spot instances)
resource "aws_iam_role" "batch_spot_fleet_role" {
  for_each = {
    for key, env in var.batch_compute_environments : key => env
    if lookup(env.compute_resources, "type", "") == "EC2" && 
       lookup(env.compute_resources, "allocation_strategy", "") == "SPOT_CAPACITY_OPTIMIZED"
  }
  
  name = "${local.name_prefix}-${each.key}-batch-spot-fleet-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "spotfleet.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "batch_spot_fleet_role_policy" {
  for_each = {
    for key, env in var.batch_compute_environments : key => env
    if lookup(env.compute_resources, "type", "") == "EC2" && 
       lookup(env.compute_resources, "allocation_strategy", "") == "SPOT_CAPACITY_OPTIMIZED"
  }
  
  role       = aws_iam_role.batch_spot_fleet_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRequestRole"
}