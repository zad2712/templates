# API Gateway REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.api_description

  # API Gateway configuration
  api_key_source               = var.api_key_source
  binary_media_types           = var.binary_media_types
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  minimum_compression_size     = var.minimum_compression_size

  # Endpoint configuration
  endpoint_configuration {
    types            = var.endpoint_types
    vpc_endpoint_ids = var.vpc_endpoint_ids
  }

  # Policy document for resource-based permissions
  policy = var.api_policy

  tags = var.tags
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
    aws_api_gateway_method_response.this,
    aws_api_gateway_integration_response.this,
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    # Redeploy when configuration changes
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.this,
      aws_api_gateway_method.this,
      aws_api_gateway_integration.this,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name

  # Access logging configuration
  access_log_destination_arn = var.enable_access_logging ? aws_cloudwatch_log_group.access_logs[0].arn : null
  access_log_format = var.enable_access_logging ? jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    caller         = "$context.identity.caller"
    user           = "$context.identity.user"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    resourcePath   = "$context.resourcePath"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
    error          = "$context.error.message"
    errorMessage   = "$context.error.messageString"
  }) : null

  # X-Ray tracing
  xray_tracing_enabled = var.enable_xray_tracing

  # Cache configuration
  dynamic "cache_cluster_enabled" {
    for_each = var.cache_cluster_enabled ? [1] : []
    content {
      cache_cluster_enabled = true
      cache_cluster_size    = var.cache_cluster_size
    }
  }

  # Throttling settings
  dynamic "throttle_settings" {
    for_each = var.throttle_settings != null ? [var.throttle_settings] : []
    content {
      rate_limit  = throttle_settings.value.rate_limit
      burst_limit = throttle_settings.value.burst_limit
    }
  }

  # Stage variables
  variables = var.stage_variables

  tags = var.tags
}

