# =============================================================================
# COMPUTE LAYER VARIABLES
# =============================================================================

# Project Configuration
variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, qa, uat, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# EKS CONFIGURATION
# =============================================================================

variable "enable_eks" {
  description = "Whether to create EKS cluster"
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cluster_addons" {
  description = "Map of EKS cluster add-ons"
  type = map(object({
    addon_version     = optional(string)
    resolve_conflicts = optional(string, "OVERWRITE")
  }))
  default = {
    coredns = {
      addon_version = "v1.10.1-eksbuild.4"
    }
    kube-proxy = {
      addon_version = "v1.28.2-eksbuild.2"
    }
    vpc-cni = {
      addon_version = "v1.15.1-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.24.0-eksbuild.1"
    }
  }
}

variable "eks_node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    ami_type      = optional(string, "AL2_x86_64")
    capacity_type = optional(string, "ON_DEMAND")
    disk_size     = optional(number, 20)
    
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
    
    update_config = optional(object({
      max_unavailable_percentage = optional(number, 25)
    }), {})
    
    # Launch template configuration
    launch_template = optional(object({
      instance_types = optional(list(string))
      user_data     = optional(string)
      key_name      = optional(string)
      
      block_device_mappings = optional(list(object({
        device_name = string
        ebs = object({
          volume_size = number
          volume_type = optional(string, "gp3")
          encrypted   = optional(bool, true)
        })
      })), [])
      
      metadata_options = optional(object({
        http_endpoint               = optional(string, "enabled")
        http_tokens                 = optional(string, "required")
        http_put_response_hop_limit = optional(number, 2)
        instance_metadata_tags      = optional(string, "disabled")
      }), {})
      
      monitoring = optional(object({
        enabled = optional(bool, true)
      }), {})
      
      tag_specifications = optional(list(object({
        resource_type = string
        tags         = map(string)
      })), [])
    }), {})
    
    # Bootstrap arguments for user data
    bootstrap_arguments = optional(string, "")
    
    # Taints
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    
    # Labels
    labels = optional(map(string), {})
  }))
  default = {}
}

variable "eks_fargate_profiles" {
  description = "Map of EKS Fargate profile configurations"
  type = map(object({
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
  }))
  default = {}
}

variable "eks_enable_oidc_provider" {
  description = "Whether to enable OIDC identity provider for EKS cluster"
  type        = bool
  default     = true
}

variable "eks_cluster_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# =============================================================================
# ECS CONFIGURATION
# =============================================================================

variable "enable_ecs" {
  description = "Whether to create ECS cluster"
  type        = bool
  default     = false
}

