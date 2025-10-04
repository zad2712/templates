# Compute Layer

This layer provides comprehensive compute services for the AWS infrastructure, including container orchestration (EKS/ECS), serverless computing (Lambda), API management (API Gateway), content delivery (CloudFront), and batch processing capabilities.

## Architecture Overview

The compute layer follows a microservices architecture pattern with multiple compute options:

- **EKS (Elastic Kubernetes Service)**: Container orchestration for cloud-native applications
- **ECS (Elastic Container Service)**: Managed container service with Fargate and EC2 launch types
- **Lambda**: Serverless compute for event-driven architectures
- **API Gateway**: Managed API service with REST and HTTP API support
- **Application Load Balancer**: Layer 7 load balancing with advanced routing
- **CloudFront**: Global content delivery network
- **Elastic Beanstalk**: Platform-as-a-Service for web applications
- **AWS Batch**: Managed batch computing service

## Dependencies

This layer depends on:
- **Networking Layer**: VPC, subnets, security groups, and network infrastructure
- **Security Layer**: IAM roles, KMS keys, secrets, and security policies
- **Data Layer**: Storage services, databases, and data processing resources

## Features

### Container Services

#### Amazon EKS
- **Managed Kubernetes Control Plane**: Fully managed Kubernetes API server
- **Node Groups**: Auto-scaling worker nodes with multiple instance types
- **Fargate Profiles**: Serverless containers for specific namespaces
- **Add-ons**: Core DNS, VPC CNI, EBS CSI driver, and kube-proxy
- **OIDC Identity Provider**: Integration with AWS IAM for service accounts
- **Encryption**: Envelope encryption for Kubernetes secrets
- **Logging**: Control plane logging to CloudWatch

#### Amazon ECS
- **Cluster Management**: Container orchestration with capacity providers
- **Service Discovery**: Native service discovery integration
- **Task Definitions**: Containerized application specifications
- **Auto Scaling**: Target tracking and step scaling policies
- **Load Balancer Integration**: Seamless ALB integration
- **Container Insights**: Performance monitoring and logging

### Serverless Services

#### AWS Lambda
- **Function Management**: Deployment and versioning
- **Event Source Mappings**: Integration with SQS, Kinesis, DynamoDB
- **Function URLs**: HTTP(S) endpoints for Lambda functions
- **Layers**: Shared code and dependencies
- **VPC Integration**: Access to private resources
- **Dead Letter Queues**: Error handling and retry logic
- **Provisioned Concurrency**: Reduced cold start latency

#### API Gateway
- **REST APIs**: RESTful web services with resource-based routing
- **HTTP APIs**: Low-latency, cost-effective HTTP APIs
- **Custom Domains**: Custom domain names with SSL certificates
- **VPC Links**: Private integration with VPC resources
- **Authentication**: IAM, Lambda authorizers, and API keys
- **Throttling**: Request rate limiting and burst protection
- **Caching**: Response caching for improved performance

### Load Balancing and Content Delivery

#### Application Load Balancer
- **Layer 7 Routing**: Content-based routing with path and host rules
- **Target Groups**: Health checking and load distribution
- **SSL Termination**: Centralized SSL/TLS certificate management
- **WAF Integration**: Web application firewall protection
- **Access Logs**: Request logging to S3

#### CloudFront
- **Global Distribution**: Edge locations worldwide
- **Origin Protection**: Origin access identity for S3 origins
- **Cache Behaviors**: Customizable caching rules
- **Lambda@Edge**: Serverless compute at edge locations
- **Real-time Logs**: Detailed request logging
- **Security Headers**: Response header manipulation

### Platform Services

#### Elastic Beanstalk
- **Application Management**: Multi-environment application deployment
- **Platform Versions**: Managed platform updates
- **Health Monitoring**: Application and infrastructure health
- **Auto Scaling**: Capacity management based on demand
- **Rolling Deployments**: Zero-downtime application updates

#### AWS Batch
- **Compute Environments**: Managed and unmanaged compute resources
- **Job Queues**: Priority-based job scheduling
- **Job Definitions**: Container and multinode job specifications
- **Spot Integration**: Cost optimization with Spot instances
- **Array Jobs**: Parallel job execution

## Configuration

### Environment Variables

All services support environment-specific configuration:

