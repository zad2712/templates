# =============================================================================
# AWS API Gateway Module Variables
# =============================================================================
# This file defines all the variables used in the API Gateway module with
# comprehensive validation rules and detailed descriptions for both REST and
# HTTP APIs, including authentication, authorization, and monitoring
# =============================================================================

# =============================================================================
# General Configuration
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names to ensure uniqueness and organization"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name_prefix))
    error_message = "Name prefix must start with a letter, contain only alphanumeric characters and hyphens, and end with an alphanumeric character."
  }

  validation {
    condition     = length(var.name_prefix) >= 2 && length(var.name_prefix) <= 30
    error_message = "Name prefix must be between 2 and 30 characters long."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources created by this module"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.common_tags : 
      can(regex("^[\\w\\s\\-\\.\\:\\/\\=\\+\\@]+$", tag_key)) &&
      can(regex("^[\\w\\s\\-\\.\\:\\/\\=\\+\\@]*$", tag_value)) &&
      length(tag_key) <= 128 &&
      length(tag_value) <= 256
    ])
    error_message = "Tag keys and values must contain only valid characters and be within AWS limits (key: 128 chars, value: 256 chars)."
  }
}

# =============================================================================
# CloudWatch Configuration
# =============================================================================

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logging for API Gateway"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs for API Gateway"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 
      731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be one of the valid CloudWatch log retention values."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = null

  validation {
    condition = var.log_kms_key_id == null || can(regex("^(arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+|[a-f0-9-]+)$", var.log_kms_key_id))
    error_message = "Log KMS key ID must be a valid KMS key ID or ARN."
  }
}

# =============================================================================
# REST API Configuration
# =============================================================================

