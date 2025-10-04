# AWS API Gateway Terraform Module

A comprehensive Terraform module for creating and managing AWS API Gateway resources including both REST APIs (API Gateway v1) and HTTP APIs (API Gateway v2) with advanced features, security, monitoring, and integration capabilities.

## Features

### 🚀 Core API Gateway Capabilities
- **REST API Gateway**: Full-featured API Gateway v1 with comprehensive configuration options
- **HTTP API Gateway**: Modern API Gateway v2 with improved performance and lower costs
- **Multiple Endpoint Types**: Edge-optimized, Regional, and Private endpoints
- **Custom Domains**: SSL/TLS certificates with custom domain mapping
- **Stage Management**: Multiple deployment stages with independent configurations
- **Request/Response Transformation**: Advanced data transformation capabilities

### 🔒 Security & Authentication
- **Multiple Authorization Types**: AWS IAM, Cognito User Pools, Lambda, and JWT authorizers
- **API Keys & Usage Plans**: Granular access control and usage monitoring
- **WAF Integration**: Web Application Firewall protection against common threats
- **Mutual TLS (mTLS)**: Client certificate authentication for enhanced security
- **CORS Configuration**: Cross-Origin Resource Sharing with flexible policies
- **IP Restrictions**: Network-based access control

### 📊 Monitoring & Observability
- **CloudWatch Integration**: Comprehensive logging and metrics collection
- **X-Ray Tracing**: Distributed request tracing for performance analysis
- **Access Logging**: Detailed request/response logging with custom formats
- **Method-level Metrics**: Granular monitoring at the API method level
- **Custom Dashboards**: Performance and health monitoring capabilities

### 🔗 Integration & Connectivity
- **Lambda Integration**: Seamless serverless function integration with proxy and non-proxy modes
- **VPC Links**: Private connectivity to resources in Amazon VPC
- **HTTP Integrations**: Direct integration with HTTP endpoints
- **AWS Service Integration**: Direct integration with AWS services (S3, DynamoDB, etc.)
- **Mock Integrations**: API prototyping and testing capabilities

### ⚡ Performance & Optimization
- **Caching**: Response caching to reduce latency and backend load
- **Throttling**: Request rate limiting and burst control
- **Compression**: Automatic response compression for bandwidth optimization
- **Edge Locations**: Global content delivery through CloudFront integration
- **Connection Pooling**: Efficient connection management for HTTP integrations

## Usage Examples

### Basic REST API

```hcl
module "api_gateway_basic" {
  source = "./modules/api-gateway"

  name_prefix = "my-app"
  
  rest_apis = {
    main = {
      description = "Main REST API for the application"
      
      endpoint_configuration = {
        types = ["REGIONAL"]
      }
      
      stages = {
        dev = {
          stage_description = "Development stage"
          variables = {
            environment = "development"
            log_level   = "INFO"
          }
          
          throttle_settings = {
            throttling_rate_limit  = 100
            throttling_burst_limit = 200
            metrics_enabled       = true
            logging_level        = "INFO"
          }
          
          xray_tracing_enabled = true
        }
        
        prod = {
          stage_description = "Production stage"
          variables = {
            environment = "production"
            log_level   = "WARN"
          }
          
          cache_cluster_enabled = true
          cache_cluster_size   = "1.6"
          
          throttle_settings = {
            throttling_rate_limit  = 1000
            throttling_burst_limit = 2000
            metrics_enabled       = true
            logging_level        = "ERROR"
          }
        }
      }
      
      tags = {
        API = "Main"
        Purpose = "Application Backend"
      }
    }
  }
  
  common_tags = {
    Environment = "multi-stage"
    Project = "api-demo"
  }
}
```

### Advanced HTTP API with Authentication

