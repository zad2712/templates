# =============================================================================
# AWS API Gateway Module Outputs
# =============================================================================
# This file defines all the outputs from the API Gateway module to expose
# important resource information for use in other modules or root configurations
# =============================================================================

# =============================================================================
# REST API Outputs
# =============================================================================

output "rest_apis" {
  description = "Map of all REST APIs with their detailed information"
  value = {
    for name, api in aws_api_gateway_rest_api.rest_apis : name => {
      id               = api.id
      name            = api.name
      description     = api.description
      arn             = api.arn
      execution_arn   = api.execution_arn
      root_resource_id = api.root_resource_id
      policy          = api.policy
      api_key_source  = api.api_key_source
      binary_media_types = api.binary_media_types
      minimum_compression_size = api.minimum_compression_size
      endpoint_configuration = api.endpoint_configuration
      created_date    = api.created_date
    }
  }
}

output "rest_api_ids" {
  description = "Map of REST API names to their IDs"
  value = {
    for name, api in aws_api_gateway_rest_api.rest_apis : name => api.id
  }
}

output "rest_api_execution_arns" {
  description = "Map of REST API names to their execution ARNs"
  value = {
    for name, api in aws_api_gateway_rest_api.rest_apis : name => api.execution_arn
  }
}

output "rest_api_root_resource_ids" {
  description = "Map of REST API names to their root resource IDs"
  value = {
    for name, api in aws_api_gateway_rest_api.rest_apis : name => api.root_resource_id
  }
}

# =============================================================================
# HTTP API Outputs
# =============================================================================

output "http_apis" {
  description = "Map of all HTTP APIs with their detailed information"
  value = {
    for name, api in aws_apigatewayv2_api.http_apis : name => {
      id               = api.id
      name            = api.name
      description     = api.description
      arn             = api.arn
      execution_arn   = api.execution_arn
      api_endpoint    = api.api_endpoint
      protocol_type   = api.protocol_type
      version         = api.version
      route_selection_expression = api.route_selection_expression
      cors_configuration = api.cors_configuration
      disable_execute_api_endpoint = api.disable_execute_api_endpoint
    }
  }
}

output "http_api_ids" {
  description = "Map of HTTP API names to their IDs"
  value = {
    for name, api in aws_apigatewayv2_api.http_apis : name => api.id
  }
}

output "http_api_execution_arns" {
  description = "Map of HTTP API names to their execution ARNs"
  value = {
    for name, api in aws_apigatewayv2_api.http_apis : name => api.execution_arn
  }
}

output "http_api_endpoints" {
  description = "Map of HTTP API names to their endpoints"
  value = {
    for name, api in aws_apigatewayv2_api.http_apis : name => api.api_endpoint
  }
}

# =============================================================================
# REST API Stage Outputs
# =============================================================================

output "rest_api_stages" {
  description = "Map of REST API stages with their detailed information"
  value = {
    for key, stage in aws_api_gateway_stage.rest_stages : key => {
      id                = stage.id
      stage_name       = stage.stage_name
      deployment_id    = stage.deployment_id
      invoke_url       = stage.invoke_url
      arn             = stage.arn
      execution_arn   = stage.execution_arn
      cache_cluster_enabled = stage.cache_cluster_enabled
      cache_cluster_size = stage.cache_cluster_size
      client_certificate_id = stage.client_certificate_id
      description     = stage.description
      documentation_version = stage.documentation_version
      variables       = stage.variables
      xray_tracing_enabled = stage.xray_tracing_enabled
      web_acl_arn     = stage.web_acl_arn
    }
  }
}

output "rest_api_stage_invoke_urls" {
  description = "Map of REST API stage keys to their invoke URLs"
  value = {
    for key, stage in aws_api_gateway_stage.rest_stages : key => stage.invoke_url
  }
}

# =============================================================================
# HTTP API Stage Outputs
# =============================================================================