variable "ecs_capacity_providers" {
  description = "List of ECS capacity providers"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "ecs_default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for ECS cluster"
  type = list(object({
    capacity_provider = string
    weight           = optional(number, 1)
    base             = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight           = 1
      base             = 1
    }
  ]
}

variable "ecs_enable_container_insights" {
  description = "Whether to enable Container Insights for ECS cluster"
  type        = bool
  default     = true
}

variable "ecs_services" {
  description = "Map of ECS service configurations"
  type = map(object({
    task_definition = object({
      family                   = string
      network_mode            = optional(string, "awsvpc")
      requires_compatibilities = optional(list(string), ["FARGATE"])
      cpu                     = optional(string, "256")
      memory                  = optional(string, "512")
      
      containers = list(object({
        name  = string
        image = string
        
        cpu    = optional(number, 0)
        memory = optional(number)
        
        essential = optional(bool, true)
        
        portMappings = optional(list(object({
          containerPort = number
          hostPort      = optional(number)
          protocol      = optional(string, "tcp")
        })), [])
        
        environment = optional(list(object({
          name  = string
          value = string
        })), [])
        
        secrets = optional(map(string), {})
        
        healthCheck = optional(object({
          command     = list(string)
          interval    = optional(number, 30)
          timeout     = optional(number, 5)
          retries     = optional(number, 3)
          startPeriod = optional(number, 0)
        }))
        
        mountPoints = optional(list(object({
          sourceVolume  = string
          containerPath = string
          readOnly      = optional(bool, false)
        })), [])
        
        volumesFrom = optional(list(object({
          sourceContainer = string
          readOnly        = optional(bool, false)
        })), [])
      }))
      
      volumes = optional(list(object({
        name = string
        
        host = optional(object({
          sourcePath = string
        }))
        
        efs_volume_configuration = optional(object({
          file_system_id          = string
          root_directory          = optional(string, "/")
          transit_encryption      = optional(string, "ENABLED")
          transit_encryption_port = optional(number, 2049)
          
          authorization_config = optional(object({
            access_point_id = string
            iam            = optional(string, "ENABLED")
          }))
        }))
      })), [])
    })
    
    # Service Configuration
    desired_count   = optional(number, 1)
    launch_type     = optional(string, "FARGATE")
    platform_version = optional(string, "LATEST")
    
    # Deployment Configuration
    deployment_configuration = optional(object({
      maximum_percent         = optional(number, 200)
      minimum_healthy_percent = optional(number, 100)
      
      deployment_circuit_breaker = optional(object({
        enable   = optional(bool, true)
        rollback = optional(bool, true)
      }), {})
    }), {})
    
    # Auto Scaling
    auto_scaling = optional(object({
      min_capacity = number
      max_capacity = number
      
      target_tracking_scaling_policies = optional(list(object({
        name                = string
        metric_type        = string
        target_value       = number
        scale_in_cooldown  = optional(number, 300)
        scale_out_cooldown = optional(number, 60)
      })), [])
    }))
    
    # Load Balancer Configuration
    load_balancer = optional(object({
      alb_key          = string
      target_group_key = string
      container_name   = string
      container_port   = number
    }))
    
    # Service Discovery
    service_registries = optional(list(object({
      registry_arn   = string
      port          = optional(number)
      container_name = optional(string)
      container_port = optional(number)
    })), [])
    
    # Placement Constraints
    placement_constraints = optional(list(object({
      type       = string
      expression = optional(string)
    })), [])
    
    # Placement Strategy
    placement_strategy = optional(list(object({
      type  = string
      field = optional(string)
    })), [])
  }))
  default = {}
}

variable "ecs_auto_scaling_groups" {
  description = "Configuration for ECS EC2 Auto Scaling Groups"
  type = map(object({
    ami_id      = string
    instance_type = string
    key_name    = optional(string)
    
    min_size         = number
    max_size         = number
    desired_capacity = number
    
    root_volume_size = optional(number, 30)
    
    scaling_policies = optional(list(object({
      name                    = string
      adjustment_type         = string
      policy_type            = optional(string, "TargetTrackingScaling")
      target_value           = optional(number)
      metric_type            = optional(string)
      cooldown               = optional(number, 300)
      scaling_adjustment     = optional(number)
      min_adjustment_magnitude = optional(number)
    })), [])
  }))
  default = {}
}

# =============================================================================
# APPLICATION LOAD BALANCER CONFIGURATION
# =============================================================================

variable "application_load_balancers" {
  description = "Configuration for Application Load Balancers"
  type = map(object({
    scheme = optional(string, "internet-facing")
    
    certificate_arn = optional(string)
    
    target_groups = map(object({
      name_prefix      = string
      port            = number
      protocol        = optional(string, "HTTP")
      protocol_version = optional(string, "HTTP1")
      target_type     = optional(string, "ip")
      
      health_check = optional(object({
        enabled             = optional(bool, true)
        healthy_threshold   = optional(number, 2)
        unhealthy_threshold = optional(number, 2)
        timeout            = optional(number, 5)
        interval           = optional(number, 30)
        path               = optional(string, "/")
        matcher            = optional(string, "200")
        port               = optional(string, "traffic-port")
        protocol           = optional(string, "HTTP")
      }), {})
      
      stickiness = optional(object({
        enabled         = optional(bool, false)
        type           = optional(string, "lb_cookie")
        cookie_duration = optional(number, 86400)
      }))
    }))
    
    listeners = list(object({
      port            = number
      protocol        = string
      certificate_arn = optional(string)
      ssl_policy     = optional(string, "ELBSecurityPolicy-TLS-1-2-2017-01")
      
      default_actions = list(object({
        type = string
        
        target_group_arn = optional(string)
        
        redirect = optional(object({
          port        = string
          protocol    = string
          status_code = string
        }))
        
        fixed_response = optional(object({
          content_type = string
          message_body = optional(string)
          status_code  = string
        }))
      }))
      
      rules = optional(list(object({
        priority = number
        
        conditions = list(object({
          field  = string
          values = list(string)
        }))
        
        actions = list(object({
          type             = string
          target_group_arn = optional(string)
          
          redirect = optional(object({
            port        = string
            protocol    = string
            status_code = string
          }))
          
          fixed_response = optional(object({
            content_type = string
            message_body = optional(string)
            status_code  = string
          }))
        }))
      })), [])
    }))
  }))
  default = {}
}

# =============================================================================
# LAMBDA CONFIGURATION
# =============================================================================

variable "lambda_functions" {
  description = "Configuration for Lambda functions"
  type = map(object({
    filename         = optional(string)
    s3_bucket       = optional(string)
    s3_key          = optional(string)
    s3_object_version = optional(string)
    image_uri       = optional(string)
    
    function_name = string
    description   = optional(string)
    handler      = optional(string)
    runtime      = optional(string)
    package_type = optional(string, "Zip")
    
    memory_size = optional(number, 128)
    timeout     = optional(number, 3)
    
    # VPC Configuration
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
    
    # Environment Variables
    environment_variables = optional(map(string), {})
    
    # Dead Letter Queue
    dead_letter_config = optional(object({
      target_arn = string
    }))
    
    # Tracing
    tracing_mode = optional(string, "PassThrough")
    
    # Reserved Concurrency
    reserved_concurrent_executions = optional(number, -1)
    
    # Provisioned Concurrency
    provisioned_concurrency_config = optional(object({
      provisioned_concurrent_executions = number
    }))
    
    # Code Signing
    code_signing_config_arn = optional(string)
    
    # Architecture
    architectures = optional(list(string), ["x86_64"])
    
    # Layers
    layers = optional(list(string), [])
  }))
  default = {}
}

variable "lambda_layers" {
  description = "Configuration for Lambda layers"
  type = map(object({
    filename         = optional(string)
    s3_bucket       = optional(string)
    s3_key          = optional(string)
    s3_object_version = optional(string)
    
    layer_name      = string
    description     = optional(string)
    
    compatible_runtimes      = list(string)
    compatible_architectures = optional(list(string), ["x86_64"])
    
    license_info = optional(string)
  }))
  default = {}
}

variable "lambda_event_source_mappings" {
  description = "Event source mappings for Lambda functions"
  type = map(object({
    event_source_arn = string
    function_name   = string
    
    starting_position                    = optional(string, "LATEST")
    starting_position_timestamp         = optional(string)
    batch_size                          = optional(number, 10)
    maximum_batching_window_in_seconds  = optional(number, 0)
    enabled                            = optional(bool, true)
    parallelization_factor             = optional(number, 1)
    
    # For Kinesis and DynamoDB
    bisect_batch_on_function_error     = optional(bool, false)
    maximum_record_age_in_seconds      = optional(number, 604800)
    maximum_retry_attempts             = optional(number, 10000)
    tumbling_window_in_seconds         = optional(number)
    
    # For SQS
    function_response_types = optional(list(string), [])
    
    # Destination config
    destination_config = optional(object({
      on_failure = optional(object({
        destination_arn = string
      }))
      on_success = optional(object({
        destination_arn = string
      }))
    }))
    
    # Filter criteria
    filter_criteria = optional(object({
      filters = list(object({
        pattern = string
      }))
    }))
    
    # Source access configuration
    source_access_configurations = optional(list(object({
      type = string
      uri  = string
    })), [])
  }))
  default = {}
}

variable "lambda_function_urls" {
  description = "Function URLs for Lambda functions"
  type = map(object({
    function_name      = string
    authorization_type = optional(string, "AWS_IAM")
    
    cors = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers    = optional(list(string), [])
      allow_methods    = optional(list(string), ["*"])
      allow_origins    = optional(list(string), ["*"])
      expose_headers   = optional(list(string), [])
      max_age         = optional(number, 86400)
    }))
    
    qualifier = optional(string)
  }))
  default = {}
}