```hcl
module "api_gateway_http" {
  source = "./modules/api-gateway"

  name_prefix = "modern-app"
  
  http_apis = {
    api_v2 = {
      description = "Modern HTTP API with JWT authentication"
      version     = "2.0"
      
      cors_configuration = {
        allow_credentials = true
        allow_headers     = ["content-type", "x-amz-date", "authorization"]
        allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        allow_origins     = ["https://myapp.com", "https://dev.myapp.com"]
        expose_headers    = ["x-request-id"]
        max_age          = 86400
      }
      
      stages = {
        v2 = {
          description = "Version 2 API stage"
          auto_deploy = true
          
          default_route_settings = {
            data_trace_enabled       = true
            detailed_metrics_enabled = true
            logging_level           = "INFO"
            throttling_rate_limit   = 2000
            throttling_burst_limit  = 4000
          }
          
          access_log_settings = {
            destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/http-api"
            format = jsonencode({
              requestId      = "$context.requestId"
              ip            = "$context.identity.sourceIp"
              requestTime   = "$context.requestTime"
              httpMethod    = "$context.httpMethod"
              routeKey      = "$context.routeKey"
              status        = "$context.status"
              protocol      = "$context.protocol"
              responseLength = "$context.responseLength"
              error         = "$context.error.message"
              integrationError = "$context.integration.error"
            })
          }
        }
      }
      
      # JWT Authorizer with Cognito
      jwt_authorizers = {
        cognito_auth = {
          name     = "CognitoAuthorizer"
          audience = ["client-id-1", "client-id-2"]
          issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXXXX"
        }
      }
      
      # Lambda Authorizer
      lambda_authorizers = {
        custom_auth = {
          name                            = "CustomAuthorizer"
          authorizer_type                 = "REQUEST"
          authorizer_uri                  = "arn:aws:lambda:us-east-1:123456789012:function:custom-authorizer"
          identity_sources               = ["$request.header.Authorization"]
          authorizer_payload_format_version = "2.0"
          authorizer_result_ttl_in_seconds = 300
          enable_simple_responses        = true
        }
      }
      
      # Integrations
      integrations = {
        lambda_proxy = {
          integration_type    = "AWS_PROXY"
          integration_method  = "POST"
          integration_uri     = "arn:aws:lambda:us-east-1:123456789012:function:api-handler"
          payload_format_version = "2.0"
          timeout_milliseconds = 29000
        }
        
        http_backend = {
          integration_type   = "HTTP_PROXY"
          integration_method = "ANY"
          integration_uri    = "https://backend.internal.com/{proxy}"
          timeout_milliseconds = 5000
        }
        
        vpc_service = {
          integration_type = "HTTP_PROXY"
          integration_uri  = "http://internal-service.vpc"
          connection_type  = "VPC_LINK"
          connection_id   = "vpc-link-id"
        }
      }
      
      # Routes
      routes = {
        get_users = {
          route_key          = "GET /users"
          target            = "integrations/lambda_proxy"
          authorization_type = "JWT"
          authorizer_id     = "cognito_auth"
        }
        
        post_users = {
          route_key          = "POST /users"
          target            = "integrations/lambda_proxy"
          authorization_type = "CUSTOM"
          authorizer_id     = "custom_auth"
        }
        
        proxy_backend = {
          route_key          = "ANY /api/{proxy+}"
          target            = "integrations/http_backend"
          authorization_type = "AWS_IAM"
        }
      }
      
      tags = {
        API = "Modern"
        Version = "2.0"
        Authentication = "JWT"
      }
    }
  }
  
  # Global configuration
  enable_cloudwatch_logs = true
  log_retention_days     = 30
  
  common_tags = {
    Environment = "production"
    Project = "modern-api"
  }
}
```

### REST API with Comprehensive Security

