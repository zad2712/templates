# =============================================================================
# AWS API Gateway Module
# =============================================================================
# This module creates AWS API Gateway (REST and HTTP APIs) with comprehensive
# configuration including authentication, authorization, throttling, monitoring,
# CORS, custom domains, and integration with Lambda and other AWS services
# Features:
# - REST API Gateway with full feature set
# - HTTP API Gateway (API Gateway v2) for modern applications
# - Custom authorizers (Lambda, Cognito, JWT)
# - Request/response transformations
# - Caching and throttling
# - CORS configuration
# - Custom domains and SSL certificates
# - Stage management and deployments
# - CloudWatch logging and X-Ray tracing
# - WAF integration for security
# - VPC Link for private integrations
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.9.0"
}

# Local values for computed configurations
locals {
  # Common tags for all resources
  common_tags = merge(
    var.common_tags,
    {
      Module = "api-gateway"
    }
  )

  # REST API configurations
  rest_apis = {
    for name, config in var.rest_apis : name => {
      name               = "${var.name_prefix}-${name}"
      description        = config.description
      endpoint_configuration = config.endpoint_configuration
      binary_media_types = config.binary_media_types
      minimum_compression_size = config.minimum_compression_size
      api_key_source     = config.api_key_source
      policy            = config.policy
      disable_execute_api_endpoint = config.disable_execute_api_endpoint
      
      # OpenAPI specification
      body = config.openapi_spec != null ? jsonencode(config.openapi_spec) : null
      
      # Tags
      tags = merge(local.common_tags, config.tags)
    }
  }

  # HTTP API configurations (API Gateway v2)
  http_apis = {
    for name, config in var.http_apis : name => {
      name               = "${var.name_prefix}-${name}"
      description        = config.description
      protocol_type      = "HTTP"
      version           = config.version
      route_selection_expression = config.route_selection_expression
      disable_execute_api_endpoint = config.disable_execute_api_endpoint
      fail_on_warnings  = config.fail_on_warnings
      
      # CORS configuration
      cors_configuration = config.cors_configuration
      
      # Tags
      tags = merge(local.common_tags, config.tags)
    }
  }

  # Stage configurations for REST APIs
  rest_api_stages = flatten([
    for api_name, api_config in var.rest_apis : [
      for stage_name, stage_config in api_config.stages : {
        api_name = api_name
        stage_name = stage_name
        deployment_description = stage_config.deployment_description
        stage_description = stage_config.stage_description
        variables = stage_config.variables
        cache_cluster_enabled = stage_config.cache_cluster_enabled
        cache_cluster_size = stage_config.cache_cluster_size
        throttle_settings = stage_config.throttle_settings
        access_log_settings = stage_config.access_log_settings
        canary_settings = stage_config.canary_settings
        client_certificate_id = stage_config.client_certificate_id
        documentation_version = stage_config.documentation_version
        xray_tracing_enabled = stage_config.xray_tracing_enabled
        tags = stage_config.tags
      }
    ]
  ])

  # Stage configurations for HTTP APIs
  http_api_stages = flatten([
    for api_name, api_config in var.http_apis : [
      for stage_name, stage_config in api_config.stages : {
        api_name = api_name
        stage_name = stage_name
        description = stage_config.description
        auto_deploy = stage_config.auto_deploy
        throttle_settings = stage_config.throttle_settings
        access_log_settings = stage_config.access_log_settings
        default_route_settings = stage_config.default_route_settings
        route_settings = stage_config.route_settings
        stage_variables = stage_config.stage_variables
        tags = stage_config.tags
      }
    ]
  ])

  # API Keys configuration
  api_keys = flatten([
    for api_name, api_config in var.rest_apis : [
      for key_name, key_config in coalesce(api_config.api_keys, {}) : {
        api_name = api_name
        key_name = key_name
        description = key_config.description
        enabled = key_config.enabled
        value = key_config.value
        tags = key_config.tags
      }
    ]
  ])

  # Usage plans configuration
  usage_plans = flatten([
    for api_name, api_config in var.rest_apis : [
      for plan_name, plan_config in coalesce(api_config.usage_plans, {}) : {
        api_name = api_name
        plan_name = plan_name
        description = plan_config.description
        api_stages = plan_config.api_stages
        quota_settings = plan_config.quota_settings
        throttle_settings = plan_config.throttle_settings
        tags = plan_config.tags
      }
    ]
  ])

  # Custom domain configurations
  custom_domains = merge(
    { for name, config in var.rest_api_custom_domains : name => merge(config, { api_type = "REST" }) },
    { for name, config in var.http_api_custom_domains : name => merge(config, { api_type = "HTTP" }) }
  )

  # VPC Links configuration
  vpc_links = {
    for name, config in var.vpc_links : name => {
      name = "${var.name_prefix}-${name}"
      description = config.description
      target_arns = config.target_arns
      tags = merge(local.common_tags, config.tags)
    }
  }

  # Authorizers configuration for REST APIs
  rest_authorizers = flatten([
    for api_name, api_config in var.rest_apis : [
      for auth_name, auth_config in coalesce(api_config.authorizers, {}) : {
        api_name = api_name
        auth_name = auth_name
        name = auth_config.name
        type = auth_config.type
        authorizer_uri = auth_config.authorizer_uri
        authorizer_credentials = auth_config.authorizer_credentials
        authorizer_result_ttl_in_seconds = auth_config.authorizer_result_ttl_in_seconds
        identity_source = auth_config.identity_source
        identity_validation_expression = auth_config.identity_validation_expression
        provider_arns = auth_config.provider_arns
        auth_type = auth_config.auth_type
      }
    ]
  ])

  # JWT Authorizers for HTTP APIs
  jwt_authorizers = flatten([
    for api_name, api_config in var.http_apis : [
      for auth_name, auth_config in coalesce(api_config.jwt_authorizers, {}) : {
        api_name = api_name
        auth_name = auth_name
        name = auth_config.name
        audience = auth_config.audience
        issuer = auth_config.issuer
        identity_sources = auth_config.identity_sources
      }
    ]
  ])

  # Lambda Authorizers for HTTP APIs
  lambda_authorizers = flatten([
    for api_name, api_config in var.http_apis : [
      for auth_name, auth_config in coalesce(api_config.lambda_authorizers, {}) : {
        api_name = api_name
        auth_name = auth_name
        name = auth_config.name
        authorizer_type = auth_config.authorizer_type
        authorizer_uri = auth_config.authorizer_uri
        authorizer_payload_format_version = auth_config.authorizer_payload_format_version
        authorizer_result_ttl_in_seconds = auth_config.authorizer_result_ttl_in_seconds
        identity_sources = auth_config.identity_sources
        authorizer_credentials_arn = auth_config.authorizer_credentials_arn
        enable_simple_responses = auth_config.enable_simple_responses
      }
    ]
  ])

  # Integrations for HTTP APIs
  http_integrations = flatten([
    for api_name, api_config in var.http_apis : [
      for int_name, int_config in coalesce(api_config.integrations, {}) : {
        api_name = api_name
        integration_name = int_name
        integration_type = int_config.integration_type
        integration_method = int_config.integration_method
        integration_uri = int_config.integration_uri
        integration_subtype = int_config.integration_subtype
        connection_type = int_config.connection_type
        connection_id = int_config.connection_id
        credentials_arn = int_config.credentials_arn
        description = int_config.description
        passthrough_behavior = int_config.passthrough_behavior
        payload_format_version = int_config.payload_format_version
        request_parameters = int_config.request_parameters
        request_templates = int_config.request_templates
        response_parameters = int_config.response_parameters
        template_selection_expression = int_config.template_selection_expression
        timeout_milliseconds = int_config.timeout_milliseconds
        tls_config = int_config.tls_config
      }
    ]
  ])

  # Routes for HTTP APIs
  http_routes = flatten([
    for api_name, api_config in var.http_apis : [
      for route_name, route_config in coalesce(api_config.routes, {}) : {
        api_name = api_name
        route_name = route_name
        route_key = route_config.route_key
        target = route_config.target
        authorization_type = route_config.authorization_type
        authorizer_id = route_config.authorizer_id
        api_key_required = route_config.api_key_required
        operation_name = route_config.operation_name
        route_response_selection_expression = route_config.route_response_selection_expression
        model_selection_expression = route_config.model_selection_expression
        request_models = route_config.request_models
        request_parameters = route_config.request_parameters
      }
    ]
  ])
}

