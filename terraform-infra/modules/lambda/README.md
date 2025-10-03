# Lambda Terraform Module

## Overview

This Terraform module creates **AWS Lambda functions** with enterprise-grade features including event triggers, environment management, monitoring, security controls, and cost optimization. The module supports multiple runtimes, deployment methods, and integration patterns for serverless applications.

## Features

### 🚀 **Serverless Computing**
- **Multiple Runtimes**: Python, Node.js, Java, Go, .NET, Ruby, and custom runtimes
- **Event-Driven Architecture**: Trigger functions from various AWS services
- **Auto Scaling**: Automatic scaling based on incoming requests
- **Pay-per-Use**: Cost-effective execution model with millisecond billing
- **Cold Start Optimization**: Provisioned concurrency for consistent performance

### 🔗 **Event Sources & Triggers**
- **API Gateway**: RESTful and WebSocket API integration

- **S3 Events**: Object creation, deletion, and modification triggers
- **DynamoDB Streams**: Real-time data processing
- **Kinesis**: Stream processing and analytics
- **SQS**: Queue-based message processing
- **EventBridge**: Event-driven architectures
- **CloudWatch Events**: Scheduled and reactive triggers

### 🔒 **Security & Access Control**
- **IAM Integration**: Fine-grained permissions and execution roles
- **VPC Integration**: Private network access and security groups
- **Environment Variables**: Secure configuration management
- **Secrets Manager**: Automatic secret injection and rotation
- **Layer Security**: Shared code and dependencies management
- **Function URL**: HTTPS endpoints with authentication controls

### 📊 **Monitoring & Observability**
- **CloudWatch Logs**: Automatic logging and log retention
- **CloudWatch Metrics**: Performance and error monitoring
- **X-Ray Tracing**: Distributed tracing and performance analysis
- **Dead Letter Queues**: Error handling and retry mechanisms
- **CloudWatch Insights**: Advanced log analysis and queries

### 💰 **Cost Optimization**
- **Right-Sizing**: Memory and timeout optimization
- **Provisioned Concurrency**: Predictable performance with cost control
- **Reserved Concurrency**: Cost management and resource allocation
- **Lifecycle Management**: Automated cleanup and version management

## Architecture

### 🏗️ **Lambda Architecture Patterns**

```
┌─────────────────────────────────────────────────────────────────┐
│                    Event-Driven Architecture                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │ API Gateway │    │             │    │ CloudWatch  │        │
│  │   Events    │    │  Target     │    │   Events    │        │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘        │
│         │                  │                  │               │
│         │                  │                  │               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │     S3      │    │ DynamoDB    │    │   Kinesis   │        │
│  │   Events    │    │  Streams    │    │   Streams   │        │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘        │
│         │                  │                  │               │
│         └──────────────────┼──────────────────┘               │
│                            │                                  │
│  ┌─────────────────────────▼─────────────────────────┐       │
│  │                Lambda Function                    │       │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│      │
│  │  │   Runtime   │  │ Environment │  │    Layers   ││      │
│  │  │   Handler   │  │ Variables   │  │Dependencies ││      │
│  │  └─────────────┘  └─────────────┘  └─────────────┘│      │
│  │                                                   │       │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│      │
│  │  │ IAM Role    │  │ VPC Config  │  │ Monitoring  ││      │
│  │  │Permissions  │  │   Access    │  │   & Logs    ││      │
│  │  └─────────────┘  └─────────────┘  └─────────────┘│      │
│  └───────────────────────────────────────────────────┘       │
│                            │                                  │
│         ┌──────────────────┼──────────────────┐               │
│         │                  │                  │               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │   DynamoDB  │    │     S3      │    │     RDS     │        │
│  │   Tables    │    │   Buckets   │    │ Databases   │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 📋 **Function Lifecycle**

```
┌─────────────────────────────────────────────────────────────────┐
│                    Lambda Function Lifecycle                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Event Trigger                                              │
│     └─► API Request / S3 Event / DynamoDB Stream               │
│                                                                 │
│  2. Runtime Initialization (Cold Start)                        │
│     ├─► Download Function Package                              │
│     ├─► Initialize Runtime Environment                         │
│     ├─► Load Dependencies and Layers                          │
│     └─► Execute Initialization Code                           │
│                                                                 │
│  3. Handler Execution                                          │
│     ├─► Process Event Data                                     │
│     ├─► Execute Business Logic                                 │
│     ├─► Access External Resources                             │
│     └─► Return Response                                        │
│                                                                 │
│  4. Runtime Reuse (Warm Start)                                │
│     └─► Skip Initialization, Direct to Handler               │
│                                                                 │
│  5. Monitoring & Logging                                       │
│     ├─► CloudWatch Logs                                       │
│     ├─► CloudWatch Metrics                                    │
│     ├─► X-Ray Tracing                                         │
│     └─► Error Handling                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Basic Python Lambda Function

