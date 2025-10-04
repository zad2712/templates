# =============================================================================
# APPLICATION GATEWAY MODULE
# =============================================================================

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.sku_capacity
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = var.public_ip_id
  }

  backend_address_pool {
    name = "default-backend-pool"
  }

  backend_http_settings {
    name                  = "default-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "default-http-listener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "default-http-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-backend-http-settings"
    priority                   = 100
  }

  # WAF Configuration
  dynamic "waf_configuration" {
    for_each = var.waf_enabled ? [1] : []
    
    content {
      enabled          = true
      firewall_mode    = var.waf_mode
      rule_set_type    = "OWASP"
      rule_set_version = "3.2"
      
      disabled_rule_group {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rules           = [920300, 920440]
      }
    }
  }

  # Autoscale Configuration
  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscale ? [1] : []
    
    content {
      min_capacity = var.autoscale_min_capacity
      max_capacity = var.autoscale_max_capacity
    }
  }

  tags = var.tags
}

# WAF Policy (if using WAF_v2)
resource "azurerm_web_application_firewall_policy" "main" {
  count = var.waf_enabled && var.sku_tier == "WAF_v2" ? 1 : 0

  name                = "${var.name}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                       = var.waf_mode
    request_body_check         = true
    file_upload_limit_in_mb    = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}