# =============================================================================
# CloudWatch Log Groups for API Gateway
# =============================================================================

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  for_each = merge(
    { for name in keys(var.rest_apis) : "rest-${name}" => "REST" },
    { for name in keys(var.http_apis) : "http-${name}" => "HTTP" }
  )

  name              = "/aws/apigateway/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    local.common_tags,
    {
      Purpose = "API Gateway logs"
      APIType = each.value
    }
  )
}

# =============================================================================
# IAM Role for API Gateway CloudWatch Logs
# =============================================================================

resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name_prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  role       = aws_iam_role.api_gateway_cloudwatch_role[0].name
}

# API Gateway account settings for CloudWatch logs
resource "aws_api_gateway_account" "main" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role[0].arn
}

# =============================================================================
# REST API Gateway
# =============================================================================

resource "aws_api_gateway_rest_api" "rest_apis" {
  for_each = local.rest_apis

  name        = each.value.name
  description = each.value.description
  body        = each.value.body
  
  binary_media_types           = each.value.binary_media_types
  minimum_compression_size     = each.value.minimum_compression_size
  api_key_source              = each.value.api_key_source
  policy                      = each.value.policy
  disable_execute_api_endpoint = each.value.disable_execute_api_endpoint

  dynamic "endpoint_configuration" {
    for_each = each.value.endpoint_configuration != null ? [each.value.endpoint_configuration] : []
    content {
      types            = endpoint_configuration.value.types
      vpc_endpoint_ids = endpoint_configuration.value.vpc_endpoint_ids
    }
  }

  tags = each.value.tags

  depends_on = [aws_cloudwatch_log_group.api_gateway_logs]
}