```hcl
module "python_lambda" {
  source = "../../modules/lambda"

  # Basic configuration
  function_name = "my-python-function"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"

  # Deployment package
  filename         = "function.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Function configuration
  timeout     = 30
  memory_size = 256

  # Environment variables
  environment = {
    variables = {
      ENVIRONMENT = "development"
      LOG_LEVEL   = "INFO"
    }
  }

  # IAM permissions
  execution_role_arn = module.iam.lambda_execution_role_arn

  tags = {
    Environment = "development"
    Project     = "my-app"
  }
}

# Package Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/function.zip"
}
```

### API Gateway Integration

```hcl
module "api_lambda" {
  source = "../../modules/lambda"

  function_name = "api-handler"
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  
  # Optimized for API responses
  timeout     = 10
  memory_size = 512

  # Source code from S3
  s3_bucket = aws_s3_bucket.lambda_deployments.bucket
  s3_key    = "api-handler-v1.0.0.zip"

  # Environment configuration
  environment = {
    variables = {
      NODE_ENV    = "production"
      API_VERSION = "v1"
      CORS_ORIGIN = "https://myapp.com"
    }
  }

  # VPC configuration for database access
  vpc_config = {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [module.security_groups.lambda_sg_id]
  }

  # Enable X-Ray tracing
  tracing_config = {
    mode = "Active"
  }

  # Dead letter queue for error handling
  dead_letter_config = {
    target_arn = aws_sqs_queue.dlq.arn
  }

  execution_role_arn = module.iam.api_lambda_role_arn

  tags = {
    Environment = "production"
    Service     = "api"
  }
}

# API Gateway integration
resource "aws_api_gateway_integration" "lambda_proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = module.api_lambda.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

### S3 Event Processing

```hcl
module "s3_processor" {
  source = "../../modules/lambda"

  function_name = "s3-image-processor"
  runtime       = "python3.11"
  handler       = "processor.handle_s3_event"

  # Increased resources for image processing
  timeout     = 300  # 5 minutes
  memory_size = 2048 # 2GB for image processing

  # Deployment configuration
  filename         = "image-processor.zip"
  source_code_hash = data.archive_file.processor_zip.output_base64sha256

  # Environment variables
  environment = {
    variables = {
      OUTPUT_BUCKET     = aws_s3_bucket.processed_images.bucket
      THUMBNAIL_SIZE    = "200x200"
      IMAGE_QUALITY     = "85"
      SUPPORTED_FORMATS = "jpg,png,webp"
    }
  }

  # VPC configuration for enhanced security
  vpc_config = {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [module.security_groups.lambda_sg_id]
  }

  # Layers for image processing libraries
  layers = [
    aws_lambda_layer_version.pillow_layer.arn,
    aws_lambda_layer_version.opencv_layer.arn
  ]

  # Reserved concurrency to control costs
  reserved_concurrent_executions = 10