```hcl
module "api_gateway_secure" {
  source = "./modules/api-gateway"

  name_prefix = "secure-api"
  
  rest_apis = {
    enterprise = {
      description = "Enterprise API with comprehensive security"
      
      endpoint_configuration = {
        types = ["PRIVATE"]
        vpc_endpoint_ids = ["vpce-12345678"]
      }
      
      # Resource policy for private API
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = "*"
            Action = "execute-api:Invoke"
            Resource = "*"
            Condition = {
              StringEquals = {
                "aws:SourceVpce" = "vpce-12345678"
              }
            }
          }
        ]
      })
      
      stages = {
        secure = {
          stage_description = "Secure production stage"
          
          cache_cluster_enabled = true
          cache_cluster_size   = "6.1"
          
          throttle_settings = {
            throttling_rate_limit  = 500
            throttling_burst_limit = 1000
            metrics_enabled       = true
            logging_level        = "ERROR"
            data_trace_enabled   = false  # Security: disable detailed logging
            caching_enabled      = true
            cache_ttl_in_seconds = 300
            require_authorization_for_cache_control = true
          }
          
          access_log_settings = {
            destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/secure-api"
            format = "$requestId $ip $requestTime $httpMethod $resourcePath $status $responseLength $responseTime"
          }
        }
      }
      
      # API Keys and Usage Plans
      api_keys = {
        partner_key = {
          description = "Partner API access key"
          enabled     = true
        }
        
        internal_key = {
          description = "Internal service API key"
          enabled     = true
        }
      }
      
      usage_plans = {
        partner_plan = {
          description = "Partner usage plan with rate limiting"
          
          api_stages = [{
            stage = "secure"
            throttle = {
              rate_limit  = 100
              burst_limit = 200
              path       = "/partner/*"
            }
          }]
          
          quota_settings = {
            limit  = 10000
            period = "MONTH"
            offset = 0
          }
          
          throttle_settings = {
            rate_limit  = 100
            burst_limit = 200
          }
        }
      }
      
      # Lambda Authorizer
      authorizers = {
        token_auth = {
          name                             = "TokenAuthorizer"
          type                            = "TOKEN"
          authorizer_uri                  = "arn:aws:lambda:us-east-1:123456789012:function:token-authorizer"
          authorizer_result_ttl_in_seconds = 300
          identity_source                 = "method.request.header.Authorization"
          identity_validation_expression   = "^Bearer [-0-9A-Za-z\\.]+$"
        }
        
        cognito_auth = {
          name          = "CognitoAuthorizer"
          type         = "COGNITO_USER_POOLS"
          provider_arns = ["arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_XXXXXXXXX"]
        }
      }
      
      # WAF Integration
      waf_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/secure-api-waf/12345678-1234-1234-1234-123456789012"
      
      tags = {
        Security = "High"
        Access = "Private"
        Compliance = "Required"
      }
    }
  }
}
```

### Custom Domains and SSL

```hcl
module "api_gateway_domains" {
  source = "./modules/api-gateway"

  name_prefix = "branded-api"
  
  rest_apis = {
    public = {
      description = "Public API with custom domain"
      
      endpoint_configuration = {
        types = ["EDGE"]
      }
      
      stages = {
        v1 = {
          stage_description = "Version 1 API"
          
          throttle_settings = {
            throttling_rate_limit  = 1000
            throttling_burst_limit = 2000
          }
        }
      }
    }
  }
  
  http_apis = {
    modern = {
      description = "Modern API with regional custom domain"
      
      stages = {
        v2 = {
          description = "Version 2 API"
          auto_deploy = true
        }
      }
    }
  }
  
  # REST API Custom Domain (Edge-optimized)
  rest_api_custom_domains = {
    api_domain = {
      api_name        = "public"
      domain_name     = "api.mycompany.com"
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
      
      endpoint_configuration = {
        types = ["EDGE"]
      }
      
      base_path_mappings = {
        stage_name = "v1"
        base_path  = "v1"
      }
      
      # Mutual TLS Authentication
      mutual_tls_authentication = {
        truststore_uri     = "s3://my-truststore-bucket/truststore.pem"
        truststore_version = "v1.0"
      }
    }
  }
  
  # HTTP API Custom Domain (Regional)
  http_api_custom_domains = {
    modern_domain = {
      api_name    = "modern"
      domain_name = "api-v2.mycompany.com"
      
      domain_name_configuration = {
        certificate_arn                        = "arn:aws:acm:us-east-1:123456789012:certificate/87654321-4321-4321-4321-210987654321"
        endpoint_type                         = "REGIONAL"
        security_policy                       = "TLS_1_2"
      }
      
      api_mapping = {
        stage = "v2"
      }
    }
  }
}
```

### VPC Links and Private Integrations

