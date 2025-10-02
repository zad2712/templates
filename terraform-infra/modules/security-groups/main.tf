# =============================================================================
# SECURITY GROUPS MODULE
# =============================================================================

terraform {
  required_version = ">= 1.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

resource "aws_security_group" "security_groups" {
  for_each = var.security_groups

  name_prefix = lookup(each.value, "name_prefix", null)
  name        = lookup(each.value, "name", null)
  description = lookup(each.value, "description", "Managed by Terraform")
  vpc_id      = var.vpc_id

  # Revoke default egress rule if specified
  revoke_rules_on_delete = lookup(each.value, "revoke_rules_on_delete", false)

  tags = merge(var.tags, lookup(each.value, "tags", {}), {
    Name = coalesce(
      lookup(each.value, "name", null),
      "${lookup(each.value, "name_prefix", each.key)}"
    )
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# SECURITY GROUP INGRESS RULES
# =============================================================================

resource "aws_security_group_rule" "ingress_rules" {
  for_each = local.ingress_rules

  type              = "ingress"
  security_group_id = aws_security_group.security_groups[each.value.security_group].id

  # Rule configuration
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = lookup(each.value, "description", null)

  # Source configuration (mutually exclusive)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks        = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids         = lookup(each.value, "prefix_list_ids", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                    = lookup(each.value, "self", null)
}

# =============================================================================
# SECURITY GROUP EGRESS RULES
# =============================================================================

resource "aws_security_group_rule" "egress_rules" {
  for_each = local.egress_rules

  type              = "egress"
  security_group_id = aws_security_group.security_groups[each.value.security_group].id

  # Rule configuration
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = lookup(each.value, "description", null)

  # Destination configuration (mutually exclusive)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks        = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids         = lookup(each.value, "prefix_list_ids", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                    = lookup(each.value, "self", null)
}

# =============================================================================
# LOCALS FOR RULE PROCESSING
# =============================================================================

locals {
  # Flatten ingress rules
  ingress_rules = merge([
    for sg_name, sg_config in var.security_groups : {
      for rule_index, rule in lookup(sg_config, "ingress_rules", []) : "${sg_name}-ingress-${rule_index}" => merge(rule, {
        security_group = sg_name
      })
    }
  ]...)

  # Flatten egress rules
  egress_rules = merge([
    for sg_name, sg_config in var.security_groups : {
      for rule_index, rule in lookup(sg_config, "egress_rules", []) : "${sg_name}-egress-${rule_index}" => merge(rule, {
        security_group = sg_name
      })
    }
  ]...)
}
