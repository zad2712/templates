# API Gateway Terraform Module

## Overview

This Terraform module creates a comprehensive **Amazon API Gateway REST API** with enterprise-grade features following AWS best practices. The module supports complete API lifecycle management including resources, methods, integrations, authorization, throttling, monitoring, and custom domains.

## Features

### 🌟 **Core API Gateway Features**
- **REST API Management**: Complete API lifecycle with resources, methods, and integrations
- **Multiple Authorization Types**: API Key, IAM, Cognito, Lambda authorizers
- **Request/Response Validation**: Schema-based validation with custom models
- **Throttling & Rate Limiting**: Usage plans with quota and rate controls
- **Custom Domain Support**: SSL/TLS termination with custom certificates
- **Multi-Stage Deployment**: Support for dev, test, prod environments

### 🔒 **Security & Compliance**
- **WAF Integration**: Web Application Firewall protection
- **IAM Integration**: Fine-grained access controls
- **API Key Management**: Secure API key generation and rotation
- **Request Validation**: Input sanitization and validation
- **CORS Configuration**: Cross-origin resource sharing controls

### 📊 **Monitoring & Observability**
- **CloudWatch Integration**: Comprehensive logging and metrics
- **X-Ray Tracing**: Distributed tracing for performance analysis
- **Access Logging**: Detailed request/response logging
- **Custom Metrics**: Business and operational metrics
- **Alerting**: CloudWatch alarms for key metrics

### ⚡ **Performance Optimization**
- **Response Caching**: Configurable cache clusters for improved performance
- **Compression**: Automatic response compression
- **Connection Pooling**: Optimized backend connections
- **Regional Endpoints**: Reduced latency with regional deployments

## Usage Examples

### Basic API Gateway

```hcl
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name        = "my-rest-api"
  api_description = "REST API for my application"
  stage_name      = "v1"

  # Basic API structure
  api_resources = {
    users = {
      path_part = "users"
    }
    user_detail = {
      path_part = "{id}"
      parent_id = module.api_gateway.api_resources["users"].id
    }
  }

  # API methods
  api_methods = {
    get_users = {
      resource_key  = "users"
      http_method   = "GET"
      authorization = "NONE"
      
      integration = {
        type                    = "AWS_PROXY"
        integration_http_method = "POST"
        uri                    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.get_users.arn}/invocations"
      }
      
      responses = {
        "200" = {
          status_code = "200"
          response_models = {
            "application/json" = "Empty"
          }
          integration_response = {
            response_templates = {
              "application/json" = ""
            }
          }
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Production API with Authentication

```hcl
module "secure_api_gateway" {
  source = "../../modules/api-gateway"

  api_name        = "secure-api"
  api_description = "Production API with full security features"
  stage_name      = "v1"

  # Enable security features
  enable_access_logging    = true
  enable_execution_logging = false
  enable_xray_tracing     = true
  log_retention_days      = 30

  # Request validation
  request_validators = {
    validate_body = {
      name                        = "validate-body"
      validate_request_body       = true
      validate_request_parameters = false
    }
    validate_params = {
      name                        = "validate-params"
      validate_request_body       = false
      validate_request_parameters = true
    }
  }

  # API models for validation
  api_models = {
    user_model = {
      name         = "UserModel"
      content_type = "application/json"
      schema = jsonencode({
        "$schema": "http://json-schema.org/draft-04/schema#",
        "title": "User Schema",
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "age": { "type": "integer", "minimum": 0 }
        },
        "required": ["name", "email"]
      })
    }
  }

  # Lambda authorizer
  api_authorizers = {
    lambda_auth = {
      name                             = "lambda-authorizer"
      type                            = "TOKEN"
      authorizer_uri                  = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer.arn}/invocations"
      authorizer_credentials          = aws_iam_role.authorizer_role.arn
      identity_source                 = "method.request.header.Authorization"
      authorizer_result_ttl_in_seconds = 300
    }
  }

  # API resources and methods
  api_resources = {
    api = {
      path_part = "api"
    }
    users = {
      path_part = "users"
      parent_id = "api"
    }
  }

  api_methods = {
    post_user = {
      resource_key         = "users"
      http_method         = "POST"
      authorization       = "CUSTOM"
      authorizer_id       = "lambda_auth"
      api_key_required    = true
      request_validator_id = "validate_body"
      request_models = {
        "application/json" = "UserModel"
      }
      
      integration = {
        type                    = "AWS_PROXY"
        integration_http_method = "POST"
        uri                    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.create_user.arn}/invocations"
      }
      
      responses = {
        "201" = {
          status_code = "201"
          response_models = {
            "application/json" = "UserModel"
          }
          integration_response = {
            response_templates = {
              "application/json" = ""
            }
          }
        }
        "400" = {
          status_code = "400"
          integration_response = {
            selection_pattern = "4\\d{2}"
            response_templates = {
              "application/json" = "{\"error\": \"Bad Request\"}"
            }
          }
        }
      }
    }
  }

  # Usage plans and API keys
  usage_plans = {
    basic_plan = {
      name        = "Basic Plan"
      description = "Basic usage plan with rate limiting"
      
      api_stages = [{
        stage = "v1"
        throttle = {
          path        = "/*/*"
          rate_limit  = 100
          burst_limit = 200
        }
      }]
      
      quota_settings = {
        limit  = 10000
        period = "MONTH"
      }
      
      throttle_settings = {
        rate_limit  = 100
        burst_limit = 200
      }
    }
  }

  api_keys = {
    client_key = {
      name        = "client-api-key"
      description = "API key for client application"
      enabled     = true
    }
  }

  usage_plan_keys = {
    client_association = {
      api_key_name     = "client_key"
      usage_plan_name  = "basic_plan"
    }
  }

  tags = {
    Environment = "production"
    Project     = "secure-app"
    Security    = "high"
  }
}
```

### API with Custom Domain

```hcl
module "custom_domain_api" {
  source = "../../modules/api-gateway"

