#####################################################################################################
# Production VPC Example
# Demonstrates a production-ready VPC configuration with all security features enabled
#####################################################################################################

terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "my-application"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "platform-team"
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc-flow-logs"
    Environment = var.environment
  }
}

# IAM role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Production VPC with full security features
module "vpc" {
  source = "../"  # Path to the VPC module

  name_prefix = "${var.project_name}-${var.environment}"
  cidr_block  = "10.0.0.0/16"

  # Multi-AZ configuration for high availability
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  # High availability NAT Gateways (one per AZ)
  enable_nat_gateway = true
  single_nat_gateway = false

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Security features
  enable_flow_log                    = true
  flow_log_traffic_type              = "ALL"
  flow_log_cloudwatch_log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  flow_log_cloudwatch_iam_role_arn   = aws_iam_role.vpc_flow_logs.arn

  manage_default_security_group = true
  create_network_acls          = true

  # Database configuration
  create_database_subnet_group  = true
  create_database_route_table   = true

  # Cost optimization with VPC endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # Comprehensive tagging strategy
  common_tags = {
    Environment             = var.environment
    Project                 = var.project_name
    Owner                   = var.owner
    "backup:required"       = "true"
    "compliance:required"   = "true"
    "cost-center"          = "platform"
    "data-classification"   = "internal"
    "business-unit"        = "engineering"
  }

  vpc_tags = {
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
    "network.vpc/type" = "main"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"     = "1"
    "network.subnet/type"        = "public"
    "load-balancer.type"         = "external"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "network.subnet/type"             = "private"
    "load-balancer.type"              = "internal"
  }

  database_subnet_tags = {
    "network.subnet/type" = "database"
    "database.tier"       = "data"
  }
}

# Security Group for web tier (example)
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-sg"
    Environment = var.environment
    Tier        = "web"
  }
}

# Security Group for application tier (example)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for application tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
    Tier        = "application"
  }
}

# Security Group for database tier (example)
resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for database tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Environment = var.environment
    Tier        = "database"
  }
}

# Outputs
output "vpc_info" {
  description = "VPC information"
  value = {
    vpc_id     = module.vpc.vpc_id
    vpc_arn    = module.vpc.vpc_arn
    cidr_block = module.vpc.vpc_cidr_block
    region     = module.vpc.region
  }
}

output "subnets" {
  description = "Subnet information"
  value = {
    public_subnets   = module.vpc.public_subnets
    private_subnets  = module.vpc.private_subnets
    database_subnets = module.vpc.database_subnets
  }
}

output "connectivity" {
  description = "Connectivity information"
  value = {
    internet_gateway_id    = module.vpc.igw_id
    nat_gateway_ids        = module.vpc.nat_ids
    nat_gateway_public_ips = module.vpc.nat_public_ips
  }
}

output "security_groups" {
  description = "Security group IDs"
  value = {
    web_sg      = aws_security_group.web.id
    app_sg      = aws_security_group.app.id
    database_sg = aws_security_group.database.id
  }
}

output "vpc_endpoints" {
  description = "VPC endpoint information"
  value = {
    s3_endpoint       = module.vpc.vpc_endpoint_s3_id
    dynamodb_endpoint = module.vpc.vpc_endpoint_dynamodb_id
  }
}

output "database_subnet_group" {
  description = "Database subnet group information"
  value = {
    name = module.vpc.database_subnet_group_name
    id   = module.vpc.database_subnet_group
  }
}