output "http_api_stages" {
  description = "Map of HTTP API stages with their detailed information"
  value = {
    for key, stage in aws_apigatewayv2_stage.http_stages : key => {
      id           = stage.id
      name         = stage.name
      arn          = stage.arn
      invoke_url   = stage.invoke_url
      execution_arn = stage.execution_arn
      description  = stage.description
      auto_deploy  = stage.auto_deploy
      stage_variables = stage.stage_variables
      access_log_settings = stage.access_log_settings
      default_route_settings = stage.default_route_settings
      route_settings = stage.route_settings
    }
  }
}

output "http_api_stage_invoke_urls" {
  description = "Map of HTTP API stage keys to their invoke URLs"
  value = {
    for key, stage in aws_apigatewayv2_stage.http_stages : key => stage.invoke_url
  }
}

# =============================================================================
# API Keys and Usage Plans Outputs
# =============================================================================

output "api_keys" {
  description = "Map of API keys with their information"
  value = {
    for key, api_key in aws_api_gateway_api_key.api_keys : key => {
      id          = api_key.id
      name        = api_key.name
      description = api_key.description
      enabled     = api_key.enabled
      value       = api_key.value
      arn         = api_key.arn
      created_date = api_key.created_date
      last_updated_date = api_key.last_updated_date
    }
  }
  sensitive = true
}

output "usage_plans" {
  description = "Map of usage plans with their information"
  value = {
    for key, plan in aws_api_gateway_usage_plan.usage_plans : key => {
      id          = plan.id
      name        = plan.name
      description = plan.description
      arn         = plan.arn
      api_stages  = plan.api_stages
      quota_settings = plan.quota_settings
      throttle_settings = plan.throttle_settings
    }
  }
}

# =============================================================================
# Custom Domain Outputs
# =============================================================================

output "rest_api_custom_domains" {
  description = "Map of REST API custom domains with their information"
  value = {
    for name, domain in aws_api_gateway_domain_name.rest_custom_domains : name => {
      id                       = domain.id
      domain_name             = domain.domain_name
      arn                     = domain.arn
      certificate_arn         = domain.certificate_arn
      cloudfront_domain_name  = domain.cloudfront_domain_name
      cloudfront_zone_id      = domain.cloudfront_zone_id
      regional_certificate_arn = domain.regional_certificate_arn
      regional_domain_name    = domain.regional_domain_name
      regional_zone_id        = domain.regional_zone_id
      security_policy         = domain.security_policy
      endpoint_configuration  = domain.endpoint_configuration
    }
  }
}

output "http_api_custom_domains" {
  description = "Map of HTTP API custom domains with their information"
  value = {
    for name, domain in aws_apigatewayv2_domain_name.http_custom_domains : name => {
      id                    = domain.id
      domain_name          = domain.domain_name
      arn                  = domain.arn
      api_mapping_selection_expression = domain.api_mapping_selection_expression
      domain_name_configuration = domain.domain_name_configuration
      mutual_tls_authentication = domain.mutual_tls_authentication
    }
  }
}

# =============================================================================
# VPC Links Outputs
# =============================================================================

output "vpc_links" {
  description = "Map of VPC links with their information"
  value = {
    for name, link in aws_api_gateway_vpc_link.vpc_links : name => {
      id          = link.id
      name        = link.name
      description = link.description
      arn         = link.arn
      status      = link.status
      status_message = link.status_message
      target_arns = link.target_arns
    }
  }
}

# =============================================================================
# Authorizer Outputs
# =============================================================================

output "rest_api_authorizers" {
  description = "Map of REST API authorizers with their information"
  value = {
    for key, auth in aws_api_gateway_authorizer.rest_authorizers : key => {
      id                              = auth.id
      name                           = auth.name
      arn                            = auth.arn
      type                           = auth.type
      authorizer_uri                 = auth.authorizer_uri
      authorizer_credentials         = auth.authorizer_credentials
      authorizer_result_ttl_in_seconds = auth.authorizer_result_ttl_in_seconds
      identity_source                = auth.identity_source
      identity_validation_expression = auth.identity_validation_expression
      provider_arns                  = auth.provider_arns
      auth_type                      = auth.auth_type
    }
  }
}

output "jwt_authorizers" {
  description = "Map of HTTP API JWT authorizers with their information"
  value = {
    for key, auth in aws_apigatewayv2_authorizer.jwt_authorizers : key => {
      id                = auth.id
      name             = auth.name
      authorizer_type  = auth.authorizer_type
      identity_sources = auth.identity_sources
      jwt_configuration = auth.jwt_configuration
    }
  }
}

