# =============================================================================
# COMPUTE LAYER OUTPUTS
# =============================================================================

# EKS Outputs
output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_id : null
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = var.enable_eks ? module.eks[0].cluster_arn : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_security_group_id : null
}

output "eks_cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_iam_role_name : null
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = var.enable_eks ? module.eks[0].cluster_certificate_authority_data : null
  sensitive   = true
}

output "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = var.enable_eks ? module.eks[0].cluster_version : null
}

output "eks_cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = var.enable_eks ? module.eks[0].cluster_platform_version : null
}

output "eks_cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = var.enable_eks ? module.eks[0].cluster_status : null
}

output "eks_node_groups" {
  description = "EKS node groups"
  value       = var.enable_eks ? module.eks[0].node_groups : {}
}

output "eks_fargate_profiles" {
  description = "EKS Fargate profiles"
  value       = var.enable_eks ? module.eks[0].fargate_profiles : {}
}

output "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = var.enable_eks ? module.eks[0].cluster_oidc_issuer_url : null
}

output "eks_addon_arns" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = var.enable_eks ? module.eks[0].cluster_addons : {}
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = var.enable_ecs ? module.ecs[0].cluster_id : null
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = var.enable_ecs ? module.ecs[0].cluster_arn : null
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.enable_ecs ? module.ecs[0].cluster_name : null
}

output "ecs_capacity_providers" {
  description = "Map of capacity providers created and their attributes"
  value       = var.enable_ecs ? module.ecs[0].capacity_providers : {}
}

output "ecs_services" {
  description = "Map of services created and their attributes"
  value       = var.enable_ecs ? module.ecs[0].services : {}
}

output "ecs_task_definitions" {
  description = "Map of task definitions created and their attributes"
  value       = var.enable_ecs ? module.ecs[0].task_definitions : {}
}

output "ecs_auto_scaling_groups" {
  description = "Map of Auto Scaling Groups created for ECS"
  value = var.enable_ecs ? {
    for key, asg in module.ecs_asg : key => {
      id   = asg.auto_scaling_group_id
      arn  = asg.auto_scaling_group_arn
      name = asg.auto_scaling_group_name
    }
  } : {}
}

# Application Load Balancer Outputs
output "alb_arns" {
  description = "ARNs of the Application Load Balancers"
  value = {
    for key, alb in module.alb : key => alb.lb_arn
  }
}

output "alb_dns_names" {
  description = "DNS names of the Application Load Balancers"
  value = {
    for key, alb in module.alb : key => alb.lb_dns_name
  }
}

output "alb_hosted_zone_ids" {
  description = "Hosted zone IDs of the Application Load Balancers"
  value = {
    for key, alb in module.alb : key => alb.lb_zone_id
  }
}

output "alb_target_group_arns" {
  description = "ARNs of the target groups"
  value = {
    for key, alb in module.alb : key => alb.target_group_arns
  }
}

output "alb_listener_arns" {
  description = "ARNs of the load balancer listeners"
  value = {
    for key, alb in module.alb : key => alb.listener_arns
  }
}

output "alb_security_group_ids" {
  description = "Security group IDs attached to the load balancers"
  value = {
    for key, alb in module.alb : key => alb.security_group_id
  }
}

# Lambda Outputs
output "lambda_function_arns" {
  description = "ARNs of the Lambda functions"
  value = module.lambda.function_arns
}

output "lambda_function_names" {
  description = "Names of the Lambda functions"
  value = module.lambda.function_names
}

output "lambda_function_invoke_arns" {
  description = "Invoke ARNs of the Lambda functions"
  value = module.lambda.function_invoke_arns
}

output "lambda_function_qualified_arns" {
  description = "Qualified ARNs of the Lambda functions"
  value = module.lambda.function_qualified_arns
}

output "lambda_function_versions" {
  description = "Latest published versions of the Lambda functions"
  value = module.lambda.function_versions
}

output "lambda_layer_arns" {
  description = "ARNs of the Lambda layers"
  value = module.lambda.layer_arns
}