  api_name        = "custom-api"
  api_description = "API with custom domain"
  stage_name      = "v1"

  # Custom domain configuration
  domain_name              = "api.example.com"
  certificate_arn          = aws_acm_certificate.api_cert.arn
  domain_security_policy   = "TLS_1_2"
  domain_endpoint_types    = ["REGIONAL"]
  base_path               = "v1"

  # WAF integration for additional security
  waf_acl_arn = aws_wafv2_web_acl.api_waf.arn

  # Performance optimization
  cache_cluster_enabled = true
  cache_cluster_size   = "1.6"

  # Throttling at stage level
  throttle_settings = {
    rate_limit  = 1000
    burst_limit = 2000
  }

  # Stage variables for environment configuration
  stage_variables = {
    environment = "production"
    version     = "1.0"
    lambda_alias = "PROD"
  }

  # ... rest of configuration
}

# Route 53 record for custom domain
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"

  alias {
    name                   = module.custom_domain_api.domain_name.regional_domain_name
    zone_id                = module.custom_domain_api.domain_name.regional_zone_id
    evaluate_target_health = false
  }
}
```

### Microservices API Gateway

```hcl
module "microservices_api" {
  source = "../../modules/api-gateway"

  api_name        = "microservices-gateway"
  api_description = "API Gateway for microservices architecture"
  stage_name      = "v1"

  # Comprehensive API structure
  api_resources = {
    api = {
      path_part = "api"
    }
    
    # User service
    users = {
      path_part = "users"
      parent_id = "api"
    }
    user_id = {
      path_part = "{user_id}"
      parent_id = "users"
    }
    
    # Order service
    orders = {
      path_part = "orders"
      parent_id = "api"
    }
    order_id = {
      path_part = "{order_id}"
      parent_id = "orders"
    }
    
    # Payment service
    payments = {
      path_part = "payments"
      parent_id = "api"
    }
    
    # Health check
    health = {
      path_part = "health"
      parent_id = "api"
    }
  }

