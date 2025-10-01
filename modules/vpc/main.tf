#####################################################################################################
# AWS VPC Module - Main Configuration
# Following AWS Well-Architected Framework Principles
#####################################################################################################

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    local.common_tags,
    var.vpc_tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count  = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    local.common_tags,
    var.public_subnet_tags,
    {
      Name = "${var.name_prefix}-public-subnet-${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
      Type = "Public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common_tags,
    var.private_subnet_tags,
    {
      Name = "${var.name_prefix}-private-subnet-${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
      Type = "Private"
    }
  )
}

# Database Subnets
resource "aws_subnet" "database" {
  count             = length(var.database_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common_tags,
    var.database_subnet_tags,
    {
      Name = "${var.name_prefix}-db-subnet-${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
      Type = "Database"
    }
  )
}

# Database Subnet Group
resource "aws_db_subnet_group" "database" {
  count       = length(var.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0
  name        = "${var.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${var.name_prefix}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-db-subnet-group"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
    }
  )
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-nat-gateway-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    var.public_route_table_tags,
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )
}

# Public Route to Internet Gateway
resource "aws_route" "public_internet_gateway" {
  count                  = length(var.public_subnets) > 0 && var.create_igw ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  timeouts {
    create = "5m"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : length(var.private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    var.private_route_table_tags,
    {
      Name = var.single_nat_gateway ? "${var.name_prefix}-private-rt" : "${var.name_prefix}-private-rt-${count.index + 1}"
    }
  )
}

# Private Routes to NAT Gateway
resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id

  timeouts {
    create = "5m"
  }
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# Database Route Tables
resource "aws_route_table" "database" {
  count  = length(var.database_subnets) > 0 ? (var.create_database_route_table ? 1 : 0) : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    var.database_route_table_tags,
    {
      Name = "${var.name_prefix}-database-rt"
    }
  )
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  count          = length(var.database_subnets) > 0 && var.create_database_route_table ? length(var.database_subnets) : 0
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# VPC Flow Logs (Security Best Practice)
resource "aws_flow_log" "vpc" {
  count           = var.enable_flow_log ? 1 : 0
  iam_role_arn    = var.flow_log_cloudwatch_iam_role_arn
  log_destination = var.flow_log_cloudwatch_log_group_name
  traffic_type    = var.flow_log_traffic_type
  vpc_id          = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-vpc-flow-log"
    }
  )
}

# Default Security Group Rules (Security Best Practice)
resource "aws_default_security_group" "default" {
  count  = var.manage_default_security_group ? 1 : 0
  vpc_id = aws_vpc.main.id

  # Remove all default rules
  ingress = []
  egress  = []

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-default-sg"
    }
  )
}

# VPC Endpoint for S3 (Cost Optimization)
resource "aws_vpc_endpoint" "s3" {
  count           = var.enable_s3_endpoint ? 1 : 0
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = local.vpc_endpoint_route_table_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-s3-endpoint"
    }
  )
}

# VPC Endpoint for DynamoDB (Cost Optimization)
resource "aws_vpc_endpoint" "dynamodb" {
  count           = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids = local.vpc_endpoint_route_table_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-dynamodb-endpoint"
    }
  )
}

# Network ACLs for additional security
resource "aws_network_acl" "public" {
  count      = var.create_network_acls ? 1 : 0
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Allow inbound HTTP
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound HTTPS
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow inbound ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-public-nacl"
    }
  )
}

resource "aws_network_acl" "private" {
  count      = var.create_network_acls ? 1 : 0
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  # Allow inbound from VPC CIDR
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Allow inbound ephemeral ports from internet (for return traffic)
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-private-nacl"
    }
  )
}

resource "aws_network_acl" "database" {
  count      = var.create_network_acls && length(var.database_subnets) > 0 ? 1 : 0
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  # Allow inbound from VPC CIDR
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Allow outbound to VPC CIDR
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-database-nacl"
    }
  )
}