```hcl
module "api_gateway_vpc" {
  source = "./modules/api-gateway"

  name_prefix = "internal-api"
  
  # VPC Links for private integrations
  vpc_links = {
    internal_services = {
      description = "VPC Link to internal microservices"
      target_arns = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/internal-nlb/1234567890123456"]
    }
  }
  
  http_apis = {
    internal = {
      description = "Internal API with VPC connectivity"
      
      stages = {
        internal = {
          description = "Internal services stage"
          auto_deploy = true
        }
      }
      
      integrations = {
        user_service = {
          integration_type = "HTTP_PROXY"
          integration_uri  = "http://user-service.internal"
          connection_type  = "VPC_LINK"
          connection_id   = "internal_services"  # Reference to VPC Link
          timeout_milliseconds = 10000
        }
        
        order_service = {
          integration_type = "HTTP_PROXY"
          integration_uri  = "http://order-service.internal/{proxy}"
          connection_type  = "VPC_LINK"
          connection_id   = "internal_services"
          
          # TLS configuration for backend
          tls_config = {
            server_name_to_verify = "order-service.internal"
          }
        }
      }
      
      routes = {
        users_api = {
          route_key          = "ANY /users/{proxy+}"
          target            = "integrations/user_service"
          authorization_type = "AWS_IAM"
        }
        
        orders_api = {
          route_key          = "ANY /orders/{proxy+}"
          target            = "integrations/order_service"
          authorization_type = "AWS_IAM"
        }
      }
    }
  }
}
```

### Multi-API Gateway Setup

```hcl
module "api_gateway_multi" {
  source = "./modules/api-gateway"

  name_prefix = "multi-api"
  
  # Multiple REST APIs
  rest_apis = {
    public_api = {
      description = "Public-facing REST API"
      
      endpoint_configuration = {
        types = ["EDGE"]
      }
      
      stages = {
        prod = {
          cache_cluster_enabled = true
          cache_cluster_size   = "1.6"
          
          throttle_settings = {
            throttling_rate_limit  = 2000
            throttling_burst_limit = 4000
          }
        }
      }
    }
    
    admin_api = {
      description = "Administrative REST API"
      
      endpoint_configuration = {
        types = ["REGIONAL"]
      }
      
      stages = {
        admin = {
          throttle_settings = {
            throttling_rate_limit  = 100
            throttling_burst_limit = 200
            logging_level        = "INFO"
            data_trace_enabled   = true
          }
        }
      }
      
      # IP restrictions for admin API
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = "*"
            Action = "execute-api:Invoke"
            Resource = "*"
            Condition = {
              IpAddress = {
                "aws:SourceIp" = ["10.0.0.0/8", "172.16.0.0/12"]
              }
            }
          }
        ]
      })
    }
  }
  
  # Multiple HTTP APIs
  http_apis = {
    mobile_api = {
      description = "Mobile application API"
      
      cors_configuration = {
        allow_credentials = false
        allow_headers     = ["content-type"]
        allow_methods     = ["GET", "POST"]
        allow_origins     = ["*"]
      }
      
      stages = {
        mobile = {
          auto_deploy = true
          
          default_route_settings = {
            throttling_rate_limit = 1000
          }
        }
      }
    }
    
    iot_api = {
      description = "IoT devices API"
      
      stages = {
        devices = {
          auto_deploy = true
          
          default_route_settings = {
            throttling_rate_limit   = 5000
            throttling_burst_limit  = 10000
            detailed_metrics_enabled = true
          }
        }
      }
    }
  }
  
  common_tags = {
    Environment = "production"
    Project = "multi-service"
  }
}
```

## Module Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name_prefix` | Prefix for all resource names | `string` | n/a | yes |
| `rest_apis` | Configuration for REST API Gateway instances | `map(object)` | `{}` | no |
| `http_apis` | Configuration for HTTP API Gateway instances | `map(object)` | `{}` | no |
| `rest_api_custom_domains` | Custom domain configurations for REST APIs | `map(object)` | `{}` | no |
| `http_api_custom_domains` | Custom domain configurations for HTTP APIs | `map(object)` | `{}` | no |
| `vpc_links` | VPC Links for private integrations | `map(object)` | `{}` | no |
| `common_tags` | Common tags for all resources | `map(string)` | `{}` | no |
| `enable_cloudwatch_logs` | Enable CloudWatch logging | `bool` | `true` | no |
| `log_retention_days` | CloudWatch log retention period | `number` | `14` | no |
| `log_kms_key_id` | KMS key for log encryption | `string` | `null` | no |

### REST API Configuration

Each REST API supports:

#### Basic Configuration
- `description` - API description
- `endpoint_configuration` - Edge, Regional, or Private endpoint types
- `binary_media_types` - Binary media type support
- `minimum_compression_size` - Response compression threshold
- `api_key_source` - API key source (HEADER or AUTHORIZER)
- `policy` - Resource policy for access control
- `openapi_spec` - OpenAPI/Swagger specification

