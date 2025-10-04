# =============================================================================
# COMPUTE LAYER - LOCAL VALUES
# =============================================================================

locals {
  # Environment and naming
  environment_config = {
    dev = {
      instance_types = ["t3.medium", "t3.large"]
      min_size      = 1
      max_size      = 3
      desired_size  = 1
    }
    qa = {
      instance_types = ["t3.large", "t3.xlarge"]
      min_size      = 1
      max_size      = 5
      desired_size  = 2
    }
    uat = {
      instance_types = ["t3.large", "t3.xlarge"]
      min_size      = 2
      max_size      = 10
      desired_size  = 3
    }
    prod = {
      instance_types = ["m5.large", "m5.xlarge", "m5.2xlarge"]
      min_size      = 3
      max_size      = 20
      desired_size  = 5
    }
  }

  # Current environment configuration
  current_env_config = local.environment_config[var.environment]

  # Common resource naming
  resource_names = {
    eks_cluster     = "${var.project_name}-${var.environment}-eks"
    ecs_cluster     = "${var.project_name}-${var.environment}-ecs"
    lambda_prefix   = "${var.project_name}-${var.environment}"
    api_gw_prefix   = "${var.project_name}-${var.environment}"
    alb_prefix      = "${var.project_name}-${var.environment}"
    cf_prefix       = "${var.project_name}-${var.environment}"
    batch_prefix    = "${var.project_name}-${var.environment}"
    eb_prefix       = "${var.project_name}-${var.environment}"
  }

  # Security group mappings from networking layer
  security_groups = {
    alb     = "application-load-balancer"
    ecs     = "ecs-service"
    lambda  = "lambda"
    batch   = "batch"
    web     = "web-tier"
  }

  # Default EKS node group configuration
  default_node_group_config = {
    instance_types = local.current_env_config.instance_types
    ami_type      = "AL2_x86_64"
    capacity_type = var.environment == "prod" ? "ON_DEMAND" : "SPOT"
    disk_size     = var.environment == "prod" ? 50 : 30
    
    scaling_config = {
      desired_size = local.current_env_config.desired_size
      max_size     = local.current_env_config.max_size
      min_size     = local.current_env_config.min_size
    }
    
    update_config = {
      max_unavailable_percentage = 25
    }
  }

  # Default ECS service configuration
  default_ecs_task_config = {
    network_mode            = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                     = var.environment == "prod" ? "1024" : "512"
    memory                  = var.environment == "prod" ? "2048" : "1024"
  }

  # Lambda runtime configurations
  lambda_runtimes = {
    python = "python3.11"
    nodejs = "nodejs18.x"
    java   = "java17"
    dotnet = "dotnet6"
    go     = "go1.x"
  }

  # Environment-specific Lambda configurations
  lambda_configs = {
    dev = {
      memory_size                = 128
      timeout                   = 30
      reserved_concurrent_executions = 10
      log_level                 = "DEBUG"
    }
    qa = {
      memory_size                = 256
      timeout                   = 60
      reserved_concurrent_executions = 25
      log_level                 = "INFO"
    }
    uat = {
      memory_size                = 512
      timeout                   = 300
      reserved_concurrent_executions = 50
      log_level                 = "INFO"
    }
    prod = {
      memory_size                = 1024
      timeout                   = 900
      reserved_concurrent_executions = 100
      log_level                 = "WARN"
    }
  }

  # Current Lambda configuration
  current_lambda_config = local.lambda_configs[var.environment]

  # API Gateway configurations
  api_gateway_configs = {
    throttling = {
      rate_limit  = var.environment == "prod" ? 10000 : 1000
      burst_limit = var.environment == "prod" ? 20000 : 2000
    }
    
    caching = {
      enabled = var.environment == "prod" ? true : false
      ttl     = var.environment == "prod" ? 300 : 0
    }
  }

  # CloudFront configurations
  cloudfront_configs = {
    dev = {
      price_class                = "PriceClass_100"
      minimum_protocol_version   = "TLSv1.2_2021"
      default_ttl               = 300
      max_ttl                   = 3600
    }
    qa = {
      price_class                = "PriceClass_200"
      minimum_protocol_version   = "TLSv1.2_2021"
      default_ttl               = 3600
      max_ttl                   = 86400
    }
    uat = {
      price_class                = "PriceClass_200"
      minimum_protocol_version   = "TLSv1.2_2021"
      default_ttl               = 3600
      max_ttl                   = 86400
    }
    prod = {
      price_class                = "PriceClass_All"
      minimum_protocol_version   = "TLSv1.2_2021"
      default_ttl               = 86400
      max_ttl                   = 31536000
    }
  }

  # Current CloudFront configuration
  current_cloudfront_config = local.cloudfront_configs[var.environment]

  # Auto Scaling configurations
  auto_scaling_configs = {
    dev = {
      scale_up_cooldown    = 300
      scale_down_cooldown  = 300
      target_cpu_utilization = 70
    }
    qa = {
      scale_up_cooldown    = 300
      scale_down_cooldown  = 600
      target_cpu_utilization = 70
    }
    uat = {
      scale_up_cooldown    = 180
      scale_down_cooldown  = 600
      target_cpu_utilization = 60
    }
    prod = {
      scale_up_cooldown    = 60
      scale_down_cooldown  = 300
      target_cpu_utilization = 50
    }
  }

  # Current Auto Scaling configuration
  current_auto_scaling_config = local.auto_scaling_configs[var.environment]

  # Health check configurations
  health_check_configs = {
    alb = {
      healthy_threshold   = 2
      unhealthy_threshold = 5
      timeout            = 5
      interval           = 30
      path               = "/health"
      matcher            = "200,202"
      protocol           = "HTTP"
    }
    
    api_gateway = {
      timeout_seconds = 29
    }
    
    lambda = {
      timeout = var.environment == "prod" ? 900 : 300
    }
  }

  # Logging configurations
  logging_configs = {
    retention_days = {
      dev  = 7
      qa   = 14
      uat  = 30
      prod = 90
    }
    
    log_levels = {
      dev  = "DEBUG"
      qa   = "INFO"
      uat  = "INFO"
      prod = "WARN"
    }
  }

  # Monitoring and alerting configurations
  monitoring_configs = {
    enable_detailed_monitoring = var.environment == "prod" ? true : false
    enable_container_insights  = true
    enable_x_ray_tracing      = var.environment != "dev"
    
    cloudwatch_dashboard = var.environment == "prod" ? true : false
    
    sns_notifications = var.environment == "prod" ? true : false
  }

  # Backup and disaster recovery configurations
  backup_configs = {
    enable_automated_backups = var.environment == "prod" ? true : false
    backup_retention_days   = var.environment == "prod" ? 30 : 7
    enable_cross_region_backup = var.environment == "prod" ? true : false
  }

  # Network configurations
  network_configs = {
    enable_nat_gateway     = var.environment == "prod" ? true : false
    enable_vpc_endpoints   = var.environment == "prod" ? true : false
    enable_flow_logs       = var.environment == "prod" ? true : false
  }

  # Security configurations
  security_configs = {
    enable_waf                    = var.environment != "dev"
    enable_shield_advanced        = var.environment == "prod"
    enable_guardduty             = var.environment == "prod"
    enable_config_rules          = var.environment == "prod"
    enable_cloudtrail            = true
    enable_secrets_rotation      = var.environment == "prod"
    
    # Encryption settings
    encryption_at_rest          = true
    encryption_in_transit       = true
    kms_key_rotation           = var.environment == "prod"
    
    # Network security
    restrict_ssh_access        = true
    enable_vpc_flow_logs       = var.environment == "prod"
    
    # Container security
    enable_image_scanning      = true
    enable_runtime_protection  = var.environment == "prod"
  }

  # Cost optimization configurations
  cost_optimization_configs = {
    enable_spot_instances     = var.environment != "prod"
    enable_scheduled_scaling  = var.environment == "prod"
    enable_rightsizing       = var.environment == "prod"
    
    # Storage optimization
    enable_intelligent_tiering = var.environment == "prod"
    enable_lifecycle_policies  = true
    
    # Compute optimization
    enable_auto_scaling       = true
    enable_predictive_scaling = var.environment == "prod"
  }

  # Performance configurations
  performance_configs = {
    enable_accelerated_networking = var.environment == "prod"
    enable_enhanced_networking   = var.environment == "prod"
    enable_placement_groups      = var.environment == "prod"
    
    # Caching configurations
    enable_elasticache          = var.environment != "dev"
    enable_cloudfront_caching   = true
    enable_api_gateway_caching  = var.environment == "prod"
  }
}