# =============================================================================
# HTTP API Gateway (API Gateway v2)
# =============================================================================

resource "aws_apigatewayv2_api" "http_apis" {
  for_each = local.http_apis

  name                         = each.value.name
  description                  = each.value.description
  protocol_type               = each.value.protocol_type
  version                     = each.value.version
  route_selection_expression  = each.value.route_selection_expression
  disable_execute_api_endpoint = each.value.disable_execute_api_endpoint
  fail_on_warnings           = each.value.fail_on_warnings

  dynamic "cors_configuration" {
    for_each = each.value.cors_configuration != null ? [each.value.cors_configuration] : []
    content {
      allow_credentials = cors_configuration.value.allow_credentials
      allow_headers     = cors_configuration.value.allow_headers
      allow_methods     = cors_configuration.value.allow_methods
      allow_origins     = cors_configuration.value.allow_origins
      expose_headers    = cors_configuration.value.expose_headers
      max_age          = cors_configuration.value.max_age
    }
  }

  tags = each.value.tags

  depends_on = [aws_cloudwatch_log_group.api_gateway_logs]
}

# =============================================================================
# REST API Deployments and Stages
# =============================================================================

resource "aws_api_gateway_deployment" "rest_deployments" {
  for_each = {
    for stage in local.rest_api_stages : "${stage.api_name}-${stage.stage_name}" => stage
  }

  rest_api_id = aws_api_gateway_rest_api.rest_apis[each.value.api_name].id
  description = each.value.deployment_description

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.rest_apis[each.value.api_name].body
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "rest_stages" {
  for_each = {
    for stage in local.rest_api_stages : "${stage.api_name}-${stage.stage_name}" => stage
  }

  deployment_id         = aws_api_gateway_deployment.rest_deployments[each.key].id
  rest_api_id          = aws_api_gateway_rest_api.rest_apis[each.value.api_name].id
  stage_name           = each.value.stage_name
  description          = each.value.stage_description
  variables            = each.value.variables
  cache_cluster_enabled = each.value.cache_cluster_enabled
  cache_cluster_size   = each.value.cache_cluster_size
  client_certificate_id = each.value.client_certificate_id
  documentation_version = each.value.documentation_version
  xray_tracing_enabled = each.value.xray_tracing_enabled

  dynamic "access_log_destination_arn" {
    for_each = each.value.access_log_settings != null ? [1] : []
    content {
      destination_arn = each.value.access_log_settings.destination_arn
      format         = each.value.access_log_settings.format
    }
  }

  dynamic "canary_settings" {
    for_each = each.value.canary_settings != null ? [each.value.canary_settings] : []
    content {
      percent_traffic          = canary_settings.value.percent_traffic
      deployment_id           = canary_settings.value.deployment_id
      stage_variable_overrides = canary_settings.value.stage_variable_overrides
      use_stage_cache         = canary_settings.value.use_stage_cache
    }
  }

  tags = merge(local.common_tags, each.value.tags)

  depends_on = [aws_api_gateway_account.main]
}

# Method settings for REST API stages
resource "aws_api_gateway_method_settings" "rest_method_settings" {
  for_each = {
    for stage in local.rest_api_stages : "${stage.api_name}-${stage.stage_name}" => stage
    if stage.throttle_settings != null
  }

  rest_api_id = aws_api_gateway_rest_api.rest_apis[each.value.api_name].id
  stage_name  = aws_api_gateway_stage.rest_stages[each.key].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = each.value.throttle_settings.metrics_enabled
    logging_level     = each.value.throttle_settings.logging_level
    data_trace_enabled = each.value.throttle_settings.data_trace_enabled
    throttling_rate_limit  = each.value.throttle_settings.throttling_rate_limit
    throttling_burst_limit = each.value.throttle_settings.throttling_burst_limit
    caching_enabled       = each.value.throttle_settings.caching_enabled
    cache_ttl_in_seconds  = each.value.throttle_settings.cache_ttl_in_seconds
    cache_key_parameters  = each.value.throttle_settings.cache_key_parameters
    require_authorization_for_cache_control = each.value.throttle_settings.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = each.value.throttle_settings.unauthorized_cache_control_header_strategy
  }
}