variable "lambda_log_level" {
  description = "Log level for Lambda functions"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.lambda_log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
  }
}

# =============================================================================
# API GATEWAY CONFIGURATION
# =============================================================================

variable "enable_api_gateway" {
  description = "Whether to create API Gateway resources"
  type        = bool
  default     = false
}

variable "api_gateway_rest_apis" {
  description = "Configuration for REST API Gateways"
  type = map(object({
    name        = string
    description = optional(string)
    
    # API Configuration
    api_key_source               = optional(string, "HEADER")
    binary_media_types          = optional(list(string), [])
    minimum_compression_size    = optional(number, -1)
    disable_execute_api_endpoint = optional(bool, false)
    
    # Endpoint Configuration
    endpoint_configuration = optional(object({
      types            = list(string)
      vpc_endpoint_ids = optional(list(string), [])
    }), {
      types = ["REGIONAL"]
    })
    
    # Policy
    policy = optional(string)
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateway_http_apis" {
  description = "Configuration for HTTP API Gateways"
  type = map(object({
    name        = string
    description = optional(string)
    version     = optional(string, "1.0")
    
    protocol_type = optional(string, "HTTP")
    
    # CORS Configuration
    cors_configuration = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers    = optional(list(string), [])
      allow_methods    = optional(list(string), [])
      allow_origins    = optional(list(string), [])
      expose_headers   = optional(list(string), [])
      max_age         = optional(number, 86400)
    }))
    
    # Disable Execute API Endpoint
    disable_execute_api_endpoint = optional(bool, false)
    
    # Route Selection Expression
    route_selection_expression = optional(string, "$request.method $request.path")
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateway_rest_custom_domains" {
  description = "Custom domain configurations for REST APIs"
  type = map(object({
    domain_name     = string
    certificate_arn = string
    
    security_policy = optional(string, "TLS_1_2")
    
    # Base path mappings
    base_path_mappings = optional(list(object({
      api_id      = string
      stage_name  = optional(string)
      base_path   = optional(string)
    })), [])
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateway_http_custom_domains" {
  description = "Custom domain configurations for HTTP APIs"
  type = map(object({
    domain_name     = string
    certificate_arn = string
    
    # Domain name configurations
    domain_name_configuration = optional(object({
      certificate_arn                        = string
      endpoint_type                         = optional(string, "REGIONAL")
      security_policy                       = optional(string, "TLS_1_2")
      ownership_verification_certificate_arn = optional(string)
    }))
    
    # Mutual TLS Authentication
    mutual_tls_authentication = optional(object({
      truststore_uri     = string
      truststore_version = optional(string)
    }))
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateway_vpc_links" {
  description = "VPC Link configurations for API Gateway"
  type = map(object({
    name        = string
    description = optional(string)
    
    # For REST API VPC Links
    target_arns = optional(list(string), [])
    
    # For HTTP API VPC Links
    subnet_ids         = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# CLOUDFRONT CONFIGURATION
# =============================================================================

variable "cloudfront_distributions" {
  description = "Configuration for CloudFront distributions"
  type = map(object({
    # Origins Configuration
    origins = list(object({
      domain_name              = string
      origin_id               = string
      origin_path             = optional(string, "")
      connection_attempts     = optional(number, 3)
      connection_timeout      = optional(number, 10)
      
      # Custom Origin Config
      custom_origin_config = optional(object({
        http_port                = optional(number, 80)
        https_port              = optional(number, 443)
        origin_protocol_policy  = string
        origin_ssl_protocols    = optional(list(string), ["TLSv1.2"])
        origin_keepalive_timeout = optional(number, 5)
        origin_read_timeout     = optional(number, 30)
      }))
      
      # S3 Origin Config
      s3_origin_config = optional(object({
        origin_access_identity = string
      }))
      
      # Custom Headers
      custom_header = optional(list(object({
        name  = string
        value = string
      })), [])
    }))
    
    # Default Cache Behavior
    default_cache_behavior = object({
      target_origin_id       = string
      viewer_protocol_policy = string
      
      allowed_methods = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
      cached_methods  = optional(list(string), ["GET", "HEAD"])
      
      compress               = optional(bool, true)
      query_string           = optional(bool, false)
      query_string_cache_keys = optional(list(string), [])
      
      headers = optional(list(string), [])
      
      cookies = optional(object({
        forward           = string
        whitelisted_names = optional(list(string), [])
      }), {
        forward = "none"
      })
      
      # TTL Settings
      min_ttl     = optional(number, 0)
      default_ttl = optional(number, 86400)
      max_ttl     = optional(number, 31536000)
      
      # Lambda@Edge Functions
      lambda_function_associations = optional(list(object({
        event_type   = string
        lambda_arn   = string
        include_body = optional(bool, false)
      })), [])
      
      # CloudFront Functions
      function_associations = optional(list(object({
        event_type   = string
        function_arn = string
      })), [])
      
      # Trusted Key Groups
      trusted_key_groups = optional(list(string), [])
      
      # Trusted Signers
      trusted_signers = optional(list(string), [])
      
      # Field Level Encryption
      field_level_encryption_id = optional(string)
      
      # Real-time Logs
      realtime_log_config_arn = optional(string)
      
      # Response Headers Policy
      response_headers_policy_id = optional(string)
      
      # Origin Request Policy
      origin_request_policy_id = optional(string)
      
      # Cache Policy
      cache_policy_id = optional(string)
    })
    
    # Ordered Cache Behaviors
    ordered_cache_behaviors = optional(list(object({
      path_pattern           = string
      target_origin_id       = string
      viewer_protocol_policy = string
      
      allowed_methods = optional(list(string), ["GET", "HEAD"])
      cached_methods  = optional(list(string), ["GET", "HEAD"])
      
      compress = optional(bool, true)
      
      query_string           = optional(bool, false)
      query_string_cache_keys = optional(list(string), [])
      
      headers = optional(list(string), [])
      
      cookies = optional(object({
        forward           = string
        whitelisted_names = optional(list(string), [])
      }), {
        forward = "none"
      })
      
      # TTL Settings
      min_ttl     = optional(number, 0)
      default_ttl = optional(number, 86400)
      max_ttl     = optional(number, 31536000)
      
      # Lambda@Edge Functions
      lambda_function_associations = optional(list(object({
        event_type   = string
        lambda_arn   = string
        include_body = optional(bool, false)
      })), [])
      
      # CloudFront Functions
      function_associations = optional(list(object({
        event_type   = string
        function_arn = string
      })), [])
      
      # Trusted Key Groups
      trusted_key_groups = optional(list(string), [])
      
      # Trusted Signers
      trusted_signers = optional(list(string), [])
      
      # Field Level Encryption
      field_level_encryption_id = optional(string)
      
      # Real-time Logs
      realtime_log_config_arn = optional(string)
      
      # Response Headers Policy
      response_headers_policy_id = optional(string)
      
      # Origin Request Policy
      origin_request_policy_id = optional(string)
      
      # Cache Policy
      cache_policy_id = optional(string)
    })), [])
    
    # SSL Certificate
    viewer_certificate = object({
      acm_certificate_arn            = optional(string)
      cloudfront_default_certificate = optional(bool, false)
      iam_certificate_id            = optional(string)
      minimum_protocol_version      = optional(string, "TLSv1.2_2021")
      ssl_support_method            = optional(string, "sni-only")
    })
    
    # Geo Restriction
    geo_restriction = optional(object({
      restriction_type = string
      locations       = optional(list(string), [])
    }))
    
    # Additional Configuration
    aliases             = optional(list(string), [])
    comment            = optional(string, "")
    default_root_object = optional(string, "index.html")
    enabled            = optional(bool, true)
    is_ipv6_enabled    = optional(bool, true)
    price_class        = optional(string, "PriceClass_100")
    retain_on_delete   = optional(bool, false)
    wait_for_deployment = optional(bool, true)
    
    # Custom Error Response
    custom_error_responses = optional(list(object({
      error_code            = number
      error_caching_min_ttl = optional(number, 10)
      response_code         = optional(number)
      response_page_path    = optional(string)
    })), [])
  }))
  default = {}
}

# =============================================================================
# ELASTIC BEANSTALK CONFIGURATION
# =============================================================================

variable "elastic_beanstalk_applications" {
  description = "Configuration for Elastic Beanstalk applications"
  type = map(object({
    description = optional(string)
    
    # Application Versions
    application_versions = optional(list(object({
      name        = string
      description = optional(string)
      bucket     = string
      key        = string
    })), [])
    
    # Environments
    environments = map(object({
      # Basic Configuration
      description = optional(string)
      tier        = optional(string, "WebServer")
      
      # Platform Configuration
      solution_stack_name = optional(string)
      platform_arn       = optional(string)
      
      # Version Configuration
      version_label = optional(string)
      
      # Template Configuration
      template_name = optional(string)
      
      # Environment Settings
      settings = optional(list(object({
        namespace = string
        name      = string
        value     = string
        resource  = optional(string)
      })), [])
      
      # Environment Variables
      environment_variables = optional(map(string), {})
      
      # Tags
      tags = optional(map(string), {})
      
      # Wait for Ready Timeout
      wait_for_ready_timeout = optional(string, "20m")
      
      # Polling Interval
      poll_interval = optional(string, "10s")
    }))
  }))
  default = {}
}

# =============================================================================
# BATCH CONFIGURATION
# =============================================================================

variable "batch_compute_environments" {
  description = "Configuration for AWS Batch compute environments"
  type = map(object({
    # Compute Environment Configuration
    compute_environment_name_prefix = optional(string)
    type                           = optional(string, "MANAGED")
    state                          = optional(string, "ENABLED")
    
    # Compute Resources
    compute_resources = object({
      # Instance Configuration
      type                = string
      allocation_strategy = optional(string, "BEST_FIT_PROGRESSIVE")
      
      min_vcpus     = optional(number, 0)
      max_vcpus     = number
      desired_vcpus = optional(number, 0)
      
      instance_types = list(string)
      
      # Launch Template
      launch_template = optional(object({
        launch_template_id = optional(string)
        launch_template_name = optional(string)
        version            = optional(string, "$Latest")
      }))
      
      # EC2 Configuration
      ec2_key_pair                = optional(string)
      ec2_configuration = optional(list(object({
        image_type                = optional(string, "ECS_AL2")
        image_id_override        = optional(string)
        image_kubernetes_version = optional(string)
      })), [])
      
      # Spot Configuration (for SPOT instances)
      spot_iam_fleet_request_role = optional(string)
      bid_percentage             = optional(number, 50)
      
      # Placement Group
      placement_group = optional(string)
      
      # Tags
      instance_role = string
      tags         = optional(map(string), {})
    })
    
    # Service Role
    service_role = optional(string)
    
    # Job Queues
    job_queues = list(object({
      name                 = string
      state               = optional(string, "ENABLED")
      priority            = number
      compute_environment_order = optional(list(object({
        order               = number
        compute_environment = string
      })), [])
      
      tags = optional(map(string), {})
    }))
    
    # Job Definitions
    job_definitions = list(object({
      name = string
      type = optional(string, "container")
      
      # Platform Capabilities
      platform_capabilities = optional(list(string), ["EC2"])
      
      # Parameters
      parameters = optional(map(string), {})
      
      # Container Properties (for container type)
      container_properties = optional(object({
        image  = string
        vcpus  = optional(number, 1)
        memory = number
        
        job_role_arn = optional(string)
        
        # Environment
        environment = optional(list(object({
          name  = string
          value = string
        })), [])
        
        # Mount Points
        mount_points = optional(list(object({
          source_volume  = string
          container_path = string
          read_only      = optional(bool, false)
        })), [])
        
        # Volumes
        volumes = optional(list(object({
          name = string
          
          host = optional(object({
            source_path = string
          }))
          
          efs_volume_configuration = optional(object({
            file_system_id          = string
            root_directory          = optional(string, "/")
            transit_encryption      = optional(string, "ENABLED")
            transit_encryption_port = optional(number, 2049)
            
            authorization_config = optional(object({
              access_point_id = string
              iam            = optional(string, "ENABLED")
            }))
          }))
        })), [])
        
        # Ulimits
        ulimits = optional(list(object({
          hard_limit = number
          name       = string
          soft_limit = number
        })), [])
        
        # Linux Parameters
        linux_parameters = optional(object({
          devices = optional(list(object({
            host_path      = string
            container_path = optional(string)
            permissions    = optional(list(string), ["read"])
          })), [])
          
          init_process_enabled = optional(bool, false)
          shared_memory_size  = optional(number)
          tmpfs = optional(list(object({
            container_path = string
            size          = number
            mount_options = optional(list(string), [])
          })), [])
          
          max_swap              = optional(number)
          swappiness           = optional(number)
        }))
        
        # Log Configuration
        log_configuration = optional(object({
          log_driver = string
          options   = optional(map(string), {})
          secret_options = optional(list(object({
            name       = string
            value_from = string
          })), [])
        }))
        
        # Secrets
        secrets = optional(list(object({
          name       = string
          value_from = string
        })), [])
        
        # Fargate Platform Configuration
        fargate_platform_configuration = optional(object({
          platform_version = optional(string, "LATEST")
        }))
        
        # Network Configuration (for Fargate)
        network_configuration = optional(object({
          assign_public_ip = optional(bool, false)
        }))
        
        # Execution Role ARN (for Fargate)
        execution_role_arn = optional(string)
        
        # Resource Requirements (for Fargate)
        resource_requirements = optional(list(object({
          type  = string
          value = string
        })), [])
      }))
      
      # Node Properties (for multinode type)
      node_properties = optional(object({
        main_node    = number
        num_nodes    = number
        node_range_properties = list(object({
          target_nodes = string
          container = object({
            image  = string
            vcpus  = optional(number, 1)
            memory = number
            
            # Same container properties as above...
          })
        }))
      }))
      
      # Retry Strategy
      retry_strategy = optional(object({
        attempts = number
      }))
      
      # Timeout
      timeout = optional(object({
        attempt_duration_seconds = number
      }))
      
      tags = optional(map(string), {})
    }))
  }))
  default = {}
}

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "enable_waf" {
  description = "Whether to associate WAF with load balancers and CloudFront"
  type        = bool
  default     = true
}