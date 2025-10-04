# AWS Lambda Terraform Module

A comprehensive Terraform module for creating and managing AWS Lambda functions with advanced features, security best practices, and full integration capabilities.

## Features

### 🚀 Core Lambda Capabilities
- **Multiple Package Types**: Support for both Zip and Container image deployments
- **Runtime Flexibility**: All AWS Lambda runtimes including Python, Node.js, Java, Go, .NET, Ruby
- **Architecture Support**: x86_64 and ARM64 (Graviton2) architectures for cost optimization
- **Layer Management**: Create and manage Lambda layers for code reuse
- **Version Control**: Function versioning and alias management
- **Concurrency Control**: Reserved and provisioned concurrency configuration

### 🔒 Security & Compliance
- **IAM Integration**: Automatic IAM role creation with least privilege principles
- **VPC Integration**: Secure networking with custom VPC, subnets, and security groups
- **Encryption**: KMS encryption for environment variables and CloudWatch logs
- **Code Signing**: Support for AWS Signer code signing configurations
- **Dead Letter Queues**: Error handling with DLQ integration
- **X-Ray Tracing**: Distributed tracing for performance monitoring

### 📊 Monitoring & Observability
- **CloudWatch Integration**: Automatic log group creation with configurable retention
- **Structured Logging**: JSON and text log format support
- **Performance Metrics**: Memory, timeout, and execution monitoring
- **Custom Log Levels**: Application and system log level configuration
- **Health Monitoring**: Function health and performance tracking

### 🔗 Integration & Event Processing
- **Event Source Mappings**: Kinesis, DynamoDB, SQS, MSK integration
- **Function URLs**: HTTP(S) endpoints with CORS support
- **API Gateway Ready**: Optimized for API Gateway integration
- **EventBridge Integration**: Event-driven architecture support
- **File System Support**: EFS integration for shared storage

### ⚡ Performance & Optimization
- **Memory Optimization**: Configurable memory from 128MB to 10GB
- **Ephemeral Storage**: Up to 10GB of temporary storage
- **Snap Start**: Java performance optimization
- **ARM64 Support**: Cost-effective Graviton2 processors
- **Provisioned Concurrency**: Reduced cold start latency

## Usage Examples

### Basic Function

```hcl
module "lambda_basic" {
  source = "./modules/lambda"

  name_prefix = "my-app"
  
  lambda_functions = {
    hello_world = {
      runtime = "python3.11"
      handler = "lambda_function.lambda_handler"
      filename = "hello_world.zip"
      description = "Basic Hello World function"
      timeout = 30
      memory_size = 128
      
      environment_variables = {
        LOG_LEVEL = "INFO"
        STAGE = "dev"
      }
      
      tags = {
        Function = "HelloWorld"
        Purpose = "Demo"
      }
    }
  }
  
  common_tags = {
    Environment = "development"
    Project = "lambda-demo"
  }
}
```

### Advanced Function with VPC and Monitoring

```hcl
module "lambda_advanced" {
  source = "./modules/lambda"

  name_prefix = "enterprise-app"
  
  lambda_functions = {
    data_processor = {
      runtime = "python3.11"
      handler = "app.handler"
      filename = "data_processor.zip"
      description = "Data processing function with VPC and monitoring"
      timeout = 300
      memory_size = 1024
      reserved_concurrent_executions = 50
      
      # VPC Configuration
      vpc_config = {
        subnet_ids = [
          "subnet-12345678",
          "subnet-87654321"
        ]
        security_group_ids = [
          "sg-12345678"
        ]
      }
      
      # Environment Variables with Encryption
      environment_variables = {
        DATABASE_URL = "postgresql://..."
        API_KEY = "encrypted_key"
        REDIS_URL = "redis://..."
      }
      kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      
      # Dead Letter Queue
      dead_letter_config = {
        target_arn = "arn:aws:sqs:us-east-1:123456789012:dlq"
      }
      
      # X-Ray Tracing
      tracing_mode = "Active"
      
      # Enhanced Logging
      logging_config = {
        log_format = "JSON"
        application_log_level = "INFO"
        system_log_level = "WARN"
      }
      
      # Custom IAM Policy
      custom_iam_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "rds-db:connect",
              "secretsmanager:GetSecretValue"
            ]
            Resource = "*"
          }
        ]
      })
      
      tags = {
        Function = "DataProcessor"
        Tier = "Backend"
        CriticalityLevel = "High"
      }
    }
  }
  
  # Global Configuration
  log_retention_days = 30
  log_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/log-key-id"
  
  common_tags = {
    Environment = "production"
    Project = "enterprise-app"
    ManagedBy = "terraform"
  }
}
```