```hcl
# Development Environment
environment = "dev"
enable_eks = false
enable_ecs = true
lambda_log_level = "DEBUG"

# Production Environment
environment = "prod"
enable_eks = true
enable_ecs = true
lambda_log_level = "WARN"
```

### EKS Configuration

```hcl
eks_cluster_version = "1.28"
eks_cluster_endpoint_private_access = true
eks_cluster_endpoint_public_access = false

eks_node_groups = {
  general = {
    instance_types = ["m5.large", "m5.xlarge"]
    scaling_config = {
      desired_size = 3
      max_size     = 10
      min_size     = 1
    }
    capacity_type = "ON_DEMAND"
  }
  
  spot = {
    instance_types = ["m5.large", "m5.xlarge", "m4.large"]
    scaling_config = {
      desired_size = 0
      max_size     = 20
      min_size     = 0
    }
    capacity_type = "SPOT"
  }
}
```

### ECS Configuration

```hcl
ecs_capacity_providers = ["FARGATE", "FARGATE_SPOT", "EC2"]
ecs_enable_container_insights = true

ecs_services = {
  web-app = {
    task_definition = {
      family = "web-app"
      cpu    = "512"
      memory = "1024"
      
      containers = [{
        name  = "web"
        image = "nginx:latest"
        portMappings = [{
          containerPort = 80
          protocol     = "tcp"
        }]
      }]
    }
    
    desired_count = 2
    
    load_balancer = {
      alb_key          = "main"
      target_group_key = "web"
      container_name   = "web"
      container_port   = 80
    }
  }
}
```

### Lambda Configuration

```hcl
lambda_functions = {
  api-handler = {
    function_name = "api-handler"
    runtime      = "python3.11"
    handler      = "lambda_function.lambda_handler"
    filename     = "api-handler.zip"
    
    memory_size = 256
    timeout     = 30
    
    environment_variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL  = var.lambda_log_level
    }
    
    vpc_config = {
      subnet_ids         = data.terraform_remote_state.networking.outputs.private_subnet_ids
      security_group_ids = [data.terraform_remote_state.networking.outputs.security_group_ids["lambda"]]
    }
  }
}
```

### API Gateway Configuration

```hcl
api_gateway_rest_apis = {
  main = {
    name        = "main-api"
    description = "Main REST API"
    
    endpoint_configuration = {
      types = ["REGIONAL"]
    }
  }
}

api_gateway_http_apis = {
  fast = {
    name        = "fast-api"
    description = "High-performance HTTP API"
    
    cors_configuration = {
      allow_origins = ["*"]
      allow_methods = ["GET", "POST", "PUT", "DELETE"]
      allow_headers = ["content-type", "authorization"]
    }
  }
}
```

## Security

### Network Security
- **VPC Integration**: All services deployed within private subnets
- **Security Groups**: Least-privilege network access control
- **WAF Protection**: Web application firewall for public-facing services
- **SSL/TLS**: End-to-end encryption with AWS Certificate Manager

### Identity and Access Management
- **IAM Roles**: Service-specific roles with minimal permissions
- **Service Accounts**: EKS service account integration with IAM
- **Secrets Management**: Integration with AWS Secrets Manager
- **Encryption**: KMS encryption for all data at rest

### Monitoring and Compliance
- **CloudWatch Logs**: Centralized logging for all services
- **X-Ray Tracing**: Distributed tracing for Lambda and API Gateway
- **Container Insights**: ECS and EKS performance monitoring
- **Access Logging**: ALB and CloudFront access logs

## Monitoring and Observability

### Metrics
- **CloudWatch Metrics**: CPU, memory, network, and custom metrics
- **Application Metrics**: Request latency, error rates, throughput
- **Infrastructure Metrics**: Node health, cluster status, capacity utilization

### Logging
- **Structured Logging**: JSON-formatted logs with consistent fields
- **Log Aggregation**: CloudWatch Logs with retention policies
- **Log Insights**: Advanced log querying and analysis

### Tracing
- **X-Ray Integration**: End-to-end request tracing
- **Service Map**: Visual representation of service dependencies
- **Performance Analysis**: Latency bottleneck identification

## Scaling and Performance

