# =============================================================================
# COMPUTE LAYER - DEV ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "dev"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-dev"

# Load Balancer Configuration
enable_load_balancer = true
ssl_certificate_arn = ""

target_groups = {
  app = {
    port     = 80
    protocol = "HTTP"
    health_check = {
      enabled             = true
      healthy_threshold   = 2
      interval            = 30
      matcher             = "200"
      path                = "/"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 2
    }
  }
}

alb_listeners = {
  http = {
    port     = 80
    protocol = "HTTP"
    default_action = {
      type             = "forward"
      target_group_arn = "app"
    }
  }
}

# Auto Scaling Configuration
enable_auto_scaling = true
ami_id = ""  # Will use latest Amazon Linux 2
instance_type = "t3.micro"
key_pair_name = ""

asg_min_size = 1
asg_max_size = 2
asg_desired_capacity = 1

user_data_script = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from Dev Environment</h1>" > /var/www/html/index.html
EOF

ebs_volumes = [
  {
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
]

# ECS Configuration
enable_ecs = false
ecs_capacity_providers = ["FARGATE", "FARGATE_SPOT"]
enable_container_insights = false

# Lambda Configuration
lambda_functions = {}

# EKS Configuration
enable_eks = true
eks_cluster_version = "1.30"

# Cluster endpoint configuration (dev environment - more open for development)
eks_endpoint_private_access = true
eks_endpoint_public_access = true
eks_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Restrict this in production

# Logging configuration (minimal for cost optimization)
eks_cluster_log_types = ["api", "audit"]
eks_log_retention_days = 7

# Encryption
eks_encryption_enabled = true
eks_kms_key_id = ""  # Will use default AWS managed key

# Node groups configuration (optimized for dev workloads)
eks_node_groups = {
  general = {
    ami_type        = "AL2_x86_64"
    instance_types  = ["t3.small", "t3.medium"]
    capacity_type   = "SPOT"  # Cost optimization
    disk_size       = 20
    desired_size    = 1
    max_size        = 3
    min_size        = 1
    max_unavailable_percentage = 25
    labels = {
      role = "general"
      environment = "dev"
    }
    taints = []
  }
}

# Fargate profiles (optional - for specific workloads)
eks_fargate_profiles = {
  # system = {
  #   selectors = [
  #     {
  #       namespace = "kube-system"
  #       labels = {}
  #     }
  #   ]
  # }
}

# EKS Addons (Latest versions as of Oct 2025)
eks_addons = {
  vpc-cni = {
    addon_version = "v1.18.1-eksbuild.1"
  }
  coredns = {
    addon_version = "v1.11.1-eksbuild.4"
  }
  kube-proxy = {
    addon_version = "v1.28.8-eksbuild.2"
  }
  aws-ebs-csi-driver = {
    addon_version = "v1.30.0-eksbuild.1"
  }
}

# Marketplace Addons (Latest versions as of Oct 2025)
enable_aws_load_balancer_controller = true
aws_load_balancer_controller_chart_version = "1.8.1"
aws_load_balancer_controller_namespace = "kube-system"

enable_cluster_autoscaler = true
cluster_autoscaler_chart_version = "9.37.0"
cluster_autoscaler_namespace = "kube-system"

enable_metrics_server = true
metrics_server_chart_version = "3.12.1"
metrics_server_namespace = "kube-system"

enable_aws_node_termination_handler = false  # Not needed for dev
enable_external_dns = false  # Configure as needed
external_dns_domain_name = ""

# =============================================================================
# API GATEWAY CONFIGURATION
# =============================================================================

# Basic API Gateway for development
enable_api_gateway = true
api_gateway_stage_name = "dev"
api_gateway_endpoint_types = ["REGIONAL"]

# Development-friendly settings
api_gateway_enable_access_logging = true
api_gateway_enable_execution_logging = false
api_gateway_log_retention_days = 7
api_gateway_enable_xray_tracing = false
api_gateway_cache_cluster_enabled = false

# Basic throttling for development
api_gateway_throttle_settings = {
  rate_limit  = 100
  burst_limit = 200
}

# Stage variables for development
api_gateway_stage_variables = {
  environment = "dev"
  lambda_alias = "DEV"
}

# Basic API structure example
api_gateway_resources = {
  api = {
    path_part = "api"
  }
  health = {
    path_part = "health"
    parent_id = "api"
  }
}

# Basic health check method
api_gateway_methods = {
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
            "application/json" = "{\"status\": \"healthy\", \"environment\": \"dev\", \"timestamp\": \"$context.requestTime\"}"
          }
        }
      }
    }
  }
}

# Request validators
api_gateway_request_validators = {
  validate_body = {
    name                        = "validate-body-dev"
    validate_request_body       = true
    validate_request_parameters = false
  }
}

# Basic usage plan for development
api_gateway_usage_plans = {
  dev_plan = {
    name        = "Development Plan"
    description = "Development usage plan with higher limits for testing"
    
    api_stages = [{
      stage = "dev"
    }]
    
    quota_settings = {
      limit  = 50000
      period = "MONTH"
    }
    
    throttle_settings = {
      rate_limit  = 100
      burst_limit = 200
    }
  }
}

# API key for development
api_gateway_api_keys = {
  dev_key = {
    name        = "dev-api-key"
    description = "API key for development environment"
    enabled     = true
  }
}

# Associate API key with usage plan
api_gateway_usage_plan_keys = {
  dev_association = {
    api_key_name     = "dev_key"
    usage_plan_name  = "dev_plan"
  }
}

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "dev"
  CostCenter  = "Engineering"
}