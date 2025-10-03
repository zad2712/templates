# =============================================================================
# COMPUTE LAYER - PROD ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "prod"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-prod"



# ECS Configuration
enable_ecs = true
ecs_capacity_providers = ["FARGATE", "FARGATE_SPOT"]
enable_container_insights = true

# Lambda Configuration
lambda_functions = {}

# EKS Configuration - Production Environment
enable_eks = true
eks_cluster_version = "1.31"

# Cluster endpoint configuration (Production - high security)
eks_endpoint_private_access = true
eks_endpoint_public_access = false  # Private only for production
eks_endpoint_public_access_cidrs = []  # No public access

# Logging configuration (comprehensive production logging)
eks_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_log_retention_days = 90  # Extended retention for compliance

# Encryption
eks_encryption_enabled = true
eks_kms_key_id = ""  # Use dedicated production KMS key

# Node groups configuration (production-grade)
eks_node_groups = {
  general = {
    ami_type        = "AL2_x86_64"
    instance_types  = ["m5.large", "m5.xlarge"]
    capacity_type   = "ON_DEMAND"  # Stable for production
    disk_size       = 100
    desired_size    = 3
    max_size        = 10
    min_size        = 3
    max_unavailable_percentage = 25
    labels = {
      role = "general"
      environment = "prod"
    }
    taints = []
  },
  monitoring = {
    ami_type        = "AL2_x86_64"
    instance_types  = ["t3.medium"]
    capacity_type   = "ON_DEMAND"
    disk_size       = 50
    desired_size    = 2
    max_size        = 3
    min_size        = 1
    max_unavailable_percentage = 50
    labels = {
      role = "monitoring"
      environment = "prod"
    }
    taints = [
      {
        key    = "monitoring"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

# Fargate profiles for production workloads
eks_fargate_profiles = {
  system = {
    selectors = [
      {
        namespace = "kube-system"
        labels = {}
      }
    ]
  },
  production_apps = {
    selectors = [
      {
        namespace = "prod-apps"
        labels = {
          compute-type = "fargate"
        }
      }
    ]
  }
}

# EKS Addons - Production versions
eks_addons = {
  vpc-cni = {
    addon_version = "v1.18.1-eksbuild.1"
  }
  coredns = {
    addon_version = "v1.11.1-eksbuild.4"
  }
  kube-proxy = {
    addon_version = "v1.31.0-eksbuild.2"
  }
  aws-ebs-csi-driver = {
    addon_version = "v1.31.0-eksbuild.1"
  }
}

# Marketplace Addons (full production suite)
enable_aws_load_balancer_controller = true
aws_load_balancer_controller_chart_version = "1.8.1"
aws_load_balancer_controller_namespace = "kube-system"

enable_cluster_autoscaler = true
cluster_autoscaler_chart_version = "9.37.0"
cluster_autoscaler_namespace = "kube-system"

enable_metrics_server = true
metrics_server_chart_version = "3.12.1"
metrics_server_namespace = "kube-system"

enable_aws_node_termination_handler = true
enable_external_dns = true
external_dns_domain_name = "example.com"  # Production domain

# =============================================================================
# API GATEWAY CONFIGURATION - PRODUCTION
# =============================================================================

# Production API Gateway with full features
enable_api_gateway = true
api_gateway_stage_name = "v1"
api_gateway_endpoint_types = ["REGIONAL"]
api_gateway_disable_execute_api_endpoint = false  # Set to true if using custom domain only

# Production logging and monitoring
api_gateway_enable_access_logging = true
api_gateway_enable_execution_logging = false
api_gateway_log_retention_days = 90  # 3 months for compliance
api_gateway_enable_xray_tracing = true

# Performance optimization for production
api_gateway_cache_cluster_enabled = true
api_gateway_cache_cluster_size = "1.6"  # 1.6 GB cache for production

# Production throttling settings
api_gateway_throttle_settings = {
  rate_limit  = 1000
  burst_limit = 2000
}

# Stage variables for production
api_gateway_stage_variables = {
  environment = "prod"
  lambda_alias = "PROD"
  version = "1.0"
}

# Production API structure
api_gateway_resources = {
  api = {
    path_part = "api"
  }
  v1 = {
    path_part = "v1"
    parent_id = "api"
  }
  users = {
    path_part = "users"
    parent_id = "v1"
  }
  user_id = {
    path_part = "{user_id}"
    parent_id = "users"
  }
  orders = {
    path_part = "orders"
    parent_id = "v1"
  }
  order_id = {
    path_part = "{order_id}"
    parent_id = "orders"
  }
  health = {
    path_part = "health"
    parent_id = "api"
  }
}

# Production API methods with authentication
api_gateway_methods = {
  # Public health check
  health_check = {
    resource_key  = "health"
    http_method   = "GET"
    authorization = "NONE"
    
    integration = {
      type = "MOCK"
      request_templates = {
        "application/json" = "{\"statusCode\": 200}"
      }
    }
    
    responses = {
      "200" = {
        status_code = "200"
        response_models = {
          "application/json" = "Empty"
        }
        integration_response = {
          response_templates = {
            "application/json" = "{\"status\": \"healthy\", \"environment\": \"prod\", \"timestamp\": \"$context.requestTime\"}"
          }
        }
      }
    }
  }
  
  # Authenticated user endpoints would be configured here
  # get_users = {
  #   resource_key     = "users"
  #   http_method      = "GET"
  #   authorization    = "AWS_IAM"  # or COGNITO_USER_POOLS, CUSTOM
  #   api_key_required = true
  #   
  #   integration = {
  #     type = "AWS_PROXY"
  #     integration_http_method = "POST"
  #     uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${lambda_function_arn}/invocations"
  #   }
  #   
  #   responses = {
  #     "200" = {
  #       status_code = "200"
  #       integration_response = {}
  #     }
  #   }
  # }
}

# Request validation for production
api_gateway_request_validators = {
  validate_body = {
    name                        = "validate-body-prod"
    validate_request_body       = true
    validate_request_parameters = false
  }
  validate_params = {
    name                        = "validate-params-prod"
    validate_request_body       = false
    validate_request_parameters = true
  }
  validate_all = {
    name                        = "validate-all-prod"
    validate_request_body       = true
    validate_request_parameters = true
  }
}

# Production usage plans with tiered access
api_gateway_usage_plans = {
  basic_plan = {
    name        = "Basic Plan"
    description = "Basic production usage plan"
    
    api_stages = [{
      stage = "v1"
      throttle = {
        path        = "/*/*"
        rate_limit  = 100
        burst_limit = 200
      }
    }]
    
    quota_settings = {
      limit  = 10000
      period = "MONTH"
    }
    
    throttle_settings = {
      rate_limit  = 100
      burst_limit = 200
    }
  }
  
  premium_plan = {
    name        = "Premium Plan"
    description = "Premium production usage plan"
    
    api_stages = [{
      stage = "v1"
      throttle = {
        path        = "/*/*"
        rate_limit  = 1000
        burst_limit = 2000
      }
    }]
    
    quota_settings = {
      limit  = 100000
      period = "MONTH"
    }
    
    throttle_settings = {
      rate_limit  = 1000
      burst_limit = 2000
    }
  }
}

# Production API keys
api_gateway_api_keys = {
  client_basic = {
    name        = "client-basic-key"
    description = "Basic tier client API key"
    enabled     = true
  }
  client_premium = {
    name        = "client-premium-key"
    description = "Premium tier client API key"
    enabled     = true
  }
}

# Usage plan associations
api_gateway_usage_plan_keys = {
  basic_association = {
    api_key_name     = "client_basic"
    usage_plan_name  = "basic_plan"
  }
  premium_association = {
    api_key_name     = "client_premium"
    usage_plan_name  = "premium_plan"
  }
}

# Custom domain configuration (uncomment and configure as needed)
# api_gateway_domain_name = "api.example.com"
# api_gateway_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/example"
# api_gateway_domain_security_policy = "TLS_1_2"
# api_gateway_base_path = "v1"

# WAF integration for production security (uncomment and configure as needed)
# api_gateway_waf_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/api-waf/example"

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "prod"
  CostCenter  = "Engineering"
  Backup      = "Required"
  Compliance  = "SOC2"
}