#### Stage Configuration
- `stages` - Multiple deployment stages with independent settings
- `cache_cluster_enabled` - Response caching configuration
- `throttle_settings` - Rate limiting and request throttling
- `access_log_settings` - CloudWatch access logging
- `canary_settings` - Blue/green deployment configuration
- `xray_tracing_enabled` - X-Ray distributed tracing

#### Security & Access Control
- `api_keys` - API key management
- `usage_plans` - Usage plans with quotas and throttling
- `authorizers` - Lambda, Cognito, and custom authorizers
- `waf_acl_arn` - WAF Web ACL association

### HTTP API Configuration

Each HTTP API supports:

#### Basic Configuration
- `description` - API description
- `version` - API version
- `cors_configuration` - Cross-origin resource sharing settings
- `route_selection_expression` - Route selection logic

#### Stage Configuration
- `stages` - Deployment stages with auto-deploy options
- `default_route_settings` - Default throttling and logging settings
- `route_settings` - Route-specific configuration overrides
- `access_log_settings` - Structured access logging

#### Authentication & Authorization
- `jwt_authorizers` - JWT/OIDC token validation
- `lambda_authorizers` - Custom Lambda authorization logic

#### Integrations & Routing
- `integrations` - Lambda, HTTP, VPC Link, and AWS service integrations
- `routes` - HTTP route definitions with authorization
- `waf_acl_arn` - WAF protection

## Module Outputs

| Name | Description |
|------|-------------|
| `rest_apis` | Complete REST API details |
| `http_apis` | Complete HTTP API details |
| `rest_api_stages` | REST API stage information |
| `http_api_stages` | HTTP API stage information |
| `rest_api_stage_invoke_urls` | REST API invoke URLs |
| `http_api_stage_invoke_urls` | HTTP API invoke URLs |
| `api_keys` | API key information |
| `usage_plans` | Usage plan details |
| `rest_api_custom_domains` | Custom domain configurations |
| `http_api_custom_domains` | HTTP API custom domains |
| `vpc_links` | VPC Link information |
| `rest_api_authorizers` | REST API authorizer details |
| `jwt_authorizers` | JWT authorizer information |
| `lambda_authorizers` | Lambda authorizer details |
| `security_summary` | Security configuration overview |
| `performance_summary` | Performance metrics summary |
| `cost_optimization_summary` | Cost optimization insights |

## Security Best Practices

### Authentication and Authorization
- **Multiple Auth Methods**: Support for AWS IAM, Cognito, JWT, and Lambda authorizers
- **API Keys**: Granular access control with usage plans and quotas
- **Resource Policies**: VPC and IP-based access restrictions
- **WAF Integration**: Protection against common web vulnerabilities

### Network Security
- **Private Endpoints**: VPC-only access for sensitive APIs
- **VPC Links**: Secure connectivity to private resources
- **Custom Domains**: SSL/TLS with custom certificates
- **Mutual TLS**: Client certificate authentication

### Data Protection
- **HTTPS Only**: Enforced SSL/TLS encryption in transit
- **Request Validation**: Input validation and sanitization
- **Response Filtering**: Sensitive data protection in responses
- **CloudWatch Logs Encryption**: Encrypted log storage

### Compliance and Auditing
- **CloudTrail Integration**: API call auditing and compliance
- **Access Logging**: Comprehensive request/response logging
- **X-Ray Tracing**: Request flow monitoring and analysis
- **Metrics and Alarms**: Proactive security monitoring

## Performance Optimization

### Caching Strategies
```hcl
# Response caching for REST APIs
cache_cluster_enabled = true
cache_cluster_size   = "1.6"  # Available sizes: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237 GB

throttle_settings = {
  caching_enabled      = true
  cache_ttl_in_seconds = 300
  cache_key_parameters = ["method.request.querystring.id"]
}
```

### Throttling and Rate Limiting
```hcl
# API-level throttling
throttle_settings = {
  throttling_rate_limit  = 1000  # Requests per second
  throttling_burst_limit = 2000  # Burst capacity
}

# Usage plan throttling
usage_plans = {
  standard = {
    throttle_settings = {
      rate_limit  = 100
      burst_limit = 200
    }
    quota_settings = {
      limit  = 10000
      period = "MONTH"
    }
  }
}
```

