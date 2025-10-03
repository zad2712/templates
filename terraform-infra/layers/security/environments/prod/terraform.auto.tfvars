# =============================================================================
# SECURITY LAYER - PROD ENVIRONMENT CONFIGURATION
# =============================================================================

environment    = "prod"
project_name   = "myproject"
aws_region     = "us-east-1"
aws_profile    = "default"
state_bucket   = "myproject-terraform-state-prod"

# KMS Configuration
kms_keys = {
  general = {
    description = "General purpose KMS key for prod"
    deletion_window_in_days = 30
  }
  rds = {
    description = "KMS key for RDS encryption in prod"
    deletion_window_in_days = 30
  }
  s3 = {
    description = "KMS key for S3 encryption in prod"
    deletion_window_in_days = 30
  }
}

# IAM Configuration
service_roles = {
  ec2 = {
    service = "ec2"
    description = "EC2 instance role for prod"
    policy_arns = [
      "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    ]
  }
  lambda = {
    service = "lambda"
    description = "Lambda execution role for prod"
    policy_arns = [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    ]
  }
  rds-monitoring = {
    service = "monitoring.rds"
    description = "RDS Enhanced Monitoring role for prod"
    policy_arns = [
      "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
    ]
  }
}

# Security Groups Configuration
security_groups = {
  alb = {
    description = "Application Load Balancer security group"
    ingress = [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP access"
      },
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS access"
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }
  ec2 = {
    description = "EC2 instances security group"
    ingress = [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.40.0.0/16"]
        description = "HTTP from VPC"
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }
  rds = {
    description = "RDS database security group"
    ingress = [
      {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.40.0.0/16"]
        description = "MySQL from VPC"
      }
    ]
  }
  redis = {
    description = "ElastiCache Redis security group"
    ingress = [
      {
        from_port   = 6379
        to_port     = 6379
        protocol    = "tcp"
        cidr_blocks = ["10.40.0.0/16"]
        description = "Redis from VPC"
      }
    ]
  }
  lambda = {
    description = "Lambda functions security group"
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }
}

# WAF Configuration
enable_waf = true
waf_scope = "REGIONAL"



# Secrets Manager
secrets = {}

# Tags
common_tags = {
  Owner       = "DevOps Team"
  Project     = "MyProject"
  Environment = "prod"
  CostCenter  = "Engineering"
}