# =============================================================================
# HTTP API Stages
# =============================================================================

resource "aws_apigatewayv2_stage" "http_stages" {
  for_each = {
    for stage in local.http_api_stages : "${stage.api_name}-${stage.stage_name}" => stage
  }

  api_id      = aws_apigatewayv2_api.http_apis[each.value.api_name].id
  name        = each.value.stage_name
  description = each.value.description
  auto_deploy = each.value.auto_deploy

  stage_variables = each.value.stage_variables

  dynamic "access_log_settings" {
    for_each = each.value.access_log_settings != null ? [each.value.access_log_settings] : []
    content {
      destination_arn = access_log_settings.value.destination_arn
      format         = access_log_settings.value.format
    }
  }

  dynamic "default_route_settings" {
    for_each = each.value.default_route_settings != null ? [each.value.default_route_settings] : []
    content {
      data_trace_enabled       = default_route_settings.value.data_trace_enabled
      detailed_metrics_enabled = default_route_settings.value.detailed_metrics_enabled
      logging_level           = default_route_settings.value.logging_level
      throttling_burst_limit  = default_route_settings.value.throttling_burst_limit
      throttling_rate_limit   = default_route_settings.value.throttling_rate_limit
    }
  }

  dynamic "route_settings" {
    for_each = coalesce(each.value.route_settings, {})
    content {
      route_key                = route_settings.key
      data_trace_enabled       = route_settings.value.data_trace_enabled
      detailed_metrics_enabled = route_settings.value.detailed_metrics_enabled
      logging_level           = route_settings.value.logging_level
      throttling_burst_limit  = route_settings.value.throttling_burst_limit
      throttling_rate_limit   = route_settings.value.throttling_rate_limit
    }
  }

  tags = merge(local.common_tags, each.value.tags)

  depends_on = [aws_apigatewayv2_api.http_apis]
}

# =============================================================================
# API Keys
# =============================================================================

resource "aws_api_gateway_api_key" "api_keys" {
  for_each = {
    for key in local.api_keys : "${key.api_name}-${key.key_name}" => key
  }

  name        = "${var.name_prefix}-${each.value.api_name}-${each.value.key_name}"
  description = each.value.description
  enabled     = each.value.enabled
  value       = each.value.value

  tags = merge(local.common_tags, each.value.tags)
}

# =============================================================================
# Usage Plans
# =============================================================================