### Container-Based Function

```hcl
module "lambda_container" {
  source = "./modules/lambda"

  name_prefix = "ml-pipeline"
  
  lambda_functions = {
    ml_inference = {
      package_type = "Image"
      image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/ml-inference:latest"
      description = "ML inference using container image"
      timeout = 900
      memory_size = 3008
      architectures = ["x86_64"]
      
      # Image Configuration
      image_config = {
        entry_point = ["/lambda-entrypoint.sh"]
        command = ["app.handler"]
        working_directory = "/var/task"
      }
      
      # Ephemeral Storage for Model Files
      ephemeral_storage_size = 2048
      
      # Environment Variables
      environment_variables = {
        MODEL_PATH = "/tmp/models"
        BATCH_SIZE = "32"
        GPU_ENABLED = "false"
      }
      
      # Provisioned Concurrency for Low Latency
      provisioned_concurrency_config = {
        provisioned_concurrent_executions = 5
        qualifier = "$LATEST"
      }
      
      tags = {
        Function = "MLInference"
        ModelType = "Classification"
        GPU = "false"
      }
    }
  }
}
```

### Event-Driven Function with Multiple Integrations

```hcl
module "lambda_event_driven" {
  source = "./modules/lambda"

  name_prefix = "event-processor"
  
  lambda_functions = {
    stream_processor = {
      runtime = "python3.11"
      handler = "stream_handler.process"
      filename = "stream_processor.zip"
      timeout = 300
      memory_size = 512
      
      # Event Source Mappings
      event_source_mappings = {
        kinesis_stream = {
          event_source_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
          starting_position = "LATEST"
          batch_size = 100
          maximum_batching_window_in_seconds = 5
          parallelization_factor = 2
          
          # Error Handling
          maximum_record_age_in_seconds = 3600
          bisect_batch_on_function_error = true
          maximum_retry_attempts = 3
          
          # Destination Configuration
          destination_config = {
            on_failure = {
              destination_arn = "arn:aws:sqs:us-east-1:123456789012:failed-events"
            }
          }
          
          # Filtering
          filter_criteria = {
            filters = [
              {
                pattern = jsonencode({
                  eventType = ["ORDER_CREATED", "ORDER_UPDATED"]
                })
              }
            ]
          }
        }
        
        sqs_queue = {
          event_source_arn = "arn:aws:sqs:us-east-1:123456789012:processing-queue"
          batch_size = 10
          maximum_batching_window_in_seconds = 2
        }
      }
      
      # Function URL for HTTP Access
      function_url_config = {
        authorization_type = "AWS_IAM"
        cors = {
          allow_credentials = true
          allow_headers = ["date", "keep-alive"]
          allow_methods = ["POST", "GET"]
          allow_origins = ["https://myapp.com"]
          expose_headers = ["date", "keep-alive"]
          max_age = 86400
        }
      }
      
      # Permissions for External Services
      permissions = {
        api_gateway = {
          statement_id = "AllowExecutionFromAPIGateway"
          action = "lambda:InvokeFunction"
          principal = "apigateway.amazonaws.com"
          source_arn = "arn:aws:execute-api:us-east-1:123456789012:api-id/*/*/*"
        }
        
        eventbridge = {
          statement_id = "AllowExecutionFromEventBridge"
          action = "lambda:InvokeFunction"
          principal = "events.amazonaws.com"
          source_arn = "arn:aws:events:us-east-1:123456789012:rule/my-rule"
        }
      }
      
      tags = {
        Function = "StreamProcessor"
        Purpose = "EventProcessing"
        IntegrationType = "Multi"
      }
    }
  }
}
```

### Lambda Layers