  # Multiple authorization strategies
  api_authorizers = {
    cognito_auth = {
      name          = "cognito-authorizer"
      type          = "COGNITO_USER_POOLS"
      provider_arns = [aws_cognito_user_pool.main.arn]
    }
    
    lambda_auth = {
      name                             = "custom-authorizer"
      type                            = "TOKEN"
      authorizer_uri                  = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer.arn}/invocations"
      identity_source                 = "method.request.header.Authorization"
      authorizer_result_ttl_in_seconds = 300
    }
  }

  # Comprehensive method definitions
  api_methods = {
    # User service methods
    get_users = {
      resource_key  = "users"
      http_method   = "GET"
      authorization = "COGNITO_USER_POOLS"
      authorizer_id = "cognito_auth"
      
      integration = {
        type = "HTTP_PROXY"
        uri  = "http://${aws_lb.user_service.dns_name}/users"
        integration_http_method = "GET"
      }
      
      responses = {
        "200" = {
          status_code = "200"
          integration_response = {}
        }
      }
    }
    
    create_user = {
      resource_key      = "users"
      http_method      = "POST"
      authorization    = "COGNITO_USER_POOLS"
      authorizer_id    = "cognito_auth"
      api_key_required = true
      
      integration = {
        type = "HTTP_PROXY"
        uri  = "http://${aws_lb.user_service.dns_name}/users"
        integration_http_method = "POST"
      }
      
      responses = {
        "201" = {
          status_code = "201"
          integration_response = {}
        }
      }
    }
    
    # Order service methods
    get_orders = {
      resource_key  = "orders"
      http_method   = "GET"
      authorization = "CUSTOM"
      authorizer_id = "lambda_auth"
      
      integration = {
        type = "AWS_PROXY"
        uri  = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.orders.arn}/invocations"
        integration_http_method = "POST"
      }
      
      responses = {
        "200" = {
          status_code = "200"
          integration_response = {}
        }
      }
    }
    
    # Health check (no auth required)
    health_check = {
      resource_key  = "health"
      http_method   = "GET"
      authorization = "NONE"
      
      integration = {
        type = "MOCK"
        request_templates = {
          "application/json" = "{\"statusCode\": 200}"
        }
      }
      
      responses = {
        "200" = {
          status_code = "200"
          response_models = {
            "application/json" = "Empty"
          }
          integration_response = {
            response_templates = {
              "application/json" = "{\"status\": \"healthy\", \"timestamp\": \"$context.requestTime\"}"
            }
          }
        }
      }
    }
  }

  # Tiered usage plans
  usage_plans = {
    free_tier = {
      name        = "Free Tier"
      description = "Free usage plan with basic limits"
      
      api_stages = [{
        stage = "v1"
        throttle = {
          path        = "/*/*"
          rate_limit  = 10
          burst_limit = 20
        }
      }]
      
      quota_settings = {
        limit  = 1000
        period = "MONTH"
      }
    }
    
    premium_tier = {
      name        = "Premium Tier"
      description = "Premium usage plan with higher limits"
      
      api_stages = [{
        stage = "v1"
        throttle = {
          path        = "/*/*"
          rate_limit  = 1000
          burst_limit = 2000
        }
      }]
      
      quota_settings = {
        limit  = 100000
        period = "MONTH"
      }
    }
  }

  tags = {
    Environment   = "production"
    Architecture  = "microservices"
    Project      = "e-commerce"
  }
}
```

## Integration Examples

### Lambda Function Integration

```hcl
# Lambda function for API Gateway integration
resource "aws_lambda_function" "api_handler" {
  filename         = "api_handler.zip"
  function_name    = "api-handler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.11"

  environment {
    variables = {
      STAGE = module.api_gateway.stage_name
    }
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}
```

### ALB Integration

```hcl
# Application Load Balancer integration
resource "aws_lb" "backend" {
  name               = "api-backend"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.private_subnet_ids
  
  tags = var.tags
}

# VPC Link for private ALB integration
resource "aws_api_gateway_vpc_link" "backend" {
  name        = "backend-vpc-link"
  description = "VPC link for backend services"
  target_arns = [aws_lb.backend.arn]
}

# Use VPC link in API Gateway integration
api_methods = {
  proxy_to_backend = {
    # ... method configuration
    integration = {
      type            = "HTTP_PROXY"
      uri             = "http://backend.internal/api/{proxy}"
      connection_type = "VPC_LINK"
      connection_id   = aws_api_gateway_vpc_link.backend.id
    }
  }
}
```

## Best Practices

### 🔒 **Security Best Practices**

1. **Authentication & Authorization**
   - Use appropriate authorization types (IAM, Cognito, Lambda)
   - Implement API key rotation policies
   - Use least privilege access patterns

2. **Input Validation**
   - Define and use request validators
   - Implement schema-based validation with models
   - Sanitize user inputs

3. **Rate Limiting**
   - Implement usage plans with appropriate quotas
   - Use throttling to prevent abuse
   - Monitor and alert on unusual traffic patterns

### ⚡ **Performance Best Practices**

1. **Caching Strategy**
   - Enable response caching for static data
   - Use appropriate cache TTL values
   - Implement cache invalidation strategies

2. **Integration Optimization**
   - Use appropriate integration types
   - Optimize Lambda cold starts
   - Implement connection pooling for backend services

3. **Response Optimization**
   - Enable compression for large responses
   - Use appropriate response formats
   - Implement pagination for large datasets

### 📊 **Monitoring Best Practices**

1. **Logging Configuration**
   - Enable access logging for production environments
   - Use structured logging formats
   - Set appropriate log retention periods

2. **Metrics and Alerting**
   - Monitor key performance indicators (latency, error rate, throughput)
   - Set up CloudWatch alarms for critical metrics
   - Implement custom business metrics

3. **Tracing**
   - Enable X-Ray tracing for distributed systems
   - Implement correlation IDs across services
   - Monitor end-to-end request flows

## Outputs

| Output | Description |
|--------|-------------|
| `rest_api_id` | ID of the REST API |
| `rest_api_arn` | ARN of the REST API |
| `stage_invoke_url` | URL to invoke the API |
| `api_resources` | Map of created API resources |
| `api_methods` | Map of created API methods |
| `usage_plans` | Map of created usage plans |
| `api_keys` | Map of created API keys (sensitive) |
| `domain_name` | Custom domain configuration |

## Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `api_name` | `string` | Name of the API Gateway |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `api_description` | `string` | `""` | Description of the API Gateway |
| `stage_name` | `string` | `"v1"` | Name of the API Gateway stage |
| `enable_access_logging` | `bool` | `true` | Whether to enable access logging |
| `enable_xray_tracing` | `bool` | `false` | Whether to enable X-Ray tracing |
| `cache_cluster_enabled` | `bool` | `false` | Whether to enable caching |
| `domain_name` | `string` | `null` | Custom domain name |
| `waf_acl_arn` | `string` | `null` | WAF ACL ARN for protection |

## Requirements

- **Terraform**: >= 1.9.0
- **AWS Provider**: ~> 5.80
- **IAM Permissions**: API Gateway, CloudWatch, IAM role management

---

## 👤 Author

**Diego A. Zarate** - *API Architecture & Gateway Specialist*

---

> 🚀 **Enterprise API Gateway**: This module provides production-ready API Gateway infrastructure with comprehensive security, monitoring, and performance optimization features built-in.