  execution_role_arn = module.iam.s3_processor_role_arn

  tags = {
    Environment = "production"
    Service     = "image-processing"
  }
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "image_upload" {
  bucket = aws_s3_bucket.source_images.bucket

  lambda_function {
    lambda_function_arn = module.s3_processor.arn
    events             = ["s3:ObjectCreated:*"]
    filter_prefix      = "uploads/"
    filter_suffix      = ".jpg"
  }

  lambda_function {
    lambda_function_arn = module.s3_processor.arn
    events             = ["s3:ObjectCreated:*"]
    filter_prefix      = "uploads/"
    filter_suffix      = ".png"
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

# Lambda permission for S3
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source_images.arn
}
```

### DynamoDB Stream Processing

```hcl
module "stream_processor" {
  source = "../../modules/lambda"

  function_name = "dynamodb-stream-processor"
  runtime       = "java11"
  handler       = "com.example.StreamProcessor::handleRequest"

  # Java runtime configuration
  timeout     = 60
  memory_size = 1024

  # JAR deployment
  s3_bucket = aws_s3_bucket.lambda_deployments.bucket
  s3_key    = "stream-processor-1.0.0.jar"

  # Environment variables
  environment = {
    variables = {
      NOTIFICATION_TOPIC = aws_sns_topic.user_notifications.arn
      AUDIT_TABLE       = aws_dynamodb_table.audit_log.name
      BATCH_SIZE        = "100"
    }
  }

  # Event source mapping configuration
  event_source_mapping = {
    event_source_arn                   = aws_dynamodb_table.users.stream_arn
    function_name                      = null  # Will be set after function creation
    starting_position                  = "LATEST"
    batch_size                        = 10
    maximum_batching_window_in_seconds = 5
    parallelization_factor            = 2
    
    # Error handling
    maximum_record_age_in_seconds = 3600
    maximum_retry_attempts       = 3
    bisect_batch_on_function_error = true
    
    destination_config = {
      on_failure = {
        destination_arn = aws_sqs_queue.stream_dlq.arn
      }
    }
  }

  execution_role_arn = module.iam.stream_processor_role_arn

  tags = {
    Environment = "production"
    Service     = "stream-processing"
  }
}
```

### Scheduled Lambda Function

```hcl
module "scheduled_task" {
  source = "../../modules/lambda"

  function_name = "daily-report-generator"
  runtime       = "nodejs18.x"
  handler       = "report.generateDaily"

  # Long-running task configuration
  timeout     = 900  # 15 minutes
  memory_size = 3008 # Maximum memory

  # Code deployment
  filename         = "report-generator.zip"
  source_code_hash = data.archive_file.report_zip.output_base64sha256

  # Environment configuration
  environment = {
    variables = {
      REPORT_BUCKET     = aws_s3_bucket.reports.bucket
      DATABASE_URL      = "postgresql://${module.rds.endpoint}/reports"
      EMAIL_TOPIC       = aws_sns_topic.report_notifications.arn
      TIMEZONE          = "America/New_York"
    }
  }

  # VPC access for database
  vpc_config = {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [module.security_groups.lambda_sg_id]
  }

  execution_role_arn = module.iam.report_generator_role_arn

  tags = {
    Environment = "production"
    Service     = "reporting"
    Schedule    = "daily"
  }
}

# CloudWatch Event Rule for scheduling
resource "aws_cloudwatch_event_rule" "daily_report" {
  name                = "daily-report-schedule"
  description         = "Trigger daily report generation"
  schedule_expression = "cron(0 8 * * ? *)"  # Daily at 8 AM UTC
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_report.name
  target_id = "TriggerLambda"
  arn       = module.scheduled_task.arn

  # Pass configuration to the Lambda
  input = jsonencode({
    report_type = "daily"
    format     = "pdf"
  })
}

# Permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.scheduled_task.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report.arn
}
```

### Container Image Lambda

```hcl
module "container_lambda" {
  source = "../../modules/lambda"