```hcl
module "lambda_with_layers" {
  source = "./modules/lambda"

  name_prefix = "layered-app"
  
  # Define Layers
  lambda_layers = {
    common_utils = {
      filename = "common_utils_layer.zip"
      description = "Common utility functions and libraries"
      compatible_runtimes = ["python3.9", "python3.10", "python3.11"]
      compatible_architectures = ["x86_64", "arm64"]
      license_info = "MIT"
    }
    
    ml_libraries = {
      filename = "ml_libraries_layer.zip"
      description = "Machine learning libraries (numpy, pandas, sklearn)"
      compatible_runtimes = ["python3.11"]
      compatible_architectures = ["x86_64"]
    }
  }
  
  lambda_functions = {
    analytics_function = {
      runtime = "python3.11"
      handler = "analytics.handler"
      filename = "analytics.zip"
      
      # Reference layers (will be created by this module)
      layers = [
        # Layer ARNs will be available after creation
        # These would typically be referenced as:
        # module.lambda_with_layers.layer_arns["common_utils"],
        # module.lambda_with_layers.layer_arns["ml_libraries"]
      ]
      
      tags = {
        Function = "Analytics"
        UsesLayers = "true"
      }
    }
  }
}
```

### ARM64 (Graviton2) Optimization

```hcl
module "lambda_arm64" {
  source = "./modules/lambda"

  name_prefix = "cost-optimized"
  
  lambda_functions = {
    graviton_processor = {
      runtime = "python3.11"
      handler = "processor.handle"
      filename = "processor.zip"
      architectures = ["arm64"]  # Use ARM64 for cost savings
      memory_size = 512
      timeout = 120
      
      environment_variables = {
        ARCHITECTURE = "arm64"
        COST_OPTIMIZED = "true"
      }
      
      tags = {
        Function = "GravitonProcessor"
        Architecture = "ARM64"
        CostOptimized = "true"
      }
    }
  }
}
```

## Module Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name_prefix` | Prefix for all resource names | `string` | n/a | yes |
| `lambda_functions` | Map of Lambda functions to create | `map(object)` | `{}` | no |
| `lambda_layers` | Map of Lambda layers to create | `map(object)` | `{}` | no |
| `common_tags` | Common tags for all resources | `map(string)` | `{}` | no |
| `global_environment_variables` | Global environment variables for all functions | `map(string)` | `{}` | no |
| `default_kms_key_arn` | Default KMS key for environment encryption | `string` | `null` | no |
| `log_retention_days` | CloudWatch log retention period | `number` | `14` | no |
| `log_kms_key_id` | KMS key for log encryption | `string` | `null` | no |

### Lambda Function Configuration

Each function in the `lambda_functions` map supports:

#### Basic Configuration
- `runtime` - Lambda runtime (e.g., "python3.11", "nodejs18.x")
- `handler` - Function handler (e.g., "index.handler")
- `filename` - Path to deployment package
- `s3_bucket` - S3 bucket containing deployment package
- `s3_key` - S3 object key for deployment package
- `description` - Function description
- `timeout` - Function timeout (1-900 seconds)
- `memory_size` - Memory allocation (128-10240 MB, in 64MB increments)
- `package_type` - "Zip" or "Image"

#### Advanced Configuration
- `vpc_config` - VPC configuration with subnets and security groups
- `environment_variables` - Environment variables map
- `kms_key_arn` - KMS key for environment variable encryption
- `dead_letter_config` - Dead letter queue configuration
- `tracing_mode` - X-Ray tracing ("PassThrough" or "Active")
- `reserved_concurrent_executions` - Reserved concurrency limit
- `provisioned_concurrency_config` - Provisioned concurrency settings
- `architectures` - Processor architectures (["x86_64"] or ["arm64"])

#### Container Configuration (for package_type = "Image")
- `image_uri` - Container image URI
- `image_config` - Entry point, command, and working directory

#### Event Integration
- `event_source_mappings` - Event source configurations
- `function_url_config` - Function URL settings with CORS
- `permissions` - Lambda permissions for external services

#### Layers and Dependencies
- `layers` - List of layer ARNs
- `file_system_configs` - EFS file system configurations
- `code_signing_config_arn` - Code signing configuration

## Module Outputs

| Name | Description |
|------|-------------|
| `lambda_functions` | Complete function details |
| `function_arns` | Function ARNs |
| `function_names` | Function names |
| `function_invoke_arns` | Invoke ARNs for API Gateway |
| `execution_role_arns` | IAM execution role ARNs |
| `log_group_names` | CloudWatch log group names |
| `function_urls` | Function URL endpoints |
| `layer_arns` | Lambda layer ARNs |
| `security_summary` | Security configuration overview |
| `performance_summary` | Performance metrics summary |
| `cost_optimization_summary` | Cost optimization insights |