output "lambda_authorizers" {
  description = "Map of HTTP API Lambda authorizers with their information"
  value = {
    for key, auth in aws_apigatewayv2_authorizer.lambda_authorizers : key => {
      id                            = auth.id
      name                         = auth.name
      authorizer_type              = auth.authorizer_type
      authorizer_uri               = auth.authorizer_uri
      identity_sources             = auth.identity_sources
      authorizer_payload_format_version = auth.authorizer_payload_format_version
      authorizer_result_ttl_in_seconds = auth.authorizer_result_ttl_in_seconds
      authorizer_credentials_arn   = auth.authorizer_credentials_arn
      enable_simple_responses     = auth.enable_simple_responses
    }
  }
}

# =============================================================================
# HTTP API Integration and Route Outputs
# =============================================================================

output "http_api_integrations" {
  description = "Map of HTTP API integrations with their information"
  value = {
    for key, integration in aws_apigatewayv2_integration.http_integrations : key => {
      id                      = integration.id
      integration_type        = integration.integration_type
      integration_method      = integration.integration_method
      integration_uri         = integration.integration_uri
      integration_subtype     = integration.integration_subtype
      connection_type         = integration.connection_type
      connection_id           = integration.connection_id
      credentials_arn         = integration.credentials_arn
      description            = integration.description
      passthrough_behavior    = integration.passthrough_behavior
      payload_format_version  = integration.payload_format_version
      request_parameters      = integration.request_parameters
      request_templates       = integration.request_templates
      response_parameters     = integration.response_parameters
      template_selection_expression = integration.template_selection_expression
      timeout_milliseconds    = integration.timeout_milliseconds
      tls_config             = integration.tls_config
      integration_response_selection_expression = integration.integration_response_selection_expression
    }
  }
}

output "http_api_routes" {
  description = "Map of HTTP API routes with their information"
  value = {
    for key, route in aws_apigatewayv2_route.http_routes : key => {
      id                              = route.id
      route_key                       = route.route_key
      target                         = route.target
      authorization_type              = route.authorization_type
      authorizer_id                  = route.authorizer_id
      api_key_required               = route.api_key_required
      operation_name                 = route.operation_name
      route_response_selection_expression = route.route_response_selection_expression
      model_selection_expression     = route.model_selection_expression
      request_models                 = route.request_models
      request_parameters             = route.request_parameters
    }
  }
}

# =============================================================================
# CloudWatch Log Groups Outputs
# =============================================================================

output "log_groups" {
  description = "Map of CloudWatch log groups for API Gateway"
  value = {
    for name, log_group in aws_cloudwatch_log_group.api_gateway_logs : name => {
      name              = log_group.name
      arn               = log_group.arn
      retention_in_days = log_group.retention_in_days
      kms_key_id        = log_group.kms_key_id
    }
  }
}

# =============================================================================
# Security and Compliance Outputs
# =============================================================================

output "security_summary" {
  description = "Security configuration summary for API Gateway resources"
  value = {
    rest_apis_with_waf = [
      for name, config in var.rest_apis : name
      if config.waf_acl_arn != null
    ]
    http_apis_with_waf = [
      for name, config in var.http_apis : name
      if config.waf_acl_arn != null
    ]
    rest_apis_with_authorizers = [
      for name, api in aws_api_gateway_rest_api.rest_apis : name
      if length([for key, auth in aws_api_gateway_authorizer.rest_authorizers : auth if contains(split("-", key), name)]) > 0
    ]
    http_apis_with_jwt_auth = [
      for name, api in aws_apigatewayv2_api.http_apis : name
      if length([for key, auth in aws_apigatewayv2_authorizer.jwt_authorizers : auth if contains(split("-", key), name)]) > 0
    ]
    http_apis_with_lambda_auth = [
      for name, api in aws_apigatewayv2_api.http_apis : name
      if length([for key, auth in aws_apigatewayv2_authorizer.lambda_authorizers : auth if contains(split("-", key), name)]) > 0
    ]
    apis_with_custom_domains = concat(
      keys(aws_api_gateway_domain_name.rest_custom_domains),
      keys(aws_apigatewayv2_domain_name.http_custom_domains)
    )
    apis_with_mtls = concat(
      [for name, domain in aws_api_gateway_domain_name.rest_custom_domains : name if domain.mutual_tls_authentication != null],
      [for name, domain in aws_apigatewayv2_domain_name.http_custom_domains : name if length(domain.mutual_tls_authentication) > 0]
    )
    rest_apis_with_private_endpoints = [
      for name, api in aws_api_gateway_rest_api.rest_apis : name
      if length(api.endpoint_configuration) > 0 && 
         contains(api.endpoint_configuration[0].types, "PRIVATE")
    ]
    apis_with_xray_tracing = [
      for key, stage in aws_api_gateway_stage.rest_stages : key
      if stage.xray_tracing_enabled
    ]
  }
}