resource "aws_api_gateway_usage_plan" "usage_plans" {
  for_each = {
    for plan in local.usage_plans : "${plan.api_name}-${plan.plan_name}" => plan
  }

  name        = "${var.name_prefix}-${each.value.api_name}-${each.value.plan_name}"
  description = each.value.description

  dynamic "api_stages" {
    for_each = each.value.api_stages
    content {
      api_id = aws_api_gateway_rest_api.rest_apis[each.value.api_name].id
      stage  = api_stages.value.stage
      throttle {
        burst_limit = api_stages.value.throttle.burst_limit
        rate_limit  = api_stages.value.throttle.rate_limit
        path        = api_stages.value.throttle.path
      }
    }
  }

  dynamic "quota_settings" {
    for_each = each.value.quota_settings != null ? [each.value.quota_settings] : []
    content {
      limit  = quota_settings.value.limit
      period = quota_settings.value.period
      offset = quota_settings.value.offset
    }
  }

  dynamic "throttle_settings" {
    for_each = each.value.throttle_settings != null ? [each.value.throttle_settings] : []
    content {
      rate_limit  = throttle_settings.value.rate_limit
      burst_limit = throttle_settings.value.burst_limit
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

# =============================================================================
# Usage Plan Keys
# =============================================================================

resource "aws_api_gateway_usage_plan_key" "usage_plan_keys" {
  for_each = {
    for plan in local.usage_plans : "${plan.api_name}-${plan.plan_name}" => plan
  }

  key_id        = aws_api_gateway_api_key.api_keys["${each.value.api_name}-${each.value.plan_name}"].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plans[each.key].id
}

# =============================================================================
# Custom Domain Names
# =============================================================================

resource "aws_api_gateway_domain_name" "rest_custom_domains" {
  for_each = { 
    for name, config in local.custom_domains : name => config 
    if config.api_type == "REST"
  }

  domain_name              = each.value.domain_name
  certificate_arn          = each.value.certificate_arn
  certificate_name         = each.value.certificate_name
  certificate_body         = each.value.certificate_body
  certificate_chain        = each.value.certificate_chain
  certificate_private_key  = each.value.certificate_private_key
  regional_certificate_arn = each.value.regional_certificate_arn
  regional_certificate_name = each.value.regional_certificate_name
  security_policy          = each.value.security_policy
  mutual_tls_authentication = each.value.mutual_tls_authentication

  dynamic "endpoint_configuration" {
    for_each = each.value.endpoint_configuration != null ? [each.value.endpoint_configuration] : []
    content {
      types = endpoint_configuration.value.types
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

resource "aws_apigatewayv2_domain_name" "http_custom_domains" {
  for_each = { 
    for name, config in local.custom_domains : name => config 
    if config.api_type == "HTTP"
  }

  domain_name = each.value.domain_name

  dynamic "domain_name_configuration" {
    for_each = [each.value.domain_name_configuration]
    content {
      certificate_arn                        = domain_name_configuration.value.certificate_arn
      endpoint_type                         = domain_name_configuration.value.endpoint_type
      security_policy                       = domain_name_configuration.value.security_policy
      target_domain_name                    = domain_name_configuration.value.target_domain_name
      hosted_zone_id                        = domain_name_configuration.value.hosted_zone_id
      ownership_verification_certificate_arn = domain_name_configuration.value.ownership_verification_certificate_arn
    }
  }

  dynamic "mutual_tls_authentication" {
    for_each = each.value.mutual_tls_authentication != null ? [each.value.mutual_tls_authentication] : []
    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = mutual_tls_authentication.value.truststore_version
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

# =============================================================================
# Base Path Mappings
# =============================================================================

resource "aws_api_gateway_base_path_mapping" "rest_base_path_mappings" {
  for_each = { 
    for name, config in var.rest_api_custom_domains : name => config 
    if config.base_path_mappings != null
  }

  api_id      = aws_api_gateway_rest_api.rest_apis[each.value.api_name].id
  stage_name  = each.value.base_path_mappings.stage_name
  domain_name = aws_api_gateway_domain_name.rest_custom_domains[each.key].domain_name
  base_path   = each.value.base_path_mappings.base_path
}

resource "aws_apigatewayv2_api_mapping" "http_api_mappings" {
  for_each = { 
    for name, config in var.http_api_custom_domains : name => config 
    if config.api_mapping != null
  }

  api_id          = aws_apigatewayv2_api.http_apis[each.value.api_name].id
  domain_name     = aws_apigatewayv2_domain_name.http_custom_domains[each.key].id
  stage           = each.value.api_mapping.stage
  api_mapping_key = each.value.api_mapping.api_mapping_key
}

# =============================================================================
# VPC Links
# =============================================================================

resource "aws_api_gateway_vpc_link" "vpc_links" {
  for_each = local.vpc_links

  name        = each.value.name
  description = each.value.description
  target_arns = each.value.target_arns

  tags = each.value.tags
}

# =============================================================================
# REST API Authorizers
# =============================================================================

resource "aws_api_gateway_authorizer" "rest_authorizers" {
  for_each = {
    for auth in local.rest_authorizers : "${auth.api_name}-${auth.auth_name}" => auth
  }

  name                             = each.value.name
  rest_api_id                     = aws_api_gateway_rest_api.rest_apis[each.value.api_name].id
  type                            = each.value.type
  authorizer_uri                  = each.value.authorizer_uri
  authorizer_credentials          = each.value.authorizer_credentials
  authorizer_result_ttl_in_seconds = each.value.authorizer_result_ttl_in_seconds
  identity_source                 = each.value.identity_source
  identity_validation_expression   = each.value.identity_validation_expression
  provider_arns                   = each.value.provider_arns
  auth_type                       = each.value.auth_type
}

# =============================================================================
# HTTP API JWT Authorizers
# =============================================================================

resource "aws_apigatewayv2_authorizer" "jwt_authorizers" {
  for_each = {
    for auth in local.jwt_authorizers : "${auth.api_name}-${auth.auth_name}" => auth
  }

  api_id           = aws_apigatewayv2_api.http_apis[each.value.api_name].id
  authorizer_type  = "JWT"
  identity_sources = each.value.identity_sources
  name            = each.value.name

  jwt_configuration {
    audience = each.value.audience
    issuer   = each.value.issuer
  }
}

# =============================================================================
# HTTP API Lambda Authorizers
# =============================================================================

resource "aws_apigatewayv2_authorizer" "lambda_authorizers" {
  for_each = {
    for auth in local.lambda_authorizers : "${auth.api_name}-${auth.auth_name}" => auth
  }

  api_id                            = aws_apigatewayv2_api.http_apis[each.value.api_name].id
  authorizer_type                   = each.value.authorizer_type
  authorizer_uri                    = each.value.authorizer_uri
  identity_sources                  = each.value.identity_sources
  name                             = each.value.name
  authorizer_payload_format_version = each.value.authorizer_payload_format_version
  authorizer_result_ttl_in_seconds  = each.value.authorizer_result_ttl_in_seconds
  authorizer_credentials_arn        = each.value.authorizer_credentials_arn
  enable_simple_responses          = each.value.enable_simple_responses
}

# =============================================================================
# HTTP API Integrations
# =============================================================================

resource "aws_apigatewayv2_integration" "http_integrations" {
  for_each = {
    for integration in local.http_integrations : 
    "${integration.api_name}-${integration.integration_name}" => integration
  }

  api_id                    = aws_apigatewayv2_api.http_apis[each.value.api_name].id
  integration_type          = each.value.integration_type
  integration_method        = each.value.integration_method
  integration_uri           = each.value.integration_uri
  integration_subtype       = each.value.integration_subtype
  connection_type          = each.value.connection_type
  connection_id            = each.value.connection_id
  credentials_arn          = each.value.credentials_arn
  description              = each.value.description
  passthrough_behavior     = each.value.passthrough_behavior
  payload_format_version   = each.value.payload_format_version
  request_parameters       = each.value.request_parameters
  request_templates        = each.value.request_templates
  response_parameters      = each.value.response_parameters
  template_selection_expression = each.value.template_selection_expression
  timeout_milliseconds     = each.value.timeout_milliseconds

  dynamic "tls_config" {
    for_each = each.value.tls_config != null ? [each.value.tls_config] : []
    content {
      server_name_to_verify = tls_config.value.server_name_to_verify
    }
  }
}

# =============================================================================
# HTTP API Routes
# =============================================================================

resource "aws_apigatewayv2_route" "http_routes" {
  for_each = {
    for route in local.http_routes : 
    "${route.api_name}-${route.route_name}" => route
  }

  api_id    = aws_apigatewayv2_api.http_apis[each.value.api_name].id
  route_key = each.value.route_key
  target    = each.value.target

  authorization_type               = each.value.authorization_type
  authorizer_id                   = each.value.authorizer_id
  api_key_required                = each.value.api_key_required
  operation_name                  = each.value.operation_name
  route_response_selection_expression = each.value.route_response_selection_expression
  model_selection_expression      = each.value.model_selection_expression
  request_models                  = each.value.request_models
  request_parameters              = each.value.request_parameters
}

# =============================================================================
# WAF Association (if enabled)
# =============================================================================

resource "aws_wafv2_web_acl_association" "rest_api_waf" {
  for_each = {
    for name, config in var.rest_apis : name => config
    if config.waf_acl_arn != null
  }

  resource_arn = aws_api_gateway_stage.rest_stages["${each.key}-${keys(each.value.stages)[0]}"].arn
  web_acl_arn  = each.value.waf_acl_arn
}

resource "aws_wafv2_web_acl_association" "http_api_waf" {
  for_each = {
    for name, config in var.http_apis : name => config
    if config.waf_acl_arn != null
  }

  resource_arn = aws_apigatewayv2_stage.http_stages["${each.key}-${keys(each.value.stages)[0]}"].arn
  web_acl_arn  = each.value.waf_acl_arn
}