## Security Best Practices

### IAM and Access Control
- **Least Privilege**: Automatic IAM roles with minimal required permissions
- **Service-Specific Roles**: Separate execution roles per function
- **Policy Attachment**: Support for additional managed and custom policies
- **Resource-Based Policies**: Function permissions for external service access

### Encryption and Data Protection
- **Environment Variables**: KMS encryption for sensitive configuration
- **CloudWatch Logs**: Encrypted log storage with customer-managed keys
- **Code Signing**: AWS Signer integration for code integrity
- **VPC Integration**: Network isolation for sensitive workloads

### Network Security
- **VPC Configuration**: Private subnet deployment options
- **Security Groups**: Granular network access control
- **NAT Gateway**: Secure outbound internet access
- **VPC Endpoints**: Private AWS service connectivity

### Monitoring and Compliance
- **X-Ray Tracing**: Distributed request tracing
- **CloudWatch Integration**: Comprehensive logging and monitoring
- **Dead Letter Queues**: Error handling and investigation
- **CloudTrail Integration**: API call auditing

## Performance Optimization

### Memory and CPU Optimization
```hcl
# CPU-intensive workload
memory_size = 1769  # 1 vCPU allocated

# Memory-intensive workload  
memory_size = 3008  # Maximum memory for optimal performance

# Cost-optimized for simple tasks
memory_size = 128   # Minimum memory allocation
```

### Concurrency Management
```hcl
# Reserved concurrency (guaranteed capacity)
reserved_concurrent_executions = 100

# Provisioned concurrency (reduced cold starts)
provisioned_concurrency_config = {
  provisioned_concurrent_executions = 10
  qualifier = "$LATEST"
}
```

### Architecture Selection
```hcl
# Cost optimization with ARM64
architectures = ["arm64"]  # Up to 34% cost savings

# Performance optimization with x86_64
architectures = ["x86_64"]  # Maximum compatibility
```

## Monitoring and Observability

### CloudWatch Integration
- **Automatic Log Groups**: Created with configurable retention
- **Structured Logging**: JSON format support for better parsing
- **Custom Metrics**: Function-specific performance metrics
- **Log Insights**: Advanced log querying capabilities

### X-Ray Tracing
```hcl
tracing_mode = "Active"

# Automatic IAM permissions for X-Ray
# Performance insights and dependency mapping
# Request flow visualization
```

### Performance Monitoring
```hcl
logging_config = {
  log_format = "JSON"
  application_log_level = "INFO"
  system_log_level = "WARN"
}
```

## Event Source Integration

### Supported Event Sources
- **Amazon Kinesis**: Stream processing with configurable batch sizes
- **Amazon DynamoDB**: Table change streams
- **Amazon SQS**: Queue message processing
- **Amazon MSK**: Managed Kafka integration
- **Self-Managed Kafka**: Custom Kafka cluster support
- **Amazon MQ**: Message broker integration

### Event Source Configuration
```hcl
event_source_mappings = {
  kinesis_stream = {
    event_source_arn = "arn:aws:kinesis:region:account:stream/name"
    starting_position = "LATEST"
    batch_size = 100
    maximum_batching_window_in_seconds = 5
    parallelization_factor = 2
    
    # Error handling
    maximum_record_age_in_seconds = 3600
    bisect_batch_on_function_error = true
    maximum_retry_attempts = 3
    
    # Filtering
    filter_criteria = {
      filters = [
        {
          pattern = jsonencode({
            eventType = ["ORDER_CREATED"]
          })
        }
      ]
    }
  }
}
```

## Cost Optimization Strategies

### 1. ARM64 Architecture
- Use Graviton2 processors for up to 34% cost savings
- Suitable for most workloads with identical performance

### 2. Memory Optimization
- Right-size memory allocation based on actual usage
- Monitor CloudWatch metrics for optimization opportunities
- Consider memory vs. execution time trade-offs

### 3. Concurrency Management
- Use reserved concurrency only when necessary
- Implement provisioned concurrency for latency-sensitive functions
- Monitor concurrent execution metrics

### 4. Storage Optimization
- Minimize deployment package size
- Use Lambda layers for shared dependencies
- Optimize ephemeral storage usage

## Troubleshooting Guide