# =============================================================================
# Performance and Monitoring Outputs
# =============================================================================

output "performance_summary" {
  description = "Performance configuration summary for API Gateway resources"
  value = {
    total_rest_apis = length(aws_api_gateway_rest_api.rest_apis)
    total_http_apis = length(aws_apigatewayv2_api.http_apis)
    total_stages = length(aws_api_gateway_stage.rest_stages) + length(aws_apigatewayv2_stage.http_stages)
    
    rest_apis_with_caching = [
      for key, stage in aws_api_gateway_stage.rest_stages : key
      if stage.cache_cluster_enabled
    ]
    
    stages_with_throttling = concat(
      [for key, stage in aws_api_gateway_stage.rest_stages : key 
       if length([for setting_key, setting in aws_api_gateway_method_settings.rest_method_settings : setting 
                  if setting_key == key && (setting.settings[0].throttling_rate_limit != null || setting.settings[0].throttling_burst_limit != null)]) > 0],
      [for key, stage in aws_apigatewayv2_stage.http_stages : key 
       if length(stage.default_route_settings) > 0 && 
          (stage.default_route_settings[0].throttling_rate_limit != null || stage.default_route_settings[0].throttling_burst_limit != null)]
    )
    
    stages_with_access_logs = concat(
      [for key, stage in aws_api_gateway_stage.rest_stages : key if stage.access_log_destination_arn != null],
      [for key, stage in aws_apigatewayv2_stage.http_stages : key if length(stage.access_log_settings) > 0]
    )
    
    apis_with_cors = [
      for name, api in aws_apigatewayv2_api.http_apis : name
      if length(api.cors_configuration) > 0
    ]
    
    cache_cluster_sizes = {
      for key, stage in aws_api_gateway_stage.rest_stages : key => stage.cache_cluster_size
      if stage.cache_cluster_enabled
    }
  }
}

# =============================================================================
# Cost Optimization Outputs
# =============================================================================

output "cost_optimization_summary" {
  description = "Cost optimization information for API Gateway resources"
  value = {
    http_apis_count = length(aws_apigatewayv2_api.http_apis)
    rest_apis_count = length(aws_api_gateway_rest_api.rest_apis)
    
    # HTTP APIs are generally more cost-effective than REST APIs
    cost_optimized_apis = keys(aws_apigatewayv2_api.http_apis)
    
    # APIs with caching enabled (can reduce backend calls)
    cost_efficient_caching = [
      for key, stage in aws_api_gateway_stage.rest_stages : key
      if stage.cache_cluster_enabled
    ]
    
    # Edge-optimized vs Regional endpoints impact costs
    regional_apis = [
      for name, api in aws_api_gateway_rest_api.rest_apis : name
      if length(api.endpoint_configuration) > 0 && 
         contains(api.endpoint_configuration[0].types, "REGIONAL")
    ]
    
    edge_optimized_apis = [
      for name, api in aws_api_gateway_rest_api.rest_apis : name
      if length(api.endpoint_configuration) == 0 || 
         contains(api.endpoint_configuration[0].types, "EDGE")
    ]
    
    # Private APIs don't incur data transfer costs to internet
    private_apis = [
      for name, api in aws_api_gateway_rest_api.rest_apis : name
      if length(api.endpoint_configuration) > 0 && 
         contains(api.endpoint_configuration[0].types, "PRIVATE")
    ]
    
    # Usage plans help control and monitor API usage
    apis_with_usage_plans = [
      for key, plan in aws_api_gateway_usage_plan.usage_plans : split("-", key)[0]
    ]
    
    # Compression reduces data transfer costs
    apis_with_compression = [
      for name, api in aws_api_gateway_rest_api.rest_apis : name
      if api.minimum_compression_size != null && api.minimum_compression_size > 0
    ]
  }
}

