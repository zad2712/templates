# =============================================================================
# COMPUTE LAYER - PROD ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "prod"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-prod"

# Load Balancer Configuration
enable_load_balancer = true
ssl_certificate_arn = ""  # Add your SSL certificate ARN here

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
      type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
  https = {
    port     = 443
    protocol = "HTTPS"
    default_action = {
      type             = "forward"
      target_group_arn = "app"
    }
  }
}

# Auto Scaling Configuration
enable_auto_scaling = true
ami_id = ""  # Will use latest Amazon Linux 2
instance_type = "t3.large"
key_pair_name = ""

asg_min_size = 2
asg_max_size = 6
asg_desired_capacity = 3

user_data_script = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from Production Environment</h1>" > /var/www/html/index.html
EOF

ebs_volumes = [
  {
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
]

# ECS Configuration
enable_ecs = true
ecs_capacity_providers = ["FARGATE", "FARGATE_SPOT"]
enable_container_insights = true

# Lambda Configuration
lambda_functions = {}

# EKS Configuration - Production Environment
enable_eks = true
eks_cluster_version = "1.28"

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
    addon_version = "v1.15.1-eksbuild.1"
  }
  coredns = {
    addon_version = "v1.10.1-eksbuild.5"
  }
  kube-proxy = {
    addon_version = "v1.28.2-eksbuild.2"
  }
  aws-ebs-csi-driver = {
    addon_version = "v1.24.0-eksbuild.1"
  }
}

# Marketplace Addons (full production suite)
enable_aws_load_balancer_controller = true
aws_load_balancer_controller_chart_version = "1.6.2"
aws_load_balancer_controller_namespace = "kube-system"

enable_cluster_autoscaler = true
cluster_autoscaler_chart_version = "9.29.0"
cluster_autoscaler_namespace = "kube-system"

enable_metrics_server = true
metrics_server_chart_version = "3.11.0"
metrics_server_namespace = "kube-system"

enable_aws_node_termination_handler = true
enable_external_dns = true
external_dns_domain_name = "example.com"  # Production domain

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "prod"
  CostCenter  = "Engineering"
  Backup      = "Required"
  Compliance  = "SOC2"
}