# CloudWatch log group for access logs
resource "aws_cloudwatch_log_group" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  name              = "/aws/apigateway/${var.api_name}-${var.stage_name}/access-logs"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch log group for execution logs
resource "aws_cloudwatch_log_group" "execution_logs" {
  count = var.enable_execution_logging ? 1 : 0

  name              = "/aws/apigateway/${var.api_name}-${var.stage_name}/execution-logs"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# API Gateway account settings (for CloudWatch logging)
resource "aws_api_gateway_account" "this" {
  count = var.enable_access_logging || var.enable_execution_logging ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.cloudwatch[0].arn
}

# IAM role for CloudWatch logging
resource "aws_iam_role" "cloudwatch" {
  count = var.enable_access_logging || var.enable_execution_logging ? 1 : 0

  name = "${var.api_name}-${var.stage_name}-apigateway-cloudwatch"

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

  tags = var.tags
}

# IAM role policy attachment for CloudWatch logging
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count = var.enable_access_logging || var.enable_execution_logging ? 1 : 0

  role       = aws_iam_role.cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# API Gateway resources (paths)
resource "aws_api_gateway_resource" "this" {
  for_each = var.api_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = each.value.parent_id != null ? each.value.parent_id : aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

# API Gateway methods
resource "aws_api_gateway_method" "this" {
  for_each = var.api_methods

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this[each.value.resource_key].id
  http_method   = each.value.http_method
  authorization = each.value.authorization

  # Authorizer configuration
  authorizer_id = each.value.authorizer_id

  # API Key requirement
  api_key_required = each.value.api_key_required

  # Request validation
  request_validator_id = each.value.request_validator_id

  # Request parameters
  request_parameters = each.value.request_parameters

  # Request models
  request_models = each.value.request_models
}

# API Gateway integrations
resource "aws_api_gateway_integration" "this" {
  for_each = var.api_methods

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this[each.value.resource_key].id
  http_method = aws_api_gateway_method.this[each.key].http_method

  # Integration configuration
  integration_http_method = each.value.integration.integration_http_method
  type                   = each.value.integration.type
  uri                    = each.value.integration.uri

  # Connection configuration
  connection_type = each.value.integration.connection_type
  connection_id   = each.value.integration.connection_id

  # Request configuration
  request_templates   = each.value.integration.request_templates
  request_parameters  = each.value.integration.request_parameters
  passthrough_behavior = each.value.integration.passthrough_behavior

  # Cache configuration
  cache_key_parameters = each.value.integration.cache_key_parameters
  cache_namespace     = each.value.integration.cache_namespace

  # Timeout configuration
  timeout_milliseconds = each.value.integration.timeout_milliseconds

  # Credentials
  credentials = each.value.integration.credentials

  # TLS configuration
  dynamic "tls_config" {
    for_each = each.value.integration.tls_config != null ? [each.value.integration.tls_config] : []
    content {
      insecure_skip_verification = tls_config.value.insecure_skip_verification
    }
  }
}

# API Gateway method responses
resource "aws_api_gateway_method_response" "this" {
  for_each = merge([
    for method_key, method in var.api_methods : {
      for response_key, response in method.responses : "${method_key}-${response_key}" => {
        method_key    = method_key
        resource_key  = method.resource_key
        http_method   = method.http_method
        status_code   = response.status_code
        response_models      = response.response_models
        response_parameters  = response.response_parameters
      }
    }
  ]...)

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this[each.value.resource_key].id
  http_method = aws_api_gateway_method.this[each.value.method_key].http_method
  status_code = each.value.status_code

  response_models     = each.value.response_models
  response_parameters = each.value.response_parameters
}

# API Gateway integration responses
resource "aws_api_gateway_integration_response" "this" {
  for_each = merge([
    for method_key, method in var.api_methods : {
      for response_key, response in method.responses : "${method_key}-${response_key}" => {
        method_key    = method_key
        resource_key  = method.resource_key
        http_method   = method.http_method
        status_code   = response.status_code
        selection_pattern        = response.integration_response.selection_pattern
        response_templates      = response.integration_response.response_templates
        response_parameters     = response.integration_response.response_parameters
        content_handling        = response.integration_response.content_handling
      }
    }
  ]...)

  depends_on = [aws_api_gateway_integration.this]

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this[each.value.resource_key].id
  http_method = aws_api_gateway_method.this[each.value.method_key].http_method
  status_code = each.value.status_code

  selection_pattern   = each.value.selection_pattern
  response_templates  = each.value.response_templates
  response_parameters = each.value.response_parameters
  content_handling    = each.value.content_handling
}

# API Gateway request validators
resource "aws_api_gateway_request_validator" "this" {
  for_each = var.request_validators

  rest_api_id                 = aws_api_gateway_rest_api.this.id
  name                       = each.value.name
  validate_request_body      = each.value.validate_request_body
  validate_request_parameters = each.value.validate_request_parameters
}

# API Gateway models
resource "aws_api_gateway_model" "this" {
  for_each = var.api_models

  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = each.value.name
  content_type = each.value.content_type
  schema       = each.value.schema
}

# API Gateway authorizers
resource "aws_api_gateway_authorizer" "this" {
  for_each = var.api_authorizers

  name                   = each.value.name
  rest_api_id           = aws_api_gateway_rest_api.this.id
  type                  = each.value.type
  authorizer_uri        = each.value.authorizer_uri
  authorizer_credentials = each.value.authorizer_credentials
  
  # For Lambda authorizers
  authorizer_result_ttl_in_seconds = each.value.authorizer_result_ttl_in_seconds
  identity_source                  = each.value.identity_source
  identity_validation_expression   = each.value.identity_validation_expression

  # For Cognito authorizers
  provider_arns = each.value.provider_arns
}

# API Gateway usage plans
resource "aws_api_gateway_usage_plan" "this" {
  for_each = var.usage_plans

  name         = each.value.name
  description  = each.value.description

  dynamic "api_stages" {
    for_each = each.value.api_stages
    content {
      api_id = aws_api_gateway_rest_api.this.id
      stage  = api_stages.value.stage
      throttle {
        path        = api_stages.value.throttle.path
        rate_limit  = api_stages.value.throttle.rate_limit
        burst_limit = api_stages.value.throttle.burst_limit
      }
    }
  }

  dynamic "quota_settings" {
    for_each = each.value.quota_settings != null ? [each.value.quota_settings] : []
    content {
      limit  = quota_settings.value.limit
      offset = quota_settings.value.offset
      period = quota_settings.value.period
    }
  }

  dynamic "throttle_settings" {
    for_each = each.value.throttle_settings != null ? [each.value.throttle_settings] : []
    content {
      rate_limit  = throttle_settings.value.rate_limit
      burst_limit = throttle_settings.value.burst_limit
    }
  }

  tags = var.tags
}

# API Gateway API keys
resource "aws_api_gateway_api_key" "this" {
  for_each = var.api_keys

  name         = each.value.name
  description  = each.value.description
  enabled      = each.value.enabled
  value        = each.value.value

  tags = var.tags
}

# API Gateway usage plan keys (associate API keys with usage plans)
resource "aws_api_gateway_usage_plan_key" "this" {
  for_each = var.usage_plan_keys

  key_id        = aws_api_gateway_api_key.this[each.value.api_key_name].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[each.value.usage_plan_name].id
}

# Custom domain name
resource "aws_api_gateway_domain_name" "this" {
  count = var.domain_name != null ? 1 : 0

  domain_name              = var.domain_name
  certificate_arn          = var.certificate_arn
  security_policy          = var.domain_security_policy
  endpoint_configuration {
    types = var.domain_endpoint_types
  }

  tags = var.tags
}

# Base path mapping
resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.domain_name != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  base_path   = var.base_path
}

# WAF association (if WAF ARN is provided)
resource "aws_wafv2_web_acl_association" "this" {
  count = var.waf_acl_arn != null ? 1 : 0

  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = var.waf_acl_arn
}