# =============================================================================
# Integration Outputs
# =============================================================================

output "integration_endpoints" {
  description = "Integration endpoints for external services"
  value = {
    # Lambda integration targets
    lambda_integrations = {
      for key, integration in aws_apigatewayv2_integration.http_integrations : key => {
        integration_uri = integration.integration_uri
        integration_type = integration.integration_type
      }
      if integration.integration_type == "AWS_PROXY"
    }
    
    # VPC Link integrations
    vpc_link_integrations = {
      for key, integration in aws_apigatewayv2_integration.http_integrations : key => {
        connection_id = integration.connection_id
        integration_uri = integration.integration_uri
      }
      if integration.connection_type == "VPC_LINK"
    }
    
    # HTTP integrations
    http_integrations = {
      for key, integration in aws_apigatewayv2_integration.http_integrations : key => {
        integration_uri = integration.integration_uri
        integration_method = integration.integration_method
      }
      if contains(["HTTP", "HTTP_PROXY"], integration.integration_type)
    }
  }
}

# =============================================================================
# Comprehensive API Details
# =============================================================================

output "api_details" {
  description = "Comprehensive details for all API Gateway resources"
  value = {
    rest_apis = {
      for name, api in aws_api_gateway_rest_api.rest_apis : name => {
        # Basic information
        id = api.id
        name = api.name
        execution_arn = api.execution_arn
        
        # Stages
        stages = {
          for key, stage in aws_api_gateway_stage.rest_stages : 
          split("-", key)[1] => {
            invoke_url = stage.invoke_url
            stage_name = stage.stage_name
            caching_enabled = stage.cache_cluster_enabled
            xray_tracing = stage.xray_tracing_enabled
          }
          if split("-", key)[0] == name
        }
        
        # Security
        authorizers = [
          for key, auth in aws_api_gateway_authorizer.rest_authorizers : auth.name
          if split("-", key)[0] == name
        ]
        
        # Custom domains
        custom_domains = [
          for domain_name, domain_config in var.rest_api_custom_domains : domain_config.domain_name
          if domain_config.api_name == name
        ]
        
        # Usage plans
        usage_plans = [
          for key, plan in aws_api_gateway_usage_plan.usage_plans : plan.name
          if split("-", key)[0] == name
        ]
      }
    }
    
    http_apis = {
      for name, api in aws_apigatewayv2_api.http_apis : name => {
        # Basic information
        id = api.id
        name = api.name
        api_endpoint = api.api_endpoint
        execution_arn = api.execution_arn
        
        # Stages
        stages = {
          for key, stage in aws_apigatewayv2_stage.http_stages : 
          split("-", key)[1] => {
            invoke_url = stage.invoke_url
            auto_deploy = stage.auto_deploy
          }
          if split("-", key)[0] == name
        }
        
        # Security
        jwt_authorizers = [
          for key, auth in aws_apigatewayv2_authorizer.jwt_authorizers : auth.name
          if split("-", key)[0] == name
        ]
        
        lambda_authorizers = [
          for key, auth in aws_apigatewayv2_authorizer.lambda_authorizers : auth.name
          if split("-", key)[0] == name
        ]
        
        # Integrations
        integrations = [
          for key, integration in aws_apigatewayv2_integration.http_integrations : integration.integration_type
          if split("-", key)[0] == name
        ]
        
        # Routes
        routes = [
          for key, route in aws_apigatewayv2_route.http_routes : route.route_key
          if split("-", key)[0] == name
        ]
        
        # CORS configuration
        cors_enabled = length(api.cors_configuration) > 0
      }
    }
  }
}