variable "rest_apis" {
  description = "Configuration for REST API Gateway instances"
  type = map(object({
    description                  = optional(string, "REST API managed by Terraform")
    binary_media_types          = optional(list(string), [])
    minimum_compression_size     = optional(number, 1024)
    api_key_source              = optional(string, "HEADER")
    policy                      = optional(string)
    disable_execute_api_endpoint = optional(bool, false)
    
    # Endpoint configuration
    endpoint_configuration = optional(object({
      types            = list(string)
      vpc_endpoint_ids = optional(list(string))
    }))
    
    # OpenAPI specification
    openapi_spec = optional(any)
    
    # Stages configuration
    stages = map(object({
      deployment_description = optional(string, "Deployment managed by Terraform")
      stage_description     = optional(string)
      variables            = optional(map(string), {})
      cache_cluster_enabled = optional(bool, false)
      cache_cluster_size   = optional(string, "0.5")
      client_certificate_id = optional(string)
      documentation_version = optional(string)
      xray_tracing_enabled = optional(bool, false)
      
      # Throttling settings
      throttle_settings = optional(object({
        metrics_enabled        = optional(bool, true)
        logging_level         = optional(string, "INFO")
        data_trace_enabled    = optional(bool, false)
        throttling_rate_limit = optional(number, 1000)
        throttling_burst_limit = optional(number, 2000)
        caching_enabled       = optional(bool, false)
        cache_ttl_in_seconds  = optional(number, 300)
        cache_key_parameters  = optional(list(string), [])
        require_authorization_for_cache_control = optional(bool, false)
        unauthorized_cache_control_header_strategy = optional(string, "SUCCEED_WITH_RESPONSE_HEADER")
      }))
      
      # Access log settings
      access_log_settings = optional(object({
        destination_arn = string
        format         = string
      }))
      
      # Canary settings
      canary_settings = optional(object({
        percent_traffic          = number
        deployment_id           = optional(string)
        stage_variable_overrides = optional(map(string))
        use_stage_cache         = optional(bool, false)
      }))
      
      tags = optional(map(string), {})
    }))
    
    # API Keys
    api_keys = optional(map(object({
      description = optional(string)
      enabled     = optional(bool, true)
      value       = optional(string)
      tags        = optional(map(string), {})
    })), {})
    
    # Usage Plans
    usage_plans = optional(map(object({
      description = optional(string)
      api_stages = list(object({
        stage = string
        throttle = optional(object({
          burst_limit = optional(number)
          rate_limit  = optional(number)
          path        = optional(string, "*")
        }))
      }))
      quota_settings = optional(object({
        limit  = number
        period = string
        offset = optional(number, 0)
      }))
      throttle_settings = optional(object({
        rate_limit  = number
        burst_limit = number
      }))
      tags = optional(map(string), {})
    })), {})
    
    # Authorizers
    authorizers = optional(map(object({
      name                             = string
      type                            = string
      authorizer_uri                  = optional(string)
      authorizer_credentials          = optional(string)
      authorizer_result_ttl_in_seconds = optional(number, 300)
      identity_source                 = optional(string)
      identity_validation_expression   = optional(string)
      provider_arns                   = optional(list(string))
      auth_type                       = optional(string)
    })), {})
    
    # WAF ACL ARN
    waf_acl_arn = optional(string)
    
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.rest_apis : 
      length(name) >= 1 && length(name) <= 128
    ])
    error_message = "REST API names must be between 1 and 128 characters long."
  }

  validation {
    condition = alltrue([
      for name, config in var.rest_apis : 
      can(regex("^[a-zA-Z0-9._-]+$", name))
    ])
    error_message = "REST API names must contain only alphanumeric characters, periods, hyphens, and underscores."
  }

  validation {
    condition = alltrue([
      for name, config in var.rest_apis : 
      config.api_key_source == null || contains(["HEADER", "AUTHORIZER"], config.api_key_source)
    ])
    error_message = "API key source must be either 'HEADER' or 'AUTHORIZER'."
  }

  validation {
    condition = alltrue([
      for name, config in var.rest_apis : 
      config.minimum_compression_size == null || 
      (config.minimum_compression_size >= 0 && config.minimum_compression_size <= 10485760)
    ])
    error_message = "Minimum compression size must be between 0 and 10485760 bytes."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.rest_apis : [
        for endpoint_config in (config.endpoint_configuration != null ? [config.endpoint_configuration] : []) : 
        alltrue([
          for type in endpoint_config.types : 
          contains(["EDGE", "REGIONAL", "PRIVATE"], type)
        ])
      ]
    ]))
    error_message = "Endpoint configuration types must be 'EDGE', 'REGIONAL', or 'PRIVATE'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.rest_apis : [
        for stage_name, stage_config in config.stages : [
          stage_config.cache_cluster_size == null || 
          contains(["0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237"], stage_config.cache_cluster_size)
        ]
      ]
    ]))
    error_message = "Cache cluster size must be one of: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.rest_apis : [
        for stage_name, stage_config in config.stages : [
          stage_config.throttle_settings == null || 
          stage_config.throttle_settings.logging_level == null || 
          contains(["OFF", "ERROR", "INFO"], stage_config.throttle_settings.logging_level)
        ]
      ]
    ]))
    error_message = "Logging level must be 'OFF', 'ERROR', or 'INFO'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.rest_apis : [
        for auth_name, auth_config in coalesce(config.authorizers, {}) : 
        contains(["TOKEN", "REQUEST", "COGNITO_USER_POOLS"], auth_config.type)
      ]
    ]))
    error_message = "Authorizer type must be 'TOKEN', 'REQUEST', or 'COGNITO_USER_POOLS'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.rest_apis : [
        for auth_name, auth_config in coalesce(config.authorizers, {}) : 
        auth_config.authorizer_result_ttl_in_seconds >= 0 && auth_config.authorizer_result_ttl_in_seconds <= 3600
      ]
    ]))
    error_message = "Authorizer result TTL must be between 0 and 3600 seconds."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.rest_apis : [
        for plan_name, plan_config in coalesce(config.usage_plans, {}) : [
          plan_config.quota_settings == null || 
          contains(["DAY", "WEEK", "MONTH"], plan_config.quota_settings.period)
        ]
      ]
    ]))
    error_message = "Usage plan quota period must be 'DAY', 'WEEK', or 'MONTH'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.rest_apis : [
        for plan_name, plan_config in coalesce(config.usage_plans, {}) : [
          plan_config.quota_settings == null || 
          plan_config.quota_settings.limit >= 0
        ]
      ]
    ]))
    error_message = "Usage plan quota limit must be non-negative."
  }
}

# =============================================================================
# HTTP API Configuration (API Gateway v2)
# =============================================================================