### Auto Scaling
- **Horizontal Pod Autoscaler**: EKS pod scaling based on metrics
- **Cluster Autoscaler**: EKS node group scaling
- **ECS Auto Scaling**: Service and capacity provider scaling
- **Lambda Concurrency**: Reserved and provisioned concurrency

### Performance Optimization
- **Caching**: CloudFront and API Gateway caching
- **Connection Pooling**: Database connection optimization
- **CDN**: Global content delivery with edge caching
- **Load Balancing**: Intelligent traffic distribution

## Disaster Recovery

### Backup and Recovery
- **Multi-AZ Deployment**: High availability across availability zones
- **Cross-Region Replication**: Data replication for disaster recovery
- **Automated Backups**: Scheduled backup policies
- **Point-in-Time Recovery**: Granular recovery options

### Business Continuity
- **Health Checks**: Automated failure detection
- **Failover**: Automatic traffic redirection
- **Circuit Breakers**: Fault isolation and recovery
- **Blue/Green Deployments**: Zero-downtime deployments

## Cost Optimization

### Resource Optimization
- **Spot Instances**: Cost-effective compute for fault-tolerant workloads
- **Fargate Spot**: Serverless containers with up to 70% cost savings
- **Reserved Capacity**: Predictable workload cost optimization
- **Right Sizing**: Optimal instance and container sizing

### Usage Monitoring
- **Cost Allocation Tags**: Resource cost tracking
- **Usage Reports**: Detailed cost analysis
- **Budget Alerts**: Cost threshold notifications
- **Savings Plans**: Commitment-based pricing

## Deployment

### Prerequisites
1. Networking layer deployed
2. Security layer deployed
3. Data layer deployed

### Deployment Steps

1. **Configure Variables**: Set environment-specific variables
   ```bash
   cd layers/compute/environments/dev
   # Edit terraform.auto.tfvars
   ```

2. **Initialize Terraform**: 
   ```bash
   terraform init -backend-config=backend.conf
   ```

3. **Plan Deployment**:
   ```bash
   terraform plan
   ```

4. **Deploy Resources**:
   ```bash
   terraform apply
   ```

### Environment Management

Each environment has separate configuration:
- `environments/dev/`: Development environment
- `environments/qa/`: Quality assurance environment  
- `environments/uat/`: User acceptance testing environment
- `environments/prod/`: Production environment

## Outputs

The layer provides comprehensive outputs for integration:

### Service Endpoints
- EKS cluster endpoint and certificate authority
- ECS cluster ARN and service ARNs
- Lambda function ARNs and invoke ARNs
- API Gateway endpoints and execution ARNs
- Load balancer DNS names and hosted zone IDs
- CloudFront distribution domain names

### Security Integration
- IAM role ARNs for cross-service access
- Security group IDs for network integration
- KMS key IDs for encryption

### Monitoring Integration
- CloudWatch log group names
- X-Ray tracing configurations
- SNS topic ARNs for alerts

## Best Practices

### Security
- Use least-privilege IAM policies
- Enable encryption at rest and in transit
- Implement network segmentation
- Regular security assessments
- Secrets rotation automation

### Performance  
- Implement caching strategies
- Use connection pooling
- Optimize container images
- Monitor and tune scaling policies
- Regular performance testing

### Cost Management
- Use Spot instances where appropriate
- Implement resource tagging
- Regular cost reviews
- Automated rightsizing
- Reserved capacity planning

### Operational Excellence
- Infrastructure as Code
- Automated testing
- Monitoring and alerting
- Incident response procedures
- Regular disaster recovery testing

## Troubleshooting

### Common Issues

#### EKS Node Registration
```bash
# Check node status
kubectl get nodes

# Describe node for events
kubectl describe node <node-name>

# Check EKS cluster logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks
```

#### ECS Service Deployment
```bash
# Check service status
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# Check task definition
aws ecs describe-task-definition --task-definition <task-def-arn>

# View service events
aws ecs describe-services --cluster <cluster-name> --services <service-name> --query 'services[0].events'
```

#### Lambda Function Issues
```bash
# Check function logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda

# View function configuration
aws lambda get-function --function-name <function-name>

# Check execution role
aws lambda get-function-configuration --function-name <function-name> --query 'Role'
```

### Support Resources
- AWS Documentation: Service-specific guides
- CloudWatch Logs: Centralized logging
- AWS Support: Technical assistance
- Community Forums: Peer support and solutions