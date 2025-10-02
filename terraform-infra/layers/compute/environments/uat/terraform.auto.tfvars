# =============================================================================
# COMPUTE LAYER - UAT ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "uat"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-uat"

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
instance_type = "t3.medium"
key_pair_name = ""

asg_min_size = 2
asg_max_size = 4
asg_desired_capacity = 2

user_data_script = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from UAT Environment</h1>" > /var/www/html/index.html
EOF

ebs_volumes = [
  {
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 30
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

# EKS Configuration
enable_eks = true
eks_cluster_version = "1.30"

# Cluster endpoint configuration (UAT environment - production-like security)
eks_endpoint_private_access = true
eks_endpoint_public_access = false  # More secure for UAT
eks_endpoint_public_access_cidrs = ["10.0.0.0/16"]  # Very restrictive

# Logging configuration (comprehensive)
eks_cluster_log_types = ["api", "audit", "authenticator", "controllerManager"]
eks_log_retention_days = 30

# Encryption
eks_encryption_enabled = true
eks_kms_key_id = ""  # Consider using custom KMS key for UAT

# Node groups configuration (production-like sizing)
eks_node_groups = {
  general = {
    ami_type        = "AL2_x86_64"
    instance_types  = ["t3.large", "t3.xlarge"]
    capacity_type   = "ON_DEMAND"  # More stable for UAT testing
    disk_size       = 50
    desired_size    = 2
    max_size        = 6
    min_size        = 2
    max_unavailable_percentage = 25
    labels = {
      role = "general"
      environment = "uat"
    }
    taints = []
  }
}

# Fargate profiles for UAT workloads
eks_fargate_profiles = {
  system = {
    selectors = [
      {
        namespace = "kube-system"
        labels = {}
      },
      {
        namespace = "uat-apps"
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

# Marketplace Addons (full production-like setup)
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
enable_external_dns = true  # Enable for UAT domain testing
external_dns_domain_name = "uat.example.com"

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "uat"
  CostCenter  = "Engineering"
}
