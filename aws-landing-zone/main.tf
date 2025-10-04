# AWS Landing Zone Main Configuration

# Local variables for common configurations
locals {
  common_tags = merge(
    {
      Environment      = var.environment
      Organization     = var.organization_name
      ManagedBy       = "Terraform"
      CreatedDate     = formatdate("YYYY-MM-DD", timestamp())
      CostCenter      = var.cost_center
    },
    var.additional_tags
  )
  
  # Determine availability zones
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
  
  # Calculate number of AZs to use (max 3 for cost optimization)
  az_count = min(length(local.azs), 3)
  
  # Create subnet configurations
  private_subnets  = slice(var.private_subnet_cidrs, 0, local.az_count)
  public_subnets   = slice(var.public_subnet_cidrs, 0, local.az_count)
  database_subnets = slice(var.database_subnet_cidrs, 0, local.az_count)
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Random ID for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# KMS Key for encryption
resource "aws_kms_key" "landing_zone" {
  description             = "KMS key for ${var.organization_name} Landing Zone encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-kms-key"
  })
}

resource "aws_kms_alias" "landing_zone" {
  name          = "alias/${var.organization_name}-${var.environment}-landing-zone"
  target_key_id = aws_kms_key.landing_zone.key_id
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
    Tier = "Web"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
    Tier = "Application"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.database_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-database-subnet-${count.index + 1}"
    Type = "Database"
    Tier = "Data"
  })
}

# Database Subnet Group
resource "aws_db_subnet_group" "database" {
  name       = "${var.organization_name}-${var.environment}-database-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-database-subnet-group"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? local.az_count : 0

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? local.az_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-nat-gateway-${count.index + 1}"
  })
}

# Route Tables - Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-public-rt"
    Type = "Public"
  })
}

# Route Tables - Private
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? local.az_count : 1

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-private-rt-${count.index + 1}"
    Type = "Private"
  })
}

# Route Tables - Database
resource "aws_route_table" "database" {
  count = local.az_count

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-database-rt-${count.index + 1}"
    Type = "Database"
  })
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# Route Table Associations - Database
resource "aws_route_table_association" "database" {
  count = local.az_count

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

# VPN Gateway (optional)
resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-vpn-gateway"
  })
}

# VPN Gateway Route Propagation
resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.enable_vpn_gateway ? (var.enable_nat_gateway ? local.az_count : 1) : 0

  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

resource "aws_vpn_gateway_route_propagation" "database" {
  count = var.enable_vpn_gateway ? local.az_count : 0

  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = aws_route_table.database[count.index].id
}