output "lambda_layer_versions" {
  description = "Versions of the Lambda layers"
  value = module.lambda.layer_versions
}

output "lambda_event_source_mapping_uuids" {
  description = "UUIDs of the Lambda event source mappings"
  value = module.lambda.event_source_mapping_uuids
}

output "lambda_function_url_endpoints" {
  description = "HTTP URLs of the Lambda function URLs"
  value = module.lambda.function_url_endpoints
  sensitive = true
}

output "lambda_cloudwatch_log_group_names" {
  description = "Names of the CloudWatch log groups for Lambda functions"
  value = module.lambda.cloudwatch_log_group_names
}

# API Gateway Outputs
output "api_gateway_rest_api_ids" {
  description = "IDs of the REST API Gateways"
  value = var.enable_api_gateway ? module.api_gateway[0].rest_api_ids : {}
}

output "api_gateway_rest_api_arns" {
  description = "ARNs of the REST API Gateways"
  value = var.enable_api_gateway ? module.api_gateway[0].rest_api_arns : {}
}

output "api_gateway_rest_api_root_resource_ids" {
  description = "Root resource IDs of the REST API Gateways"
  value = var.enable_api_gateway ? module.api_gateway[0].rest_api_root_resource_ids : {}
}

output "api_gateway_rest_api_execution_arns" {
  description = "Execution ARNs of the REST API Gateways"
  value = var.enable_api_gateway ? module.api_gateway[0].rest_api_execution_arns : {}
}

output "api_gateway_http_api_ids" {
  description = "IDs of the HTTP API Gateways"
  value = var.enable_api_gateway ? module.api_gateway[0].http_api_ids : {}
}

output "api_gateway_http_api_arns" {
  description = "ARNs of the HTTP API Gateways"
  value = var.enable_api_gateway ? module.api_gateway[0].http_api_arns : {}
}

output "api_gateway_http_api_execution_arns" {
  description = "Execution ARNs of the HTTP API Gateways"
  value = var.enable_api_gateway ? module.api_gateway[0].http_api_execution_arns : {}
}

output "api_gateway_http_api_endpoints" {
  description = "HTTP API Gateway endpoints"
  value = var.enable_api_gateway ? module.api_gateway[0].http_api_endpoints : {}
}

output "api_gateway_rest_custom_domain_names" {
  description = "Custom domain names for REST APIs"
  value = var.enable_api_gateway ? module.api_gateway[0].rest_custom_domain_names : {}
}

output "api_gateway_http_custom_domain_names" {
  description = "Custom domain names for HTTP APIs"
  value = var.enable_api_gateway ? module.api_gateway[0].http_custom_domain_names : {}
}

output "api_gateway_vpc_link_ids" {
  description = "IDs of the API Gateway VPC Links"
  value = var.enable_api_gateway ? module.api_gateway[0].vpc_link_ids : {}
}

output "api_gateway_vpc_link_arns" {
  description = "ARNs of the API Gateway VPC Links"
  value = var.enable_api_gateway ? module.api_gateway[0].vpc_link_arns : {}
}

# CloudFront Outputs
output "cloudfront_distribution_ids" {
  description = "IDs of the CloudFront distributions"
  value = {
    for key, cf in module.cloudfront : key => cf.cloudfront_distribution_id
  }
}

output "cloudfront_distribution_arns" {
  description = "ARNs of the CloudFront distributions"
  value = {
    for key, cf in module.cloudfront : key => cf.cloudfront_distribution_arn
  }
}

output "cloudfront_distribution_domain_names" {
  description = "Domain names of the CloudFront distributions"
  value = {
    for key, cf in module.cloudfront : key => cf.cloudfront_distribution_domain_name
  }
}

output "cloudfront_distribution_hosted_zone_ids" {
  description = "Hosted zone IDs of the CloudFront distributions"
  value = {
    for key, cf in module.cloudfront : key => cf.cloudfront_distribution_hosted_zone_id
  }
}

output "cloudfront_distribution_statuses" {
  description = "Statuses of the CloudFront distributions"
  value = {
    for key, cf in module.cloudfront : key => cf.cloudfront_distribution_status
  }
}

