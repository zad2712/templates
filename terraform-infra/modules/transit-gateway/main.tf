# =============================================================================
# TRANSIT GATEWAY MODULE
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

# =============================================================================
# TRANSIT GATEWAY
# =============================================================================

resource "aws_ec2_transit_gateway" "main" {
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  auto_accept_shared_associations = var.auto_accept_shared_associations
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  dns_support                     = var.dns_support
  vpn_ecmp_support               = var.vpn_ecmp_support

  tags = merge(var.tags, {
    Name = var.transit_gateway_name
  })
}

# =============================================================================
# TRANSIT GATEWAY VPC ATTACHMENTS
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachments" {
  for_each = var.vpc_attachments

  subnet_ids         = each.value.subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id            = each.value.vpc_id

  dns_support                                     = lookup(each.value, "dns_support", true)
  ipv6_support                                   = lookup(each.value, "ipv6_support", false)
  appliance_mode_support                         = lookup(each.value, "appliance_mode_support", "disable")
  transit_gateway_default_route_table_association = lookup(each.value, "transit_gateway_default_route_table_association", true)
  transit_gateway_default_route_table_propagation = lookup(each.value, "transit_gateway_default_route_table_propagation", true)

  tags = merge(var.tags, {
    Name = "${each.key}-tgw-attachment"
  })
}

# =============================================================================
# TRANSIT GATEWAY ROUTE TABLE
# =============================================================================

resource "aws_ec2_transit_gateway_route_table" "main" {
  count = var.create_transit_gateway_route_table ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.transit_gateway_name}-route-table"
  })
}

# =============================================================================
# TRANSIT GATEWAY ROUTES
# =============================================================================

resource "aws_ec2_transit_gateway_route" "routes" {
  for_each = var.transit_gateway_routes

  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_attachment_id  = lookup(each.value, "transit_gateway_attachment_id", null)
  blackhole                     = lookup(each.value, "blackhole", false)
  transit_gateway_route_table_id = var.create_transit_gateway_route_table ? aws_ec2_transit_gateway_route_table.main[0].id : var.transit_gateway_route_table_id
}

# =============================================================================
# TRANSIT GATEWAY ROUTE TABLE ASSOCIATIONS
# =============================================================================

resource "aws_ec2_transit_gateway_route_table_association" "vpc_associations" {
  for_each = var.route_table_associations

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attachments[each.key].id
  transit_gateway_route_table_id = var.create_transit_gateway_route_table ? aws_ec2_transit_gateway_route_table.main[0].id : var.transit_gateway_route_table_id
}

# =============================================================================
# TRANSIT GATEWAY ROUTE TABLE PROPAGATIONS
# =============================================================================

resource "aws_ec2_transit_gateway_route_table_propagation" "vpc_propagations" {
  for_each = var.route_table_propagations

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attachments[each.key].id
  transit_gateway_route_table_id = var.create_transit_gateway_route_table ? aws_ec2_transit_gateway_route_table.main[0].id : var.transit_gateway_route_table_id
}
