# =============================================================================
# VPC ENDPOINTS MODULE
# =============================================================================

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  # Map of endpoint configurations
  endpoint_configs = {
    s3 = {
      service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = var.route_table_ids
    }
    dynamodb = {
      service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = var.route_table_ids
    }
    ec2 = {
      service_name       = "com.amazonaws.${data.aws_region.current.name}.ec2"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    ssm = {
      service_name       = "com.amazonaws.${data.aws_region.current.name}.ssm"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    ssmmessages = {
      service_name       = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    ec2messages = {
      service_name       = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
  }

  # Filter endpoints based on what was requested
  endpoints_to_create = {
    for endpoint in var.endpoints : endpoint => local.endpoint_configs[endpoint]
    if contains(keys(local.endpoint_configs), endpoint)
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_region" "current" {}

# =============================================================================
# SECURITY GROUP FOR INTERFACE ENDPOINTS
# =============================================================================

resource "aws_security_group" "vpc_endpoints" {
  count = var.vpc_id != "" && length(var.endpoints) > 0 ? 1 : 0

  name_prefix = "vpc-endpoints-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "vpc-endpoints-sg"
  })
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

# =============================================================================
# VPC ENDPOINTS
# =============================================================================

resource "aws_vpc_endpoint" "endpoints" {
  for_each = local.endpoints_to_create

  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  # Gateway endpoints
  route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? each.value.route_table_ids : null

  # Interface endpoints
  subnet_ids         = each.value.vpc_endpoint_type == "Interface" ? each.value.subnet_ids : null
  security_group_ids = each.value.vpc_endpoint_type == "Interface" ? each.value.security_group_ids : null

  private_dns_enabled = each.value.vpc_endpoint_type == "Interface" ? true : null

  tags = merge(var.tags, {
    Name = "${each.key}-vpc-endpoint"
  })
}