  function_name = "ml-inference-api"
  package_type  = "Image"

  # Container image configuration
  image_uri = "${aws_ecr_repository.ml_models.repository_url}:latest"

  # Optimized for ML inference
  timeout     = 600   # 10 minutes
  memory_size = 10240 # 10GB
  
  # Architecture for ML workloads
  architectures = ["x86_64"]

  # Environment configuration
  environment = {
    variables = {
      MODEL_BUCKET    = aws_s3_bucket.ml_models.bucket
      INFERENCE_MODE  = "production"
      BATCH_SIZE      = "32"
      GPU_ENABLED     = "false"
    }
  }

  # Image configuration
  image_config = {
    entry_point = ["/app/bootstrap"]
    command     = ["handler.inference"]
    working_directory = "/app"
  }

  # Provisioned concurrency for consistent performance
  provisioned_concurrency_config = {
    provisioned_concurrent_executions = 5
  }

  execution_role_arn = module.iam.ml_inference_role_arn

  tags = {
    Environment = "production"
    Service     = "ml-inference"
    Runtime     = "container"
  }
}

# ECR repository for container images
resource "aws_ecr_repository" "ml_models" {
  name                 = "ml-inference-lambda"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

### Lambda Layer for Shared Dependencies

```hcl
# Create a Lambda layer for shared dependencies
resource "aws_lambda_layer_version" "common_libs" {
  filename            = "common-libs-layer.zip"
  layer_name          = "common-python-libs"
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256

  compatible_runtimes      = ["python3.9", "python3.10", "python3.11"]
  compatible_architectures = ["x86_64", "arm64"]

  description = "Common Python libraries for Lambda functions"

  license_info = "MIT"
}

# Package layer dependencies
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layers/python"
  output_path = "${path.module}/common-libs-layer.zip"
}

# Lambda function using the layer
module "lambda_with_layer" {
  source = "../../modules/lambda"

  function_name = "function-with-layer"
  runtime       = "python3.11"
  handler       = "app.handler"

  filename         = "function-code.zip"
  source_code_hash = data.archive_file.function_zip.output_base64sha256

  # Include the layer
  layers = [
    aws_lambda_layer_version.common_libs.arn,
    "arn:aws:lambda:us-east-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:42"
  ]

  timeout     = 30
  memory_size = 256

  execution_role_arn = module.iam.lambda_execution_role_arn

  tags = {
    Environment = "production"
    HasLayers   = "true"
  }
}
```

## Configuration Options

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `function_name` | `string` | Name of the Lambda function |
| `runtime` | `string` | Function runtime (python3.11, nodejs18.x, etc.) |
| `handler` | `string` | Function entrypoint in your code |

### Code Deployment

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `filename` | `string` | `null` | Path to the deployment package (ZIP) |
| `s3_bucket` | `string` | `null` | S3 bucket containing deployment package |
| `s3_key` | `string` | `null` | S3 key of the deployment package |
| `s3_object_version` | `string` | `null` | S3 object version to use |
| `image_uri` | `string` | `null` | Container image URI for Image package type |
| `source_code_hash` | `string` | `null` | Used to trigger updates when source changes |

### Function Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `timeout` | `number` | `3` | Function timeout in seconds (1-900) |
| `memory_size` | `number` | `128` | Memory allocation in MB (128-10240) |
| `package_type` | `string` | `"Zip"` | Deployment package type (Zip or Image) |
| `architectures` | `list(string)` | `["x86_64"]` | Instruction set architecture |
| `layers` | `list(string)` | `[]` | Lambda layers to attach |

### Environment & Security

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | `map` | `{}` | Environment variables |
| `kms_key_arn` | `string` | `null` | KMS key for environment variable encryption |
| `execution_role_arn` | `string` | - | IAM role for function execution |
| `vpc_config` | `object` | `null` | VPC configuration for network access |

### Performance & Scaling

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `reserved_concurrent_executions` | `number` | `null` | Reserved concurrency limit |
| `provisioned_concurrency_config` | `object` | `null` | Provisioned concurrency settings |
| `dead_letter_config` | `object` | `null` | Dead letter queue configuration |

### Monitoring & Tracing

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tracing_config` | `object` | `null` | X-Ray tracing configuration |
| `log_retention_in_days` | `number` | `14` | CloudWatch logs retention period |

## Outputs

### Function Information

| Output | Description |
|--------|-------------|
| `function_name` | Lambda function name |
| `function_arn` | Lambda function ARN |
| `arn` | Lambda function ARN (alias for function_arn) |
| `invoke_arn` | ARN for invoking the Lambda function |
| `qualified_arn` | Function ARN with version or alias |

### Function Configuration

| Output | Description |
|--------|-------------|
| `version` | Latest published version of the function |
| `last_modified` | Date the function was last modified |
| `source_code_hash` | SHA256 hash of the function's deployment package |
| `source_code_size` | Size of the function's deployment package |

### Runtime Information

| Output | Description |
|--------|-------------|
| `runtime` | Runtime environment for the function |
| `handler` | Function entry point |
| `timeout` | Function timeout value |
| `memory_size` | Function memory allocation |

## Best Practices

### 🚀 **Performance Optimization**

1. **Memory and CPU**
   - Monitor actual memory usage and right-size functions
   - Use Performance Insights to identify optimization opportunities
   - Consider provisioned concurrency for latency-sensitive applications

2. **Cold Start Optimization**
   - Minimize deployment package size
   - Use connection pooling and keep connections warm
   - Initialize resources outside the handler function
   - Consider using Provisioned Concurrency for critical functions

3. **Code Optimization**
   ```python
   # Good: Initialize outside handler
   import boto3
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('MyTable')
   
   def lambda_handler(event, context):
       # Handler code here
       return table.get_item(Key={'id': event['id']})
   ```

### 🔒 **Security Best Practices**

1. **IAM Permissions**
   - Follow principle of least privilege
   - Use resource-specific permissions
   - Regularly audit and review permissions

2. **Environment Variables**
   - Use AWS Secrets Manager or Parameter Store for sensitive data
   - Encrypt environment variables with KMS
   - Avoid hardcoding credentials in code

3. **VPC Security**
   - Use private subnets for database access
   - Implement security groups with minimal required ports
   - Consider NAT Gateway costs for internet access

### 💰 **Cost Optimization**

1. **Resource Management**
   - Monitor and optimize memory allocation
   - Use reserved concurrency to control costs
   - Implement efficient error handling to reduce retries

2. **Architecture Patterns**
   - Use event-driven architectures to reduce idle time
   - Batch processing for high-volume workloads
   - Consider Step Functions for complex workflows

3. **Monitoring and Alerting**
   ```hcl
   # Cost monitoring alarm
   resource "aws_cloudwatch_metric_alarm" "lambda_cost" {
     alarm_name          = "lambda-high-invocations"
     comparison_operator = "GreaterThanThreshold"
     evaluation_periods  = "2"
     metric_name         = "Invocations"
     namespace           = "AWS/Lambda"
     period              = "300"
     statistic           = "Sum"
     threshold           = "10000"
     alarm_description   = "This metric monitors lambda invocations"
   
     dimensions = {
       FunctionName = module.my_lambda.function_name
     }
   }
   ```

### 📊 **Monitoring Best Practices**

1. **CloudWatch Metrics**
   - Monitor duration, errors, throttles, and concurrent executions
   - Set up alarms for error rates and performance degradation
   - Use custom metrics for business-specific monitoring

2. **Logging Strategy**
   ```python
   import json
   import logging
   
   logger = logging.getLogger()
   logger.setLevel(logging.INFO)
   
   def lambda_handler(event, context):
       logger.info(f"Processing event: {json.dumps(event)}")
       
       try:
           # Function logic
           result = process_data(event)
           logger.info(f"Successfully processed: {result}")
           return result
       except Exception as e:
           logger.error(f"Error processing event: {str(e)}")
           raise
   ```

3. **X-Ray Tracing**
   - Enable X-Ray for distributed tracing
   - Add custom segments for external service calls
   - Monitor service maps for performance bottlenecks

## Integration Examples

### API Gateway REST API

```hcl
# Complete API Gateway integration
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "lambda-rest-api"
  description = "REST API backed by Lambda"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = module.api_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "lambda_api" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = "prod"
}
```



### SQS Queue Processing

```hcl
# SQS Event Source Mapping
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.processing_queue.arn
  function_name    = module.queue_processor.arn
  batch_size       = 10

