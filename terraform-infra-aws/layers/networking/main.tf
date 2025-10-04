# AWS Networking Infrastructure Main Configuration
# Author: Diego A. Zarate

# Data sources for existing resources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
    Type = "vpc"
  })
}

# DHCP Options Set
resource "aws_vpc_dhcp_options" "main" {
  count = var.enable_dhcp_options ? 1 : 0
  
  domain_name         = local.dhcp_options_domain_name
  domain_name_servers = ["AmazonProvidedDNS"]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-dhcp-options"
    Type = "dhcp-options"
  })
}

resource "aws_vpc_dhcp_options_association" "main" {
  count = var.enable_dhcp_options ? 1 : 0
  
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main[0].id
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.create_igw ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
    Type = "internet-gateway"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(local.public_subnets)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index % local.az_count]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${local.azs[count.index % local.az_count]}"
    Type = "public-subnet"
    Tier = "public"
    kubernetes.io/role/elb = "1"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(local.private_subnets)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index % local.az_count]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${local.azs[count.index % local.az_count]}"
    Type = "private-subnet"
    Tier = "private"
    kubernetes.io/role/internal-elb = "1"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count = length(local.database_subnets)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.database_subnets[count.index]
  availability_zone = local.azs[count.index % local.az_count]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-${local.azs[count.index % local.az_count]}"
    Type = "database-subnet"
    Tier = "database"
  })
}

# Management Subnets (optional)
resource "aws_subnet" "management" {
  count = length(local.management_subnets)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.management_subnets[count.index]
  availability_zone = local.azs[count.index % local.az_count]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-management-${local.azs[count.index % local.az_count]}"
    Type = "management-subnet"
    Tier = "management"
  })
}

# Cache Subnets (optional)
resource "aws_subnet" "cache" {
  count = length(local.cache_subnets)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cache_subnets[count.index]
  availability_zone = local.azs[count.index % local.az_count]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cache-${local.azs[count.index % local.az_count]}"
    Type = "cache-subnet"
    Tier = "cache"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
  
  domain = "vpc"
  
  depends_on = [aws_internet_gateway.main]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  depends_on = [aws_internet_gateway.main]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  count = var.create_igw ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
    Type = "route-table"
    Tier = "public"
  })
}

# Public Route to Internet Gateway
resource "aws_route" "public_internet" {
  count = var.create_igw ? 1 : 0
  
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 1
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
  })
}

# Private Routes to NAT Gateways
resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
  
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Database Route Table
resource "aws_route_table" "database" {
  count = length(local.database_subnets) > 0 ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-rt"
    Type = "route-table"
    Tier = "database"
  })
}

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = local.public_route_table_associations
  
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  for_each = local.private_route_table_associations
  
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

# Database Subnet Route Table Associations
resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  count = length(aws_subnet.database) > 0 ? 1 : 0
  
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
    Type = "db-subnet-group"
  })
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  count = length(aws_subnet.cache) > 0 ? 1 : 0
  
  name       = "${local.name_prefix}-cache-subnet-group"
  subnet_ids = aws_subnet.cache[*].id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cache-subnet-group"
    Type = "cache-subnet-group"
  })
}

# Security Groups
resource "aws_security_group" "main" {
  for_each = local.security_groups_to_create
  
  name_prefix = "${local.name_prefix}-${each.key}-"
  description = each.value.description
  vpc_id      = aws_vpc.main.id
  
  # Ingress rules
  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
  
  # Egress rules
  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-sg"
    Type = "security-group"
    Purpose = each.key
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Network ACLs
resource "aws_network_acl" "public" {
  count = length(var.network_acls) > 0 && contains(keys(var.network_acls), "public") ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  # Ingress rules
  dynamic "ingress" {
    for_each = try(var.network_acls.public.ingress_rules, [])
    content {
      rule_no    = ingress.value.rule_number
      protocol   = ingress.value.protocol
      action     = ingress.value.rule_action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }
  
  # Egress rules
  dynamic "egress" {
    for_each = try(var.network_acls.public.egress_rules, [])
    content {
      rule_no    = egress.value.rule_number
      protocol   = egress.value.protocol
      action     = egress.value.rule_action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-nacl"
    Type = "network-acl"
    Tier = "public"
  })
}

resource "aws_network_acl" "private" {
  count = length(var.network_acls) > 0 && contains(keys(var.network_acls), "private") ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  # Ingress rules
  dynamic "ingress" {
    for_each = try(var.network_acls.private.ingress_rules, [])
    content {
      rule_no    = ingress.value.rule_number
      protocol   = ingress.value.protocol
      action     = ingress.value.rule_action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }
  
  # Egress rules
  dynamic "egress" {
    for_each = try(var.network_acls.private.egress_rules, [])
    content {
      rule_no    = egress.value.rule_number
      protocol   = egress.value.protocol
      action     = egress.value.rule_action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-nacl"
    Type = "network-acl"
    Tier = "private"
  })
}

resource "aws_network_acl" "database" {
  count = length(var.network_acls) > 0 && contains(keys(var.network_acls), "database") ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  # Ingress rules
  dynamic "ingress" {
    for_each = try(var.network_acls.database.ingress_rules, [])
    content {
      rule_no    = ingress.value.rule_number
      protocol   = ingress.value.protocol
      action     = ingress.value.rule_action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }
  
  # Egress rules
  dynamic "egress" {
    for_each = try(var.network_acls.database.egress_rules, [])
    content {
      rule_no    = egress.value.rule_number
      protocol   = egress.value.protocol
      action     = egress.value.rule_action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-nacl"
    Type = "network-acl"
    Tier = "database"
  })
}

# Network ACL Associations
resource "aws_network_acl_association" "public" {
  for_each = local.public_nacl_associations
  
  network_acl_id = each.value.network_acl_id
  subnet_id      = each.value.subnet_id
}

resource "aws_network_acl_association" "private" {
  for_each = local.private_nacl_associations
  
  network_acl_id = each.value.network_acl_id
  subnet_id      = each.value.subnet_id
}

resource "aws_network_acl_association" "database" {
  for_each = local.database_nacl_associations
  
  network_acl_id = each.value.network_acl_id
  subnet_id      = each.value.subnet_id
}