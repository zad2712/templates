# =============================================================================
# COMPUTE LAYER LOCALS
# =============================================================================

locals {
  # Common tags for all resources in this layer
  common_tags = merge(var.common_tags, {
    Layer       = "compute"
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  })

  # Environment-specific compute configurations
  env_compute_config = {
    dev = {
      instance_type              = "t3.micro"
      asg_min_size               = 1
      asg_max_size               = 2
      asg_desired_capacity       = 1
      enable_detailed_monitoring = false
    }
    qa = {
      instance_type              = "t3.small"
      asg_min_size               = 1
      asg_max_size               = 3
      asg_desired_capacity       = 2
      enable_detailed_monitoring = false
    }
    uat = {
      instance_type              = "t3.medium"
      asg_min_size               = 2
      asg_max_size               = 4
      asg_desired_capacity       = 2
      enable_detailed_monitoring = true
    }
    prod = {
      instance_type              = "t3.large"
      asg_min_size               = 2
      asg_max_size               = 6
      asg_desired_capacity       = 3
      enable_detailed_monitoring = true
    }
  }

  # Current environment compute configuration
  current_compute_config = local.env_compute_config[var.environment]
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