  # Error handling
  maximum_batching_window_in_seconds = 5
  
  function_response_types = ["ReportBatchItemFailures"]
  
  scaling_config {
    maximum_concurrency = 100
  }
}

# Dead letter queue for failed messages
resource "aws_sqs_queue" "dlq" {
  name = "processing-dlq"
  
  message_retention_seconds = 1209600  # 14 days
}

resource "aws_sqs_queue_redrive_policy" "processing_queue" {
  queue_url = aws_sqs_queue.processing_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}
```

## Troubleshooting

### Common Issues

#### **Cold Start Latency**
```python
# Optimize imports and initialization
import json
import boto3
from aws_lambda_powertools import Logger, Tracer

# Initialize outside handler
logger = Logger()
tracer = Tracer()
dynamodb = boto3.resource('dynamodb')

@tracer.capture_lambda_handler
@logger.inject_lambda_context
def lambda_handler(event, context):
    # Handler logic
    return {'statusCode': 200}
```

#### **Timeout Issues**
```hcl
# Monitor timeout metrics
resource "aws_cloudwatch_metric_alarm" "lambda_timeout" {
  alarm_name          = "lambda-timeout-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "25000"  # 25 seconds for 30-second timeout
  alarm_description   = "Lambda function approaching timeout"

  dimensions = {
    FunctionName = module.my_lambda.function_name
  }
}
```

#### **Memory Issues**
```bash
# Check memory usage in CloudWatch Logs
grep "Max Memory Used" /aws/lambda/my-function

