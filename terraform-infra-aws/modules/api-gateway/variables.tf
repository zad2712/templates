variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "v1"
}

variable "api_key_source" {
  description = "Source of the API key for requests"
  type        = string
  default     = "HEADER"

  validation {
    condition     = contains(["HEADER", "AUTHORIZER"], var.api_key_source)
    error_message = "API key source must be either HEADER or AUTHORIZER."
  }
}

variable "binary_media_types" {
  description = "List of binary media types supported by the REST API"
  type        = list(string)
  default     = []
}

variable "disable_execute_api_endpoint" {
  description = "Whether clients can invoke your API by using the default execute-api endpoint"
  type        = bool
  default     = false
}

variable "minimum_compression_size" {
  description = "Minimum response size to compress for the REST API"
  type        = number
  default     = -1
}

variable "endpoint_types" {
  description = "List of endpoint types"
  type        = list(string)
  default     = ["EDGE"]

  validation {
    condition = alltrue([
      for type in var.endpoint_types : contains(["EDGE", "REGIONAL", "PRIVATE"], type)
    ])
    error_message = "Endpoint types must be one of: EDGE, REGIONAL, PRIVATE."
  }
}

variable "vpc_endpoint_ids" {
  description = "Set of VPC Endpoint identifiers"
  type        = list(string)
  default     = []
}

variable "api_policy" {
  description = "JSON formatted policy document that controls access to the API Gateway"
  type        = string
  default     = null
}

# Logging configuration
variable "enable_access_logging" {
  description = "Whether to enable access logging for API Gateway"
  type        = bool
  default     = true
}

variable "enable_execution_logging" {
  description = "Whether to enable execution logging for API Gateway"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch logs retention value."
  }
}

# X-Ray tracing
variable "enable_xray_tracing" {
  description = "Whether to enable X-Ray tracing for the API Gateway stage"
  type        = bool
  default     = false
}

# Caching configuration
variable "cache_cluster_enabled" {
  description = "Whether cache clustering is enabled for the stage"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster for the stage"
  type        = string
  default     = "0.5"

  validation {
    condition = contains([
      "0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237"
    ], var.cache_cluster_size)
    error_message = "Cache cluster size must be a valid API Gateway cache cluster size."
  }
}

# Throttling configuration
variable "throttle_settings" {
  description = "Throttle settings for the API Gateway stage"
  type = object({
    rate_limit  = number
    burst_limit = number
  })
  default = null
}

# Stage variables
variable "stage_variables" {
  description = "Map of stage variables"
  type        = map(string)
  default     = {}
}

# API Resources configuration
variable "api_resources" {
  description = "Map of API Gateway resources"
  type = map(object({
    path_part = string
    parent_id = optional(string)
  }))
  default = {}
}

# API Methods configuration
variable "api_methods" {
  description = "Map of API Gateway methods"
  type = map(object({
    resource_key         = string
    http_method          = string
    authorization        = string
    authorizer_id        = optional(string)
    api_key_required     = optional(bool, false)
    request_validator_id = optional(string)
    request_parameters   = optional(map(bool), {})
    request_models       = optional(map(string), {})

    integration = object({
      type                    = string
      integration_http_method = optional(string)
      uri                     = optional(string)
      connection_type         = optional(string, "INTERNET")
      connection_id           = optional(string)
      credentials             = optional(string)
      request_templates       = optional(map(string), {})
      request_parameters      = optional(map(string), {})
      passthrough_behavior    = optional(string, "WHEN_NO_MATCH")
      cache_key_parameters    = optional(list(string), [])
      cache_namespace         = optional(string)
      timeout_milliseconds    = optional(number, 29000)
      tls_config = optional(object({
        insecure_skip_verification = bool
      }))
    })

    responses = map(object({
      status_code         = string
      response_models     = optional(map(string), {})
      response_parameters = optional(map(bool), {})
      integration_response = object({
        selection_pattern   = optional(string)
        response_templates  = optional(map(string), {})
        response_parameters = optional(map(string), {})
        content_handling    = optional(string)
      })
    }))
  }))
  default = {}
}

# Request validators
variable "request_validators" {
  description = "Map of API Gateway request validators"
  type = map(object({
    name                        = string
    validate_request_body       = bool
    validate_request_parameters = bool
  }))
  default = {}
}

# API Models
variable "api_models" {
  description = "Map of API Gateway models"
  type = map(object({
    name         = string
    content_type = string
    schema       = string
  }))
  default = {}
}

# API Authorizers
variable "api_authorizers" {
  description = "Map of API Gateway authorizers"
  type = map(object({
    name                             = string
    type                             = string
    authorizer_uri                   = optional(string)
    authorizer_credentials           = optional(string)
    authorizer_result_ttl_in_seconds = optional(number, 300)
    identity_source                  = optional(string)
    identity_validation_expression   = optional(string)
    provider_arns                    = optional(list(string), [])
  }))
  default = {}
}

# Usage Plans
variable "usage_plans" {
  description = "Map of API Gateway usage plans"
  type = map(object({
    name        = string
    description = optional(string)

    api_stages = list(object({
      stage = string
      throttle = optional(object({
        path        = string
        rate_limit  = number
        burst_limit = number
      }))
    }))

    quota_settings = optional(object({
      limit  = number
      offset = optional(number, 0)
      period = string
    }))

    throttle_settings = optional(object({
      rate_limit  = number
      burst_limit = number
    }))
  }))
  default = {}
}

# API Keys
variable "api_keys" {
  description = "Map of API Gateway API keys"
  type = map(object({
    name        = string
    description = optional(string)
    enabled     = optional(bool, true)
    value       = optional(string)
  }))
  default = {}
}

# Usage Plan Keys (associations)
variable "usage_plan_keys" {
  description = "Map of usage plan key associations"
  type = map(object({
    api_key_name    = string
    usage_plan_name = string
  }))
  default = {}
}

# Custom Domain Configuration
variable "domain_name" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the certificate for the domain name"
  type        = string
  default     = null
}

variable "domain_security_policy" {
  description = "Security policy for the domain name"
  type        = string
  default     = "TLS_1_2"

  validation {
    condition = contains([
      "TLS_1_0", "TLS_1_2"
    ], var.domain_security_policy)
    error_message = "Domain security policy must be either TLS_1_0 or TLS_1_2."
  }
}

variable "domain_endpoint_types" {
  description = "List of endpoint types for the domain name"
  type        = list(string)
  default     = ["EDGE"]

  validation {
    condition = alltrue([
      for type in var.domain_endpoint_types : contains(["EDGE", "REGIONAL"], type)
    ])
    error_message = "Domain endpoint types must be either EDGE or REGIONAL."
  }
}

variable "base_path" {
  description = "Base path for the API Gateway domain mapping"
  type        = string
  default     = null
}

# WAF Integration
variable "waf_acl_arn" {
  description = "ARN of the WAF ACL to associate with the API Gateway"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