### Endpoint Optimization
```hcl
# Edge-optimized for global distribution
endpoint_configuration = {
  types = ["EDGE"]
}

# Regional for specific geographic regions
endpoint_configuration = {
  types = ["REGIONAL"]
}

# Private for VPC-only access
endpoint_configuration = {
  types = ["PRIVATE"]
  vpc_endpoint_ids = ["vpce-12345678"]
}
```

## Cost Optimization Strategies

### 1. HTTP APIs vs REST APIs
- **HTTP APIs**: Up to 70% cost reduction compared to REST APIs
- **Use Cases**: Modern applications, microservices, serverless architectures
- **Limitations**: Fewer features than REST APIs, no caching

### 2. Caching Implementation
- **Response Caching**: Reduces backend calls and improves latency
- **Cache Key Strategy**: Optimize cache hit rates with proper key design
- **TTL Configuration**: Balance freshness vs. performance

### 3. Request/Response Size Optimization
- **Compression**: Enable minimum compression size for bandwidth savings
- **Response Filtering**: Return only necessary data fields
- **Pagination**: Implement efficient data pagination strategies

### 4. Throttling and Quotas
- **Usage Plans**: Prevent cost overruns with rate limiting
- **Burst Capacity**: Handle traffic spikes efficiently
- **Monitoring**: Track usage patterns for optimization

## Monitoring and Observability

### CloudWatch Integration
```hcl
# Comprehensive logging configuration
access_log_settings = {
  destination_arn = aws_cloudwatch_log_group.api_logs.arn
  format = jsonencode({
    requestId      = "$context.requestId"
    ip            = "$context.identity.sourceIp"
    requestTime   = "$context.requestTime"
    httpMethod    = "$context.httpMethod"
    resourcePath  = "$context.resourcePath"
    status        = "$context.status"
    protocol      = "$context.protocol"
    responseLength = "$context.responseLength"
    responseTime  = "$context.responseTime"
    error         = "$context.error.message"
  })
}
```

### X-Ray Tracing
```hcl
# Enable distributed tracing
xray_tracing_enabled = true

# Trace sampling configuration
# X-Ray automatically samples requests for performance analysis
```

### Custom Metrics and Alarms
```hcl
# CloudWatch alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "api_4xx_errors" {
  alarm_name          = "api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "This metric monitors api gateway 4xx errors"
  
  dimensions = {
    ApiName = module.api_gateway.rest_apis["main"].name
  }
}
```

## Troubleshooting Guide

### Common Issues and Solutions

#### CORS Configuration
```hcl
# Proper CORS setup for browser applications
cors_configuration = {
  allow_credentials = true
  allow_headers     = [
    "content-type",
    "x-amz-date",
    "authorization",
    "x-api-key",
    "x-amz-security-token"
  ]
  allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  allow_origins     = ["https://myapp.com"]
  expose_headers    = ["x-request-id"]
  max_age          = 86400
}
```

#### Lambda Integration Issues
```hcl
# Proper Lambda proxy integration
integrations = {
  lambda_function = {
    integration_type       = "AWS_PROXY"
    integration_method     = "POST"  # Always POST for Lambda proxy
    integration_uri        = "arn:aws:lambda:region:account:function:name"
    payload_format_version = "2.0"  # Use 2.0 for HTTP APIs
  }
}

# Ensure Lambda permission is granted
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "my-function"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_apis["main"].execution_arn}/*/*"
}
```

#### VPC Link Connectivity
```hcl
# Ensure Network Load Balancer is properly configured
vpc_links = {
  internal = {
    description = "VPC Link to internal services"
    target_arns = [
      "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/internal-nlb/1234567890123456"
    ]
  }
}

# NLB must be in the same region as API Gateway
# Security groups must allow traffic from API Gateway
```

#### Authentication Problems
```hcl
# JWT Authorizer troubleshooting
jwt_authorizers = {
  cognito = {
    name     = "CognitoAuth"
    audience = ["your-client-id"]  # Must match token audience
    issuer   = "https://cognito-idp.region.amazonaws.com/user-pool-id"
    
    # Ensure token is passed in correct header
    identity_sources = ["$request.header.Authorization"]
  }
}
```

