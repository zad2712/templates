# VPC Module - Main Configuration
# Author: Diego A. Zarate

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.tags,
    var.vpc_tags,
    {
      Name = var.name
      Type = "vpc"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DHCP Options Set
resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers         = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type   = var.dhcp_options_netbios_node_type

  tags = merge(
    var.tags,
    var.dhcp_options_tags,
    {
      Name = "${var.name}-dhcp-options"
      Type = "dhcp-options"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DHCP Options Association
resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  count = var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    var.igw_tags,
    {
      Name = "${var.name}-igw"
      Type = "internet-gateway"
    }
  )

  depends_on = [aws_vpc.this]
}

# Virtual Private Gateway
resource "aws_vpn_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id          = aws_vpc.this.id
  amazon_side_asn = var.amazon_side_asn

  tags = merge(
    var.tags,
    var.vpn_gateway_tags,
    {
      Name = "${var.name}-vpn-gateway"
      Type = "vpn-gateway"
    }
  )
}

# VPN Gateway Attachment
resource "aws_vpn_gateway_attachment" "this" {
  count = var.vpn_gateway_id != "" ? 1 : 0

  vpc_id         = aws_vpc.this.id
  vpn_gateway_id = var.vpn_gateway_id
}

# VPN Gateway Route Propagation
resource "aws_vpn_gateway_route_propagation" "public" {
  count = var.propagate_public_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? 1 : 0

  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this[*].id,
      [var.vpn_gateway_id]
    ),
    0
  )
  route_table_id = element(aws_route_table.public[*].id, count.index)
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.propagate_private_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.private_subnets) : 0

  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this[*].id,
      [var.vpn_gateway_id]
    ),
    0
  )
  route_table_id = element(aws_route_table.private[*].id, count.index)
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                          = aws_vpc.this.id
  cidr_block                      = var.public_subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = var.public_subnet_assign_ipv6_address_on_creation
  ipv6_cidr_block                 = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    var.tags,
    var.public_subnet_tags,
    lookup(var.public_subnet_tags_per_az, element(var.azs, count.index), {}),
    {
      Name = try(
        var.public_subnet_names[count.index],
        format("${var.name}-public-${element(var.azs, count.index)}")
      )
      Type = "public-subnet"
      Tier = "public"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id                          = aws_vpc.this.id
  cidr_block                      = var.private_subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  assign_ipv6_address_on_creation = var.private_subnet_assign_ipv6_address_on_creation
  ipv6_cidr_block                 = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    var.tags,
    var.private_subnet_tags,
    lookup(var.private_subnet_tags_per_az, element(var.azs, count.index), {}),
    {
      Name = try(
        var.private_subnet_names[count.index],
        format("${var.name}-private-${element(var.azs, count.index)}")
      )
      Type = "private-subnet"
      Tier = "private"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}