variable "http_apis" {
  description = "Configuration for HTTP API Gateway v2 instances"
  type = map(object({
    description                  = optional(string, "HTTP API managed by Terraform")
    version                     = optional(string, "1.0")
    route_selection_expression  = optional(string, "$request.method $request.path")
    disable_execute_api_endpoint = optional(bool, false)
    fail_on_warnings           = optional(bool, false)
    
    # CORS configuration
    cors_configuration = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_origins     = optional(list(string))
      expose_headers    = optional(list(string))
      max_age          = optional(number, 86400)
    }))
    
    # Stages configuration
    stages = map(object({
      description = optional(string)
      auto_deploy = optional(bool, true)
      
      # Throttling settings
      throttle_settings = optional(object({
        throttling_rate_limit  = optional(number, 1000)
        throttling_burst_limit = optional(number, 2000)
      }))
      
      # Access log settings
      access_log_settings = optional(object({
        destination_arn = string
        format         = string
      }))
      
      # Default route settings
      default_route_settings = optional(object({
        data_trace_enabled       = optional(bool, false)
        detailed_metrics_enabled = optional(bool, false)
        logging_level           = optional(string, "OFF")
        throttling_burst_limit  = optional(number, 2000)
        throttling_rate_limit   = optional(number, 1000)
      }))
      
      # Route-specific settings
      route_settings = optional(map(object({
        data_trace_enabled       = optional(bool, false)
        detailed_metrics_enabled = optional(bool, false)
        logging_level           = optional(string, "OFF")
        throttling_burst_limit  = optional(number)
        throttling_rate_limit   = optional(number)
      })), {})
      
      stage_variables = optional(map(string), {})
      tags           = optional(map(string), {})
    }))
    
    # JWT Authorizers
    jwt_authorizers = optional(map(object({
      name             = string
      audience         = list(string)
      issuer          = string
      identity_sources = optional(list(string), ["$request.header.Authorization"])
    })), {})
    
    # Lambda Authorizers
    lambda_authorizers = optional(map(object({
      name                            = string
      authorizer_type                 = string
      authorizer_uri                  = string
      identity_sources               = optional(list(string), ["$request.header.Authorization"])
      authorizer_payload_format_version = optional(string, "2.0")
      authorizer_result_ttl_in_seconds = optional(number, 300)
      authorizer_credentials_arn      = optional(string)
      enable_simple_responses        = optional(bool, false)
    })), {})
    
    # Integrations
    integrations = optional(map(object({
      integration_type        = string
      integration_method     = optional(string)
      integration_uri        = optional(string)
      integration_subtype    = optional(string)
      connection_type        = optional(string, "INTERNET")
      connection_id          = optional(string)
      credentials_arn        = optional(string)
      description           = optional(string)
      passthrough_behavior   = optional(string)
      payload_format_version = optional(string, "2.0")
      request_parameters     = optional(map(string), {})
      request_templates      = optional(map(string), {})
      response_parameters    = optional(map(map(string)), {})
      template_selection_expression = optional(string)
      timeout_milliseconds   = optional(number, 29000)
      tls_config = optional(object({
        server_name_to_verify = string
      }))
    })), {})
    
    # Routes
    routes = optional(map(object({
      route_key                           = string
      target                             = optional(string)
      authorization_type                  = optional(string, "NONE")
      authorizer_id                      = optional(string)
      api_key_required                   = optional(bool, false)
      operation_name                     = optional(string)
      route_response_selection_expression = optional(string)
      model_selection_expression         = optional(string)
      request_models                     = optional(map(string), {})
      request_parameters                 = optional(map(object({
        location = string
        required = bool
      })), {})
    })), {})
    
    # WAF ACL ARN
    waf_acl_arn = optional(string)
    
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.http_apis : 
      length(name) >= 1 && length(name) <= 128
    ])
    error_message = "HTTP API names must be between 1 and 128 characters long."
  }

  validation {
    condition = alltrue([
      for name, config in var.http_apis : 
      can(regex("^[a-zA-Z0-9._-]+$", name))
    ])
    error_message = "HTTP API names must contain only alphanumeric characters, periods, hyphens, and underscores."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for stage_name, stage_config in config.stages : [
          stage_config.default_route_settings == null || 
          stage_config.default_route_settings.logging_level == null || 
          contains(["OFF", "ERROR", "INFO"], stage_config.default_route_settings.logging_level)
        ]
      ]
    ]))
    error_message = "HTTP API logging level must be 'OFF', 'ERROR', or 'INFO'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for auth_name, auth_config in coalesce(config.lambda_authorizers, {}) : 
        contains(["REQUEST", "SIMPLE"], auth_config.authorizer_type)
      ]
    ]))
    error_message = "Lambda authorizer type must be 'REQUEST' or 'SIMPLE'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for auth_name, auth_config in coalesce(config.lambda_authorizers, {}) : 
        contains(["1.0", "2.0"], auth_config.authorizer_payload_format_version)
      ]
    ]))
    error_message = "Authorizer payload format version must be '1.0' or '2.0'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for auth_name, auth_config in coalesce(config.lambda_authorizers, {}) : 
        auth_config.authorizer_result_ttl_in_seconds >= 0 && auth_config.authorizer_result_ttl_in_seconds <= 3600
      ]
    ]))
    error_message = "Lambda authorizer result TTL must be between 0 and 3600 seconds."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for int_name, int_config in coalesce(config.integrations, {}) : 
        contains([
          "AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY", "MOCK"
        ], int_config.integration_type)
      ]
    ]))
    error_message = "Integration type must be 'AWS', 'AWS_PROXY', 'HTTP', 'HTTP_PROXY', or 'MOCK'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for int_name, int_config in coalesce(config.integrations, {}) : 
        int_config.connection_type == null || 
        contains(["INTERNET", "VPC_LINK"], int_config.connection_type)
      ]
    ]))
    error_message = "Connection type must be 'INTERNET' or 'VPC_LINK'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for int_name, int_config in coalesce(config.integrations, {}) : 
        int_config.payload_format_version == null || 
        contains(["1.0", "2.0"], int_config.payload_format_version)
      ]
    ]))
    error_message = "Payload format version must be '1.0' or '2.0'."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for int_name, int_config in coalesce(config.integrations, {}) : 
        int_config.timeout_milliseconds >= 50 && int_config.timeout_milliseconds <= 30000
      ]
    ]))
    error_message = "Integration timeout must be between 50 and 30,000 milliseconds."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.http_apis : [
        for route_name, route_config in coalesce(config.routes, {}) : 
        route_config.authorization_type == null || 
        contains(["NONE", "AWS_IAM", "CUSTOM", "JWT"], route_config.authorization_type)
      ]
    ]))
    error_message = "Route authorization type must be 'NONE', 'AWS_IAM', 'CUSTOM', or 'JWT'."
  }
}