# Or use PowerTools for automatic memory reporting
from aws_lambda_powertools import Logger

logger = Logger()

@logger.inject_lambda_context
def lambda_handler(event, context):
    # Memory usage will be automatically logged
    return process_event(event)
```

#### **VPC Connectivity**
```bash
# Test VPC connectivity from Lambda
import socket

def test_connectivity():
    try:
        socket.create_connection(("database.internal", 5432), timeout=5)
        return "Connected to database"
    except socket.error as e:
        return f"Connection failed: {e}"
```

### Debugging Commands

```bash
# View function configuration
aws lambda get-function --function-name my-function

# Check recent invocations
aws logs filter-log-events \
  --log-group-name /aws/lambda/my-function \
  --start-time $(date -d "1 hour ago" +%s)000

# Monitor real-time logs
aws logs tail /aws/lambda/my-function --follow

# Check function metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=my-function \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average,Maximum
```

## Requirements

- **Terraform**: >= 1.9.0
- **AWS Provider**: ~> 5.80
- **Minimum Permissions**: Lambda management, IAM role creation, CloudWatch access

## Related Documentation

- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Lambda Performance Optimization](https://docs.aws.amazon.com/lambda/latest/dg/performance-optimization.html)
- [AWS Lambda Powertools](https://awslabs.github.io/aws-lambda-powertools/)

---

> ⚡ **Serverless Excellence**: This Lambda module provides enterprise-grade serverless computing with automatic scaling, comprehensive monitoring, and battle-tested integration patterns built-in.
