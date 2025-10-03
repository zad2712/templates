# API Gateway outputs
output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_arn" {
  description = "ARN of the REST API"
  value       = aws_api_gateway_rest_api.this.arn
}

output "rest_api_name" {
  description = "Name of the REST API"
  value       = aws_api_gateway_rest_api.this.name
}

output "rest_api_execution_arn" {
  description = "Execution ARN part to be used in lambda_permission's source_arn"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "rest_api_root_resource_id" {
  description = "Resource ID of the REST API's root"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}

# Stage outputs
output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_arn" {
  description = "ARN of the API Gateway stage"
  value       = aws_api_gateway_stage.this.arn
}

output "stage_invoke_url" {
  description = "URL to invoke the API pointing to the stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_execution_arn" {
  description = "Execution ARN to be used in lambda_permission's source_arn"
  value       = aws_api_gateway_stage.this.execution_arn
}

# Deployment outputs
output "deployment_id" {
  description = "ID of the deployment"
  value       = aws_api_gateway_deployment.this.id
}

output "deployment_invoke_url" {
  description = "URL to invoke the API pointing to the deployment"
  value       = aws_api_gateway_deployment.this.invoke_url
}

# Resource outputs
output "api_resources" {
  description = "Map of API Gateway resources"
  value = {
    for key, resource in aws_api_gateway_resource.this : key => {
      id        = resource.id
      path      = resource.path
      path_part = resource.path_part
      parent_id = resource.parent_id
    }
  }
}

# Method outputs
output "api_methods" {
  description = "Map of API Gateway methods"
  value = {
    for key, method in aws_api_gateway_method.this : key => {
      id                   = method.id
      resource_id          = method.resource_id
      http_method          = method.http_method
      authorization        = method.authorization
      api_key_required     = method.api_key_required
    }
  }
}

# Authorizer outputs
output "api_authorizers" {
  description = "Map of API Gateway authorizers"
  value = {
    for key, authorizer in aws_api_gateway_authorizer.this : key => {
      id   = authorizer.id
      name = authorizer.name
      type = authorizer.type
    }
  }
}

# Usage plan outputs
output "usage_plans" {
  description = "Map of API Gateway usage plans"
  value = {
    for key, plan in aws_api_gateway_usage_plan.this : key => {
      id   = plan.id
      name = plan.name
      arn  = plan.arn
    }
  }
}

# API key outputs
output "api_keys" {
  description = "Map of API Gateway API keys"
  value = {
    for key, api_key in aws_api_gateway_api_key.this : key => {
      id      = api_key.id
      name    = api_key.name
      enabled = api_key.enabled
      value   = api_key.value
    }
  }
  sensitive = true
}

# Model outputs
output "api_models" {
  description = "Map of API Gateway models"
  value = {
    for key, model in aws_api_gateway_model.this : key => {
      id           = model.id
      name         = model.name
      content_type = model.content_type
    }
  }
}

# Request validator outputs
output "request_validators" {
  description = "Map of API Gateway request validators"
  value = {
    for key, validator in aws_api_gateway_request_validator.this : key => {
      id                          = validator.id
      name                        = validator.name
      validate_request_body       = validator.validate_request_body
      validate_request_parameters = validator.validate_request_parameters
    }
  }
}

# Custom domain outputs
output "domain_name" {
  description = "Custom domain name configuration"
  value = var.domain_name != null ? {
    domain_name                = aws_api_gateway_domain_name.this[0].domain_name
    certificate_arn           = aws_api_gateway_domain_name.this[0].certificate_arn
    cloudfront_domain_name    = aws_api_gateway_domain_name.this[0].cloudfront_domain_name
    cloudfront_zone_id        = aws_api_gateway_domain_name.this[0].cloudfront_zone_id
    regional_certificate_arn  = aws_api_gateway_domain_name.this[0].regional_certificate_arn
    regional_domain_name      = aws_api_gateway_domain_name.this[0].regional_domain_name
    regional_zone_id          = aws_api_gateway_domain_name.this[0].regional_zone_id
  } : null
}

# CloudWatch log group outputs
output "access_log_group_name" {
  description = "Name of the CloudWatch log group for access logs"
  value       = var.enable_access_logging ? aws_cloudwatch_log_group.access_logs[0].name : null
}

output "access_log_group_arn" {
  description = "ARN of the CloudWatch log group for access logs"
  value       = var.enable_access_logging ? aws_cloudwatch_log_group.access_logs[0].arn : null
}

output "execution_log_group_name" {
  description = "Name of the CloudWatch log group for execution logs"
  value       = var.enable_execution_logging ? aws_cloudwatch_log_group.execution_logs[0].name : null
}

output "execution_log_group_arn" {
  description = "ARN of the CloudWatch log group for execution logs"
  value       = var.enable_execution_logging ? aws_cloudwatch_log_group.execution_logs[0].arn : null
}

# CloudWatch IAM role outputs
output "cloudwatch_role_arn" {
  description = "ARN of the CloudWatch IAM role"
  value       = var.enable_access_logging || var.enable_execution_logging ? aws_iam_role.cloudwatch[0].arn : null
}
