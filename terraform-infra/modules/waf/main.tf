# =============================================================================
# WAF MODULE
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
# WAF WEB ACL
# =============================================================================

resource "aws_wafv2_web_acl" "main" {
  name  = var.name
  scope = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.key
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }
        
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }
        
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = lookup(rule.value, "managed_rule_group", null) != null ? [1] : []
          content {
            name        = rule.value.managed_rule_group.name
            vendor_name = rule.value.managed_rule_group.vendor_name
          }
        }
        
        dynamic "rate_based_statement" {
          for_each = lookup(rule.value, "rate_based_statement", null) != null ? [1] : []
          content {
            limit              = rule.value.rate_based_statement.limit
            aggregate_key_type = rule.value.rate_based_statement.aggregate_key_type
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = "${var.name}-${rule.key}"
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    metric_name                = var.name
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  tags = var.tags
}
