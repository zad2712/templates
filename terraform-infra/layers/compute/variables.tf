# =============================================================================
# COMPUTE LAYER VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
  validation {
    condition = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "state_bucket" {
  description = "S3 bucket for storing Terraform state"
  type        = string
}



# =============================================================================
# ECS CONFIGURATION
# =============================================================================

variable "enable_ecs" {
  description = "Enable ECS cluster"
  type        = bool
  default     = false
}

variable "ecs_capacity_providers" {
  description = "ECS capacity providers"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "enable_container_insights" {
  description = "Enable container insights for ECS"
  type        = bool
  default     = true
}

# =============================================================================
# LAMBDA CONFIGURATION
# =============================================================================

variable "lambda_functions" {
  description = "Map of Lambda functions to create"
  type = map(object({
    description  = string
    runtime      = string
    handler      = string
    filename     = optional(string)
    s3_bucket    = optional(string)
    s3_key       = optional(string)
    memory_size  = optional(number, 128)
    timeout      = optional(number, 3)
    environment_variables = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# EKS CONFIGURATION
# =============================================================================

variable "enable_eks" {
  description = "Enable EKS cluster"
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "eks_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "eks_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cluster_log_types" {
  description = "A list of the desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_log_retention_days" {
  description = "Number of days to retain log events in CloudWatch log group"
  type        = number
  default     = 7
}

variable "eks_encryption_enabled" {
  description = "Enable encryption of Kubernetes secrets"
  type        = bool
  default     = true
}

variable "eks_kms_key_id" {
  description = "The ARN of the Key Management Service (KMS) customer master key (CMK)"
  type        = string
  default     = ""
}

variable "eks_node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    ami_type        = optional(string, "AL2_x86_64")
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "SPOT")
    disk_size       = optional(number, 20)
    desired_size    = optional(number, 1)
    max_size        = optional(number, 3)
    min_size        = optional(number, 1)
    max_unavailable_percentage = optional(number, 25)
    labels          = optional(map(string), {})
    taints          = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}

variable "eks_fargate_profiles" {
  description = "Map of Fargate profiles configurations"
  type = map(object({
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
  }))
  default = {}
}

variable "eks_addons" {
  description = "Map of cluster addon configurations"
  type = map(object({
    addon_version               = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "PRESERVE")
    service_account_role_arn    = optional(string)
  }))
  default = {
    vpc-cni = {
      addon_version = "v1.18.1-eksbuild.1"
    }
    coredns = {
      addon_version = "v1.11.1-eksbuild.4"
    }
    kube-proxy = {
      addon_version = "v1.30.0-eksbuild.2"
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.30.0-eksbuild.1"
    }
  }
}

# =============================================================================
# EKS MARKETPLACE ADDONS CONFIGURATION
# =============================================================================

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.8.1"
}

variable "aws_load_balancer_controller_namespace" {
  description = "Namespace to deploy AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_chart_version" {
  description = "Cluster Autoscaler Helm chart version"
  type        = string
  default     = "9.37.0"
}

variable "cluster_autoscaler_namespace" {
  description = "Namespace to deploy Cluster Autoscaler"
  type        = string
  default     = "kube-system"
}

variable "enable_metrics_server" {
  description = "Enable Metrics Server"
  type        = bool
  default     = false
}

variable "metrics_server_chart_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.12.1"
}

variable "metrics_server_namespace" {
  description = "Namespace to deploy Metrics Server"
  type        = string
  default     = "kube-system"
}

variable "enable_aws_node_termination_handler" {
  description = "Enable AWS Node Termination Handler"
  type        = bool
  default     = false
}

variable "aws_node_termination_handler_chart_version" {
  description = "AWS Node Termination Handler Helm chart version"
  type        = string
  default     = "0.21.0"
}

variable "aws_node_termination_handler_namespace" {
  description = "Namespace to deploy AWS Node Termination Handler"
  type        = string
  default     = "kube-system"
}

variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = false
}

variable "external_dns_chart_version" {
  description = "External DNS Helm chart version"
  type        = string
  default     = "1.13.1"
}

variable "external_dns_namespace" {
  description = "Namespace to deploy External DNS"
  type        = string
  default     = "kube-system"
}

variable "external_dns_domain_name" {
  description = "Domain name for External DNS"
  type        = string
  default     = ""
}

# =============================================================================
# API GATEWAY CONFIGURATION
# =============================================================================

variable "enable_api_gateway" {
  description = "Enable API Gateway REST API"
  type        = bool
  default     = false
}

variable "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "v1"
}

variable "api_gateway_endpoint_types" {
  description = "List of endpoint types for API Gateway"
  type        = list(string)
  default     = ["REGIONAL"]
  
  validation {
    condition = alltrue([
      for type in var.api_gateway_endpoint_types : contains(["EDGE", "REGIONAL", "PRIVATE"], type)
    ])
    error_message = "Endpoint types must be one of: EDGE, REGIONAL, PRIVATE."
  }
}

variable "api_gateway_disable_execute_api_endpoint" {
  description = "Whether to disable the default execute-api endpoint"
  type        = bool
  default     = false
}

variable "api_gateway_binary_media_types" {
  description = "List of binary media types supported by the REST API"
  type        = list(string)
  default     = []
}

variable "api_gateway_minimum_compression_size" {
  description = "Minimum response size to compress for the REST API"
  type        = number
  default     = -1
}

variable "api_gateway_policy" {
  description = "JSON formatted policy document that controls access to the API Gateway"
  type        = string
  default     = null
}

# Logging configuration
variable "api_gateway_enable_access_logging" {
  description = "Whether to enable access logging for API Gateway"
  type        = bool
  default     = true
}

variable "api_gateway_enable_execution_logging" {
  description = "Whether to enable execution logging for API Gateway"
  type        = bool
  default     = false
}

variable "api_gateway_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

# Performance configuration
variable "api_gateway_enable_xray_tracing" {
  description = "Whether to enable X-Ray tracing for the API Gateway stage"
  type        = bool
  default     = false
}

variable "api_gateway_cache_cluster_enabled" {
  description = "Whether cache clustering is enabled for the stage"
  type        = bool
  default     = false
}

variable "api_gateway_cache_cluster_size" {
  description = "Size of the cache cluster for the stage"
  type        = string
  default     = "0.5"
}

# Throttling configuration
variable "api_gateway_throttle_settings" {
  description = "Throttle settings for the API Gateway stage"
  type = object({
    rate_limit  = number
    burst_limit = number
  })
  default = null
}

# Stage variables
variable "api_gateway_stage_variables" {
  description = "Map of stage variables"
  type        = map(string)
  default     = {}
}

# API structure configuration
variable "api_gateway_resources" {
  description = "Map of API Gateway resources"
  type = map(object({
    path_part = string
    parent_id = optional(string)
  }))
  default = {}
}

variable "api_gateway_methods" {
  description = "Map of API Gateway methods"
  type = map(object({
    resource_key         = string
    http_method         = string
    authorization       = string
    authorizer_id       = optional(string)
    api_key_required    = optional(bool, false)
    request_validator_id = optional(string)
    request_parameters  = optional(map(bool), {})
    request_models      = optional(map(string), {})
    
    integration = object({
      type                    = string
      integration_http_method = optional(string)
      uri                    = optional(string)
      connection_type        = optional(string, "INTERNET")
      connection_id          = optional(string)
      credentials            = optional(string)
      request_templates      = optional(map(string), {})
      request_parameters     = optional(map(string), {})
      passthrough_behavior   = optional(string, "WHEN_NO_MATCH")
      cache_key_parameters   = optional(list(string), [])
      cache_namespace        = optional(string)
      timeout_milliseconds   = optional(number, 29000)
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

variable "api_gateway_request_validators" {
  description = "Map of API Gateway request validators"
  type = map(object({
    name                        = string
    validate_request_body       = bool
    validate_request_parameters = bool
  }))
  default = {}
}

variable "api_gateway_models" {
  description = "Map of API Gateway models"
  type = map(object({
    name         = string
    content_type = string
    schema       = string
  }))
  default = {}
}

variable "api_gateway_authorizers" {
  description = "Map of API Gateway authorizers"
  type = map(object({
    name                             = string
    type                            = string
    authorizer_uri                  = optional(string)
    authorizer_credentials          = optional(string)
    authorizer_result_ttl_in_seconds = optional(number, 300)
    identity_source                 = optional(string)
    identity_validation_expression  = optional(string)
    provider_arns                   = optional(list(string), [])
  }))
  default = {}
}

variable "api_gateway_usage_plans" {
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

variable "api_gateway_api_keys" {
  description = "Map of API Gateway API keys"
  type = map(object({
    name        = string
    description = optional(string)
    enabled     = optional(bool, true)
    value       = optional(string)
  }))
  default = {}
}

variable "api_gateway_usage_plan_keys" {
  description = "Map of usage plan key associations"
  type = map(object({
    api_key_name     = string
    usage_plan_name  = string
  }))
  default = {}
}

# Custom domain configuration
variable "api_gateway_domain_name" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = null
}

variable "api_gateway_certificate_arn" {
  description = "ARN of the certificate for the domain name"
  type        = string
  default     = null
}

variable "api_gateway_domain_security_policy" {
  description = "Security policy for the domain name"
  type        = string
  default     = "TLS_1_2"
}

variable "api_gateway_domain_endpoint_types" {
  description = "List of endpoint types for the domain name"
  type        = list(string)
  default     = ["REGIONAL"]
}

variable "api_gateway_base_path" {
  description = "Base path for the API Gateway domain mapping"
  type        = string
  default     = null
}

# WAF integration
variable "api_gateway_waf_acl_arn" {
  description = "ARN of the WAF ACL to associate with the API Gateway"
  type        = string
  default     = null
}

# =============================================================================
# TAGGING
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
