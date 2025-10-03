# =============================================================================
# VPC MODULE - Main Implementation
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
  # Use provided AZs or fetch available ones
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, min(length(var.public_subnets), length(var.private_subnets)))

  # Create maps for subnets indexed by AZ for deterministic resource keys
  public_subnets_map = {
    for idx, cidr in var.public_subnets : idx => {
      cidr = cidr
      az   = local.azs[idx % length(local.azs)]
    }
  }

  private_subnets_map = {
    for idx, cidr in var.private_subnets : idx => {
      cidr = cidr
      az   = local.azs[idx % length(local.azs)]
    }
  }

  database_subnets_map = {
    for idx, cidr in var.database_subnets : idx => {
      cidr = cidr
      az   = local.azs[idx % length(local.azs)]
    }
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# =============================================================================
# VPC
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# =============================================================================
# INTERNET GATEWAY
# =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# =============================================================================
# PUBLIC SUBNETS
# =============================================================================

resource "aws_subnet" "public" {
  for_each = local.public_subnets_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.key}"
    Type = "public"
  })
}

# =============================================================================
# PRIVATE SUBNETS
# =============================================================================

resource "aws_subnet" "private" {
  for_each = local.private_subnets_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.key}"
    Type = "private"
  })
}

# =============================================================================
# DATABASE SUBNETS
# =============================================================================

resource "aws_subnet" "database" {
  for_each = local.database_subnets_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name}-database-${each.key}"
    Type = "database"
  })
}

# =============================================================================
# ELASTIC IPs FOR NAT GATEWAYS
# =============================================================================

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? local.public_subnets_map : {}

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-eip-${each.key}"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# NAT GATEWAYS
# =============================================================================

resource "aws_nat_gateway" "main" {
  for_each = var.enable_nat_gateway ? local.public_subnets_map : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# ROUTE TABLES
# =============================================================================

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

# Private Route Tables (one per NAT Gateway for HA)
resource "aws_route_table" "private" {
  for_each = var.enable_nat_gateway ? local.private_subnets_map : { for k, v in local.private_subnets_map : k => v }

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[each.key].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt-${each.key}"
  })
}

# Database Route Table
resource "aws_route_table" "database" {
  count = length(var.database_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-database-rt"
  })
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS
# =============================================================================

# Public subnet associations
resource "aws_route_table_association" "public" {
  for_each = local.public_subnets_map

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# Private subnet associations
resource "aws_route_table_association" "private" {
  for_each = local.private_subnets_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Database subnet associations
resource "aws_route_table_association" "database" {
  for_each = length(var.database_subnets) > 0 ? local.database_subnets_map : {}

  subnet_id      = aws_subnet.database[each.key].id
  route_table_id = aws_route_table.database[0].id
}

# =============================================================================
# VPC FLOW LOGS (Optional)
# =============================================================================

resource "aws_flow_log" "vpc" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn         = var.flow_logs_iam_role_arn
  log_destination      = var.flow_logs_s3_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}