### Performance Issues

#### High Latency
- **Enable Caching**: Implement response caching for frequently accessed data
- **Optimize Backend**: Review integration timeout and backend performance
- **Use Regional Endpoints**: Reduce latency for geographically concentrated users
- **Connection Pooling**: Optimize HTTP integration connection management

#### Throttling Errors
- **Increase Limits**: Adjust throttling rates based on usage patterns
- **Implement Retry Logic**: Add exponential backoff in client applications
- **Usage Plans**: Distribute API keys across multiple usage plans
- **Load Distribution**: Use multiple APIs or stages for load balancing

#### Memory and Timeout Issues
```hcl
# Adjust integration timeouts
integrations = {
  slow_backend = {
    integration_type     = "HTTP_PROXY"
    integration_uri      = "https://slow-backend.com"
    timeout_milliseconds = 29000  # Maximum timeout for HTTP APIs
  }
}
```

## Integration Examples

### Lambda Function Integration
```hcl
# HTTP API with Lambda integration
module "api_gateway" {
  source = "./modules/api-gateway"
  
  http_apis = {
    serverless = {
      integrations = {
        users_function = {
          integration_type       = "AWS_PROXY"
          integration_method     = "POST"
          integration_uri        = module.lambda.function_invoke_arns["users_api"]
          payload_format_version = "2.0"
        }
      }
      
      routes = {
        users_crud = {
          route_key = "ANY /users/{proxy+}"
          target   = "integrations/users_function"
        }
      }
    }
  }
}
```

### Application Load Balancer Integration
```hcl
# VPC Link to ALB
resource "aws_apigatewayv2_vpc_link" "alb_link" {
  name               = "alb-vpc-link"
  protocol_type      = "HTTP"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.vpc_link.id]
}

module "api_gateway" {
  source = "./modules/api-gateway"
  
  http_apis = {
    backend = {
      integrations = {
        alb_integration = {
          integration_type = "HTTP_PROXY"
          integration_uri  = "http://internal-alb.example.com/{proxy}"
          connection_type  = "VPC_LINK"
          connection_id   = aws_apigatewayv2_vpc_link.alb_link.id
        }
      }
    }
  }
}
```

### CloudFront Distribution
```hcl
# CloudFront with API Gateway origin
resource "aws_cloudfront_distribution" "api_cdn" {
  origin {
    domain_name = replace(module.api_gateway.rest_api_stages["main-prod"].invoke_url, "/^https?://([^/]*).*/", "$1")
    origin_id   = "api-gateway"
    origin_path = "/prod"
    
    custom_origin_config {
      http_port              = 443
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  default_cache_behavior {
    target_origin_id       = "api-gateway"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
    }
  }
  
  enabled = true
}
```

## Advanced Patterns

### Multi-Region Deployment
```hcl
# Primary region API Gateway
module "api_gateway_primary" {
  source = "./modules/api-gateway"
  
  providers = {
    aws = aws.primary
  }
  
  # Primary region configuration
}

# Disaster recovery region
module "api_gateway_dr" {
  source = "./modules/api-gateway"
  
  providers = {
    aws = aws.disaster_recovery
  }
  
  # Same configuration as primary
}

# Route 53 health checks and failover
resource "aws_route53_health_check" "primary_api" {
  fqdn                            = "api.example.com"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
}
```

### Blue/Green Deployments
```hcl
# Canary deployment configuration
stages = {
  production = {
    canary_settings = {
      percent_traffic         = 10  # 10% to new version
      deployment_id          = aws_api_gateway_deployment.new_version.id
      use_stage_cache        = false
      stage_variable_overrides = {
        version = "new"
      }
    }
  }
}
```

### API Versioning Strategy
```hcl
# Version-based routing
http_apis = {
  versioned_api = {
    routes = {
      v1_users = {
        route_key = "ANY /v1/users/{proxy+}"
        target   = "integrations/users_v1"
      }
      
      v2_users = {
        route_key = "ANY /v2/users/{proxy+}"
        target   = "integrations/users_v2"
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

## License

This module is released under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting guide above
2. Review AWS API Gateway documentation
3. Create an issue in the repository
4. Contact the development team

---

*This module follows AWS Well-Architected Framework principles and is designed for production use with enterprise-grade security, performance, and monitoring capabilities.*