### Common Issues and Solutions

#### Cold Start Performance
```hcl
# Solution 1: Provisioned Concurrency
provisioned_concurrency_config = {
  provisioned_concurrent_executions = 5
}

# Solution 2: Memory Optimization
memory_size = 1024  # More CPU for faster initialization

# Solution 3: Package Size Optimization
# Use layers for dependencies
# Minimize deployment package size
```

#### VPC Connectivity Issues
```hcl
# Ensure NAT Gateway for outbound connectivity
vpc_config = {
  subnet_ids = ["subnet-private-1", "subnet-private-2"]
  security_group_ids = ["sg-lambda-functions"]
}

# Security group must allow outbound HTTPS (443)
# VPC endpoints for AWS services reduce NAT costs
```

#### Permission Errors
```hcl
# Custom IAM policy for additional permissions
custom_iam_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "secretsmanager:GetSecretValue"
      ]
      Resource = "*"
    }
  ]
})
```

#### Memory or Timeout Issues
```hcl
# Increase memory for CPU-bound tasks
memory_size = 3008

# Increase timeout for long-running tasks
timeout = 900

# Monitor CloudWatch metrics:
# - Duration
# - Memory Utilization  
# - Errors and Throttles
```

### Debugging Tools

#### CloudWatch Logs Analysis
```bash
# View recent logs
aws logs tail /aws/lambda/function-name --follow

# Search logs with insights
aws logs start-query \
  --log-group-name /aws/lambda/function-name \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/'
```

#### X-Ray Tracing
- Enable tracing mode "Active"
- Analyze service maps for performance bottlenecks
- Identify cold start impact
- Monitor downstream service dependencies

#### Performance Monitoring
```hcl
# Enhanced monitoring configuration
logging_config = {
  log_format = "JSON"
  application_log_level = "DEBUG"  # Temporary for troubleshooting
  system_log_level = "INFO"
}
```

## Integration Examples

### API Gateway Integration
```hcl
# Lambda function configured for API Gateway
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = module.lambda.function_invoke_arns["api_handler"]
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_names["api_handler"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

### EventBridge Integration
```hcl
# EventBridge rule targeting Lambda
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "lambda-schedule"
  description         = "Trigger Lambda function"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "LambdaTarget"
  arn       = module.lambda.function_arns["scheduled_processor"]
}
```

### Step Functions Integration
```hcl
# Step Functions state machine
resource "aws_sfn_state_machine" "lambda_workflow" {
  name     = "lambda-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Lambda workflow"
    StartAt = "ProcessData"
    States = {
      ProcessData = {
        Type = "Task"
        Resource = module.lambda.function_arns["data_processor"]
        End = true
      }
    }
  })
}
```

## Advanced Patterns

### Blue/Green Deployments with Aliases
```hcl
# Function with alias for blue/green deployments
lambda_functions = {
  api_function = {
    # ... function configuration ...
    publish = true
    
    aliases = {
      name = "live"
      description = "Live production alias"
      routing_config = {
        additional_version_weights = {
          "2" = 0.1  # 10% traffic to new version
        }
      }
    }
  }
}
```

### Multi-Runtime Layer Strategy
```hcl
lambda_layers = {
  common_utils = {
    filename = "layers/common-utils.zip"
    compatible_runtimes = [
      "python3.9", "python3.10", "python3.11"
    ]
    compatible_architectures = ["x86_64", "arm64"]
  }
  
  node_dependencies = {
    filename = "layers/node-deps.zip"
    compatible_runtimes = [
      "nodejs16.x", "nodejs18.x", "nodejs20.x"
    ]
  }
}
```

### Disaster Recovery Configuration
```hcl
# Cross-region deployment for disaster recovery
module "lambda_primary" {
  source = "./modules/lambda"
  
  providers = {
    aws = aws.primary
  }
  
  # ... configuration ...
}

module "lambda_dr" {
  source = "./modules/lambda"
  
  providers = {
    aws = aws.disaster_recovery
  }
  
  # Same configuration as primary
  # ... configuration ...
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |
| archive | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| archive | ~> 2.0 |

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
2. Review AWS Lambda documentation
3. Create an issue in the repository
4. Contact the development team

---

*This module follows AWS Well-Architected Framework principles and is designed for production use with enterprise-grade security, monitoring, and performance optimization capabilities.*