output "cloudfront_origin_access_identity_ids" {
  description = "IDs of the CloudFront origin access identities"
  value = {
    for key, cf in module.cloudfront : key => cf.cloudfront_origin_access_identity_id
  }
}

output "cloudfront_origin_access_identity_iam_arns" {
  description = "IAM ARNs of the CloudFront origin access identities"
  value = {
    for key, cf in module.cloudfront : key => cf.cloudfront_origin_access_identity_iam_arn
  }
}

# Elastic Beanstalk Outputs
output "elastic_beanstalk_application_names" {
  description = "Names of the Elastic Beanstalk applications"
  value = {
    for key, eb in module.elastic_beanstalk : key => eb.application_name
  }
}

output "elastic_beanstalk_application_arns" {
  description = "ARNs of the Elastic Beanstalk applications"
  value = {
    for key, eb in module.elastic_beanstalk : key => eb.application_arn
  }
}

output "elastic_beanstalk_environment_names" {
  description = "Names of the Elastic Beanstalk environments"
  value = {
    for key, eb in module.elastic_beanstalk : key => eb.environment_names
  }
}

output "elastic_beanstalk_environment_ids" {
  description = "IDs of the Elastic Beanstalk environments"
  value = {
    for key, eb in module.elastic_beanstalk : key => eb.environment_ids
  }
}

output "elastic_beanstalk_environment_arns" {
  description = "ARNs of the Elastic Beanstalk environments"
  value = {
    for key, eb in module.elastic_beanstalk : key => eb.environment_arns
  }
}

output "elastic_beanstalk_environment_endpoints" {
  description = "Endpoints of the Elastic Beanstalk environments"
  value = {
    for key, eb in module.elastic_beanstalk : key => eb.environment_endpoints
  }
}

output "elastic_beanstalk_environment_cnames" {
  description = "CNAMEs of the Elastic Beanstalk environments"
  value = {
    for key, eb in module.elastic_beanstalk : key => eb.environment_cnames
  }
}

# AWS Batch Outputs
output "batch_compute_environment_arns" {
  description = "ARNs of the Batch compute environments"
  value = {
    for key, batch in module.batch : key => batch.compute_environment_arn
  }
}

output "batch_compute_environment_ecs_cluster_arns" {
  description = "ECS cluster ARNs of the Batch compute environments"
  value = {
    for key, batch in module.batch : key => batch.compute_environment_ecs_cluster_arn
  }
}

output "batch_job_queue_arns" {
  description = "ARNs of the Batch job queues"
  value = {
    for key, batch in module.batch : key => batch.job_queue_arns
  }
}

output "batch_job_definition_arns" {
  description = "ARNs of the Batch job definitions"
  value = {
    for key, batch in module.batch : key => batch.job_definition_arns
  }
}

output "batch_job_definition_revisions" {
  description = "Revisions of the Batch job definitions"
  value = {
    for key, batch in module.batch : key => batch.job_definition_revisions
  }
}

# IAM Outputs for Compute Services
output "compute_iam_role_arns" {
  description = "ARNs of compute-specific IAM roles"
  value = merge(
    # ECS Instance Roles
    var.enable_ecs ? {
      for key, role in aws_iam_role.ecs_instance_role : 
      "ecs_instance_${key}" => role.arn
    } : {},
    
    # Batch Roles
    {
      for key, role in aws_iam_role.batch_service_role : 
      "batch_service_${key}" => role.arn
    },
    {
      for key, role in aws_iam_role.batch_instance_role : 
      "batch_instance_${key}" => role.arn
    },
    {
      for key, role in aws_iam_role.batch_spot_fleet_role : 
      "batch_spot_fleet_${key}" => role.arn
    }
  )
}

output "compute_iam_instance_profile_arns" {
  description = "ARNs of compute-specific IAM instance profiles"
  value = merge(
    # ECS Instance Profiles
    var.enable_ecs ? {
      for key, profile in aws_iam_instance_profile.ecs_instance_profile : 
      "ecs_${key}" => profile.arn
    } : {},
    
    # Batch Instance Profiles
    {
      for key, profile in aws_iam_instance_profile.batch_instance_profile : 
      "batch_${key}" => profile.arn
    }
  )
}

# Service Discovery Outputs
output "service_discovery_endpoints" {
  description = "Service discovery endpoints for compute services"
  value = {
    # EKS Services
    eks = var.enable_eks ? {
      cluster_endpoint = module.eks[0].cluster_endpoint
      oidc_issuer_url = module.eks[0].cluster_oidc_issuer_url
    } : null
    
    # ECS Services
    ecs = var.enable_ecs ? {
      cluster_name = module.ecs[0].cluster_name
      services = {
        for key, service in module.ecs[0].services : key => {
          name = service.name
          arn  = service.id
        }
      }
    } : null
    
    # Lambda Functions
    lambda = {
      for key, function in module.lambda.function_arns : key => {
        name        = module.lambda.function_names[key]
        arn         = function
        invoke_arn  = module.lambda.function_invoke_arns[key]
      }
    }
    
    # API Gateway
    api_gateway = var.enable_api_gateway ? {
      rest_apis = {
        for key, api_id in module.api_gateway[0].rest_api_ids : key => {
          id           = api_id
          execution_arn = module.api_gateway[0].rest_api_execution_arns[key]
        }
      }
      http_apis = {
        for key, api_id in module.api_gateway[0].http_api_ids : key => {
          id           = api_id
          endpoint     = module.api_gateway[0].http_api_endpoints[key]
          execution_arn = module.api_gateway[0].http_api_execution_arns[key]
        }
      }
    } : null
    
    # Load Balancers
    load_balancers = {
      for key, dns_name in {
        for key, alb in module.alb : key => alb.lb_dns_name
      } : key => {
        dns_name        = dns_name
        hosted_zone_id = module.alb[key].lb_zone_id
        arn            = module.alb[key].lb_arn
      }
    }
    
    # CloudFront Distributions
    cloudfront = {
      for key, domain_name in {
        for key, cf in module.cloudfront : key => cf.cloudfront_distribution_domain_name
      } : key => {
        domain_name     = domain_name
        distribution_id = module.cloudfront[key].cloudfront_distribution_id
        hosted_zone_id  = module.cloudfront[key].cloudfront_distribution_hosted_zone_id
      }
    }
  }
}

# Compute Resource Summary
output "compute_resource_summary" {
  description = "Summary of all compute resources created"
  value = {
    eks = {
      enabled = var.enable_eks
      clusters = var.enable_eks ? 1 : 0
      node_groups = var.enable_eks ? length(var.eks_node_groups) : 0
      fargate_profiles = var.enable_eks ? length(var.eks_fargate_profiles) : 0
    }
    
    ecs = {
      enabled = var.enable_ecs
      clusters = var.enable_ecs ? 1 : 0
      services = var.enable_ecs ? length(var.ecs_services) : 0
      auto_scaling_groups = var.enable_ecs ? length(var.ecs_auto_scaling_groups) : 0
    }
    
    lambda = {
      functions = length(var.lambda_functions)
      layers = length(var.lambda_layers)
      event_source_mappings = length(var.lambda_event_source_mappings)
      function_urls = length(var.lambda_function_urls)
    }
    
    api_gateway = {
      enabled = var.enable_api_gateway
      rest_apis = var.enable_api_gateway ? length(var.api_gateway_rest_apis) : 0
      http_apis = var.enable_api_gateway ? length(var.api_gateway_http_apis) : 0
      vpc_links = var.enable_api_gateway ? length(var.api_gateway_vpc_links) : 0
    }
    
    load_balancers = {
      application_load_balancers = length(var.application_load_balancers)
    }
    
    cloudfront = {
      distributions = length(var.cloudfront_distributions)
    }
    
    elastic_beanstalk = {
      applications = length(var.elastic_beanstalk_applications)
    }
    
    batch = {
      compute_environments = length(var.batch_compute_environments)
    }
  }
}