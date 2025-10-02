# =============================================================================
# COMPUTE LAYER - QA ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "qa"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-qa"

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
instance_type = "t3.small"
key_pair_name = ""

asg_min_size = 1
asg_max_size = 3
asg_desired_capacity = 2

user_data_script = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from QA Environment</h1>" > /var/www/html/index.html
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
enable_container_insights = true

# Lambda Configuration
lambda_functions = {}

# EKS Configuration
enable_eks = true
eks_cluster_version = "1.30"

# Cluster endpoint configuration (QA environment - balanced security)
eks_endpoint_private_access = true
eks_endpoint_public_access = true
eks_endpoint_public_access_cidrs = ["10.0.0.0/8", "172.16.0.0/12"]  # More restrictive than dev

# Logging configuration (more comprehensive than dev)
eks_cluster_log_types = ["api", "audit", "authenticator"]
eks_log_retention_days = 14

# Encryption
eks_encryption_enabled = true
eks_kms_key_id = ""  # Will use default AWS managed key

# Node groups configuration (scaled for QA testing)
eks_node_groups = {
  general = {
    ami_type        = "AL2_x86_64"
    instance_types  = ["t3.medium", "t3.large"]
    capacity_type   = "SPOT"  # Cost optimization
    disk_size       = 30
    desired_size    = 2
    max_size        = 5
    min_size        = 1
    max_unavailable_percentage = 25
    labels = {
      role = "general"
      environment = "qa"
    }
    taints = []
  }
}

# Fargate profiles for QA workloads
eks_fargate_profiles = {
  testing = {
    selectors = [
      {
        namespace = "qa-testing"
        labels = {
          compute-type = "fargate"
        }
      }
    ]
  }
}

# EKS Addons
eks_addons = {
  vpc-cni = {
    addon_version = "v1.18.1-eksbuild.1"
  }
  coredns = {
    addon_version = "v1.11.1-eksbuild.4"
  }
  kube-proxy = {
    addon_version = "v1.30.0-eksbuild.2"
  }
  aws-ebs-csi-driver = {
    addon_version = "v1.30.0-eksbuild.1"
  }
}

# Marketplace Addons (comprehensive for QA testing)
enable_aws_load_balancer_controller = true
aws_load_balancer_controller_chart_version = "1.8.1"
aws_load_balancer_controller_namespace = "kube-system"

enable_cluster_autoscaler = true
cluster_autoscaler_chart_version = "9.37.0"
cluster_autoscaler_namespace = "kube-system"

enable_metrics_server = true
metrics_server_chart_version = "3.12.1"
metrics_server_namespace = "kube-system"

enable_aws_node_termination_handler = true  # Enable for stability testing
enable_external_dns = false  # Configure as needed
external_dns_domain_name = ""

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "qa"
  CostCenter  = "Engineering"
}