# =============================================================================
# Custom Domain Configuration
# =============================================================================

variable "rest_api_custom_domains" {
  description = "Custom domain configurations for REST APIs"
  type = map(object({
    api_name                    = string
    domain_name                = string
    certificate_arn            = optional(string)
    certificate_name           = optional(string)
    certificate_body           = optional(string)
    certificate_chain          = optional(string)
    certificate_private_key    = optional(string)
    regional_certificate_arn   = optional(string)
    regional_certificate_name  = optional(string)
    security_policy           = optional(string, "TLS_1_2")
    
    endpoint_configuration = optional(object({
      types = list(string)
    }))
    
    mutual_tls_authentication = optional(object({
      truststore_uri     = string
      truststore_version = optional(string)
    }))
    
    base_path_mappings = optional(object({
      stage_name = string
      base_path  = optional(string)
    }))
    
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.rest_api_custom_domains : 
      can(regex("^[a-zA-Z0-9.-]+$", config.domain_name))
    ])
    error_message = "Domain name must be a valid domain name format."
  }

  validation {
    condition = alltrue([
      for name, config in var.rest_api_custom_domains : 
      config.security_policy == null || 
      contains(["TLS_1_0", "TLS_1_2"], config.security_policy)
    ])
    error_message = "Security policy must be 'TLS_1_0' or 'TLS_1_2'."
  }
}

variable "http_api_custom_domains" {
  description = "Custom domain configurations for HTTP APIs"
  type = map(object({
    api_name    = string
    domain_name = string
    
    domain_name_configuration = object({
      certificate_arn                        = string
      endpoint_type                         = string
      security_policy                       = optional(string, "TLS_1_2")
      target_domain_name                    = optional(string)
      hosted_zone_id                        = optional(string)
      ownership_verification_certificate_arn = optional(string)
    })
    
    mutual_tls_authentication = optional(object({
      truststore_uri     = string
      truststore_version = optional(string)
    }))
    
    api_mapping = optional(object({
      stage           = string
      api_mapping_key = optional(string)
    }))
    
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.http_api_custom_domains : 
      can(regex("^[a-zA-Z0-9.-]+$", config.domain_name))
    ])
    error_message = "Domain name must be a valid domain name format."
  }

  validation {
    condition = alltrue([
      for name, config in var.http_api_custom_domains : 
      contains(["REGIONAL"], config.domain_name_configuration.endpoint_type)
    ])
    error_message = "HTTP API domain endpoint type must be 'REGIONAL'."
  }

  validation {
    condition = alltrue([
      for name, config in var.http_api_custom_domains : 
      config.domain_name_configuration.security_policy == null || 
      contains(["TLS_1_2"], config.domain_name_configuration.security_policy)
    ])
    error_message = "HTTP API domain security policy must be 'TLS_1_2'."
  }
}

# =============================================================================
# VPC Links Configuration
# =============================================================================

variable "vpc_links" {
  description = "VPC Links for private integrations"
  type = map(object({
    description = optional(string, "VPC Link managed by Terraform")
    target_arns = list(string)
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.vpc_links : 
      length(config.target_arns) > 0 && length(config.target_arns) <= 1
    ])
    error_message = "VPC Link must have exactly one target ARN (Network Load Balancer)."
  }

  validation {
    condition = alltrue(flatten([
      for name, config in var.vpc_links : [
        for arn in config.target_arns : 
        can(regex("^arn:aws:elasticloadbalancing:", arn))
      ]
    ]))
    error_message = "VPC Link target ARNs must be valid Network Load Balancer ARNs."
  }
}