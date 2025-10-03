# Compute Layer

## Overview

The **Compute Layer** provides comprehensive compute infrastructure including containers, serverless functions, virtual machines, and orchestration services. This layer builds upon the networking, security, and data foundations to deliver scalable application hosting and processing capabilities.

## Purpose

The compute layer establishes:
- **Container Orchestration**: EKS for Kubernetes workloads
- **Serverless Computing**: Lambda functions for event-driven processing
- **Virtual Machines**: EC2 instances and Auto Scaling Groups
- **Container Services**: ECS for Docker container management
- **Load Balancing**: Application Load Balancers for traffic distribution

## Architecture

### ⚙️ **Core Compute Components**

#### **Amazon EKS (Elastic Kubernetes Service)**
- **Managed Control Plane**: AWS-managed Kubernetes API server
- **Worker Nodes**: EC2 instances or Fargate for serverless containers
- **Add-ons**: AWS Load Balancer Controller, Cluster Autoscaler, Metrics Server
- **Security**: IAM integration, encryption, and network policies

#### **AWS Lambda**
- **Event-Driven**: Serverless function execution
- **Auto Scaling**: Automatic capacity management
- **Integrations**: Native AWS service integrations
- **Cost Optimization**: Pay-per-request pricing model

#### **Amazon EC2 & Auto Scaling**
- **Virtual Machines**: Flexible instance types and sizes
- **Auto Scaling Groups**: Automatic capacity scaling
- **Launch Templates**: Standardized instance configurations
- **Spot Instances**: Cost-optimized compute capacity

#### **Amazon ECS (Elastic Container Service)**
- **Task Management**: Docker container orchestration
- **Service Discovery**: Built-in service mesh capabilities
- **Fargate Integration**: Serverless container execution
- **Application Integration**: Load balancer and service mesh integration

#### **Amazon API Gateway**
- **REST API Management**: Complete API lifecycle with resources, methods, and integrations
- **Authorization & Security**: Multiple authentication types (IAM, Cognito, Lambda, API Keys)
- **Throttling & Rate Limiting**: Usage plans with quota and rate controls
- **Monitoring & Logging**: CloudWatch integration, X-Ray tracing, access logging
- **Performance Optimization**: Response caching, compression, regional endpoints
- **Custom Domain Support**: SSL/TLS termination with custom certificates

#### **Application Load Balancer (ALB)**
- **Layer 7 Routing**: HTTP/HTTPS traffic distribution
- **SSL Termination**: Centralized certificate management
- **Health Checks**: Application-aware health monitoring
- **Target Groups**: Dynamic backend service management

## Layer Structure

```
compute/
├── README.md                    # This documentation
├── main.tf                      # Main compute configuration
├── variables.tf                 # Input variables
├── outputs.tf                   # Compute layer outputs
├── locals.tf                    # Local compute calculations
├── providers.tf                 # Terraform and provider configuration
└── environments/
    ├── dev/
    │   ├── backend.conf         # S3 backend configuration
    │   └── terraform.auto.tfvars# Dev compute settings
    ├── qa/
    │   ├── backend.conf
    │   └── terraform.auto.tfvars
    ├── uat/
    │   ├── backend.conf
    │   └── terraform.auto.tfvars
    └── prod/
        ├── backend.conf
        └── terraform.auto.tfvars
```

## Modules Used

### **EKS Module**
```hcl
module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "../../modules/eks"

  # Cluster configuration
  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.eks_cluster_version
  
  # Network configuration
  vpc_id     = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.networking.outputs.private_subnets
  
  # Node groups and Fargate profiles
  node_groups      = var.eks_node_groups
  fargate_profiles = var.eks_fargate_profiles
  
  # Add-ons and marketplace components
  cluster_addons = var.eks_addons
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  enable_cluster_autoscaler          = var.enable_cluster_autoscaler
  enable_metrics_server              = var.enable_metrics_server
  
  tags = local.common_tags
}
```

### **Application Load Balancer Module**
```hcl
module "alb" {
  count  = var.enable_load_balancer ? 1 : 0
  source = "../../modules/alb"

  name    = "${var.project_name}-${var.environment}"
  vpc_id  = data.terraform_remote_state.networking.outputs.vpc_id
  subnets = data.terraform_remote_state.networking.outputs.public_subnets
  
  # Security groups
  security_groups = [
    data.terraform_remote_state.security.outputs.security_group_ids["alb"]
  ]
  
  # Target groups and listeners
  target_groups = var.target_groups
  listeners     = var.alb_listeners
  
  tags = local.common_tags
}
```

### **Auto Scaling Group Module**
```hcl
module "asg" {
  count  = var.enable_auto_scaling ? 1 : 0
  source = "../../modules/asg"

  name = "${var.project_name}-${var.environment}"
  
  # Launch template configuration
  launch_template = {
    name_prefix   = "${var.project_name}-${var.environment}-"
    image_id      = var.ami_id
    instance_type = var.instance_type
    key_name      = var.key_pair_name
    
    vpc_security_group_ids = [
      data.terraform_remote_state.security.outputs.security_group_ids["ec2"]
    ]
    
    iam_instance_profile = data.terraform_remote_state.security.outputs.service_roles["ec2"].instance_profile_name
    user_data           = base64encode(var.user_data_script)
  }
  
  # Auto Scaling configuration
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  
  vpc_zone_identifier = data.terraform_remote_state.networking.outputs.private_subnets
  
  tags = local.common_tags
}
```

### **Lambda Module**
```hcl
module "lambda" {
  count  = length(var.lambda_functions) > 0 ? 1 : 0
  source = "../../modules/lambda"

  functions = var.lambda_functions
  
  # VPC configuration
  vpc_config = {
    subnet_ids         = data.terraform_remote_state.networking.outputs.private_subnets
    security_group_ids = [data.terraform_remote_state.security.outputs.security_group_ids["lambda"]]
  }
  
  # IAM role
  execution_role_arn = data.terraform_remote_state.security.outputs.service_roles["lambda"].arn
  
  tags = local.common_tags
}
```

### **ECS Module**
```hcl
module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"

  cluster_name = "${var.project_name}-${var.environment}"
  
  # Capacity providers
  capacity_providers = var.ecs_capacity_providers
  
  # Container insights
  container_insights = var.enable_container_insights

  tags = local.common_tags
}
```

### **API Gateway Module**
```hcl
module "api_gateway" {
  count  = var.enable_api_gateway ? 1 : 0
  source = "../../modules/api-gateway"

  api_name        = "${var.project_name}-${var.environment}-api"
  api_description = "REST API Gateway for ${var.project_name}"
  stage_name      = var.api_gateway_stage_name

  # Security and performance
  enable_access_logging    = var.api_gateway_enable_access_logging
  enable_xray_tracing     = var.api_gateway_enable_xray_tracing
  cache_cluster_enabled   = var.api_gateway_cache_cluster_enabled
  
  # API structure
  api_resources     = var.api_gateway_resources
  api_methods       = var.api_gateway_methods
  usage_plans       = var.api_gateway_usage_plans
  api_keys          = var.api_gateway_api_keys
  
  # Custom domain (optional)
  domain_name       = var.api_gateway_domain_name
  certificate_arn   = var.api_gateway_certificate_arn
  
  tags = local.common_tags
}
```

## EKS Configuration

### 🚀 **Kubernetes Cluster Setup**

#### **Production EKS Configuration**
```hcl
# Cluster settings
eks_cluster_version = "1.31"
eks_endpoint_private_access = true
eks_endpoint_public_access = false  # Private only

# Logging for audit and compliance
eks_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_log_retention_days = 90

# Node groups with different instance types
eks_node_groups = {
  general = {
    instance_types = ["m5.large", "m5.xlarge"]
    capacity_type  = "ON_DEMAND"
    desired_size   = 3
    max_size      = 10
    min_size      = 3
    disk_size     = 100
    
    labels = {
      role = "general"
      environment = "prod"
    }
  }
  
  monitoring = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    desired_size   = 2
    max_size      = 3
    min_size      = 1
    
    labels = {
      role = "monitoring"
    }
    
    taints = [
      {
        key    = "monitoring"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

# Fargate profiles for serverless workloads
eks_fargate_profiles = {
  system = {
    selectors = [
      {
        namespace = "kube-system"
        labels = {}
      }
    ]
  }
  
  production_apps = {
    selectors = [
      {
        namespace = "prod-apps"
        labels = {
          compute-type = "fargate"
        }
      }
    ]
  }
}
```

#### **Development EKS Configuration**
```hcl
# Cost-optimized for development
eks_cluster_version = "1.31"
eks_endpoint_private_access = true
eks_endpoint_public_access = true  # Accessible for development

# Minimal logging
eks_cluster_log_types = ["api", "audit"]
eks_log_retention_days = 7

# Single node group with SPOT instances
eks_node_groups = {
  general = {
    instance_types = ["t3.small", "t3.medium"]
    capacity_type  = "SPOT"  # Cost optimization
    desired_size   = 1
    max_size      = 3
    min_size      = 1
    disk_size     = 20
    
    labels = {
      role = "general"
      environment = "dev"
    }
  }
}
```

## API Gateway Configuration

### 🚀 **REST API Setup**

#### **Basic API Gateway**
```hcl
# Enable API Gateway with basic configuration
enable_api_gateway = true
api_gateway_stage_name = "v1"
api_gateway_endpoint_types = ["REGIONAL"]

# Basic API structure
api_gateway_resources = {
  api = {
    path_part = "api"
  }
  health = {
    path_part = "health"
    parent_id = "api"
  }
}

# Health check endpoint
api_gateway_methods = {
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
        integration_response = {
          response_templates = {
            "application/json" = "{\"status\": \"healthy\"}"
          }
        }
      }
    }
  }
}
```

#### **Production API with Authentication**
```hcl
# Production API Gateway with full features
enable_api_gateway = true
api_gateway_stage_name = "v1"
api_gateway_enable_access_logging = true
api_gateway_enable_xray_tracing = true
api_gateway_cache_cluster_enabled = true

# Usage plans for rate limiting
api_gateway_usage_plans = {
  basic_plan = {
    name = "Basic Plan"
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
  }
}

# API keys for authentication
api_gateway_api_keys = {
  client_key = {
    name        = "client-api-key"
    description = "Client application API key"
    enabled     = true
  }
}
```

#### **Lambda Integration Example**
```hcl
# API method with Lambda backend
api_gateway_methods = {
  get_users = {
    resource_key     = "users"
    http_method      = "GET"
    authorization    = "AWS_IAM"
    api_key_required = true
    
    integration = {
      type = "AWS_PROXY"
      integration_http_method = "POST"
      uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.users.arn}/invocations"
    }
    
    responses = {
      "200" = {
        status_code = "200"
        integration_response = {}
      }
    }
  }
}
```

### 🔧 **Marketplace Add-ons**

#### **AWS Load Balancer Controller**
```hcl
# Latest version for ALB/NLB ingress
enable_aws_load_balancer_controller = true
aws_load_balancer_controller_chart_version = "1.8.1"
aws_load_balancer_controller_namespace = "kube-system"
```

#### **Cluster Autoscaler**
```hcl
# Automatic node scaling based on pod requirements
enable_cluster_autoscaler = true
cluster_autoscaler_chart_version = "9.37.0"
cluster_autoscaler_namespace = "kube-system"
```

#### **Metrics Server**
```hcl
# Resource utilization metrics for HPA
enable_metrics_server = true
metrics_server_chart_version = "3.12.1"
metrics_server_namespace = "kube-system"
```

## Lambda Configuration

### ⚡ **Serverless Functions**

#### **API Processing Function**
```hcl
api_processor = {
  description = "API request processing function"
  runtime     = "python3.11"
  handler     = "lambda_function.lambda_handler"
  filename    = "api_processor.zip"
  memory_size = 256
  timeout     = 30
  
  environment_variables = {
    DATABASE_URL = data.terraform_remote_state.data.outputs.rds_endpoints["primary_db"].endpoint
    CACHE_URL    = data.terraform_remote_state.data.outputs.elasticache_endpoints["redis"].primary_endpoint
  }
}
```

#### **Data Processing Function**
```hcl
data_processor = {
  description = "Batch data processing function"
  runtime     = "python3.11"
  handler     = "processor.handler"
  s3_bucket   = data.terraform_remote_state.data.outputs.s3_buckets["app_data"].id
  s3_key      = "functions/data_processor.zip"
  memory_size = 1024
  timeout     = 300
  
  environment_variables = {
    OUTPUT_BUCKET = data.terraform_remote_state.data.outputs.s3_buckets["processed_data"].id
  }
}
```

## Load Balancer Configuration

### 🌐 **Application Load Balancer**

#### **Production ALB Setup**
```hcl
target_groups = {
  app = {
    port     = 80
    protocol = "HTTP"
    health_check = {
      enabled             = true
      healthy_threshold   = 2
      interval            = 30
      matcher             = "200"
      path                = "/health"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 2
    }
  }
  
  api = {
    port     = 8080
    protocol = "HTTP"
    health_check = {
      enabled             = true
      healthy_threshold   = 2
      interval            = 15
      matcher             = "200,404"
      path                = "/api/health"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 3
    }
  }
}

alb_listeners = {
  https = {
    port     = 443
    protocol = "HTTPS"
    default_action = {
      type             = "forward"
      target_group_arn = "app"
    }
  }
  
  http_redirect = {
    port     = 80
    protocol = "HTTP"
    default_action = {
      type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}
```

## Auto Scaling Configuration

### 📈 **EC2 Auto Scaling**

#### **Web Application ASG**
```hcl
# Launch template
ami_id        = "ami-0abcdef1234567890"  # Latest Amazon Linux 2
instance_type = "t3.medium"
key_pair_name = "myapp-keypair"

# Auto Scaling settings
asg_min_size         = 2
asg_max_size         = 10
asg_desired_capacity = 3

# User data for application setup
user_data_script = <<-EOF
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install application
docker pull myapp:latest
docker run -d -p 80:8080 myapp:latest
EOF

# EBS volumes
ebs_volumes = [
  {
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
]
```

## Environment-Specific Configurations

### 🌍 **Development Environment**
```hcl
# Cost-optimized compute resources
enable_eks = true
enable_load_balancer = true
enable_auto_scaling = false  # Manual scaling for dev
enable_ecs = false
enable_container_insights = false

# EKS with SPOT instances
eks_node_groups = {
  general = {
    instance_types = ["t3.small", "t3.medium"]
    capacity_type  = "SPOT"
    desired_size   = 1
    max_size      = 3
    min_size      = 1
  }
}

# Minimal Lambda functions
lambda_functions = {
  dev_api = {
    memory_size = 128
    timeout     = 30
  }
}
```

### 🏭 **Production Environment**
```hcl
# Full compute suite with high availability
enable_eks = true
enable_load_balancer = true
enable_auto_scaling = true
enable_ecs = true
enable_container_insights = true

# Production EKS with ON_DEMAND instances
eks_node_groups = {
  general    = { /* production configuration */ }
  monitoring = { /* dedicated monitoring nodes */ }
}

# Comprehensive Lambda setup
lambda_functions = {
  api_processor    = { /* production API function */ }
  data_processor   = { /* batch processing function */ }
  notification_svc = { /* notification service */ }
}

# Production ALB with multiple target groups
target_groups = {
  app     = { /* main application */ }
  api     = { /* API services */ }
  admin   = { /* admin interface */ }
}
```

## Key Outputs

```hcl
# EKS Information
output "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_security_group_id : null
}

# Load Balancer Information
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? module.alb[0].lb_dns_name : null
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = var.enable_load_balancer ? module.alb[0].lb_zone_id : null
}

# Auto Scaling Information
output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = var.enable_auto_scaling ? module.asg[0].autoscaling_group_arn : null
}

# Lambda Information
output "lambda_function_arns" {
  description = "Map of Lambda function ARNs"
  value       = length(var.lambda_functions) > 0 ? module.lambda[0].function_arns : {}
}

# API Gateway Information
output "api_gateway_rest_api_id" {
  description = "ID of the REST API"
  value       = var.enable_api_gateway ? module.api_gateway[0].rest_api_id : null
}

output "api_gateway_stage_invoke_url" {
  description = "URL to invoke the API pointing to the stage"
  value       = var.enable_api_gateway ? module.api_gateway[0].stage_invoke_url : null
}

output "api_gateway_execution_arn" {
  description = "Execution ARN for Lambda permissions"
  value       = var.enable_api_gateway ? module.api_gateway[0].rest_api_execution_arn : null
}
```

## Performance Optimization

### 🚀 **Compute Performance**

#### **EKS Optimization**
- **Instance Types**: Use compute-optimized instances for CPU-intensive workloads
- **Node Groups**: Separate node groups for different workload types
- **Horizontal Pod Autoscaler**: Automatic pod scaling based on metrics
- **Cluster Autoscaler**: Automatic node scaling based on pod requirements

#### **Lambda Optimization**
- **Memory Allocation**: Right-size memory for optimal performance/cost ratio
- **Cold Start Reduction**: Use provisioned concurrency for low-latency functions
- **VPC Configuration**: Avoid VPC when not needed to reduce cold start time
- **Function Packaging**: Minimize deployment package size

#### **Load Balancer Optimization**
- **Target Group Health Checks**: Optimize interval and timeout settings
- **Connection Draining**: Configure appropriate deregistration delay
- **Sticky Sessions**: Use when required for stateful applications
- **SSL/TLS**: Optimize cipher suites and certificate handling

### 📊 **Monitoring and Observability**

#### **CloudWatch Metrics**
- **EKS**: Node CPU/memory utilization, pod count, cluster health
- **Lambda**: Duration, error rate, concurrent executions, throttles
- **ALB**: Request count, response time, error rates, target health
- **ASG**: Instance count, CPU utilization, scaling activities

#### **Custom Metrics**
- Application-specific business metrics
- Custom CloudWatch metrics from applications
- Prometheus metrics collection in EKS
- Application Performance Monitoring (APM) integration

## Cost Optimization

### 💰 **Compute Cost Management**

#### **EKS Cost Optimization**
- **SPOT Instances**: Use for development and fault-tolerant workloads
- **Right Sizing**: Monitor and adjust node instance types
- **Cluster Autoscaler**: Automatically scale down unused nodes
- **Fargate**: Use for workloads with variable or unpredictable traffic

#### **Lambda Cost Optimization**
- **Memory Optimization**: Find optimal memory/performance ratio
- **Timeout Settings**: Set appropriate timeouts to avoid unnecessary charges
- **Architecture**: Use ARM-based Graviton2 processors when possible
- **Reserved Concurrency**: Use only when necessary to avoid blocking other functions

#### **EC2 Cost Optimization**
- **Reserved Instances**: Purchase for stable, predictable workloads
- **SPOT Instances**: Use for fault-tolerant applications
- **Right Sizing**: Regular analysis and adjustment of instance types
- **Scheduled Scaling**: Scale down during off-hours for non-production environments

## Deployment

### **Prerequisites**
1. **Networking Layer**: VPC and subnets must exist
2. **Security Layer**: IAM roles and security groups must be configured
3. **Data Layer**: Database endpoints available (if required)

### **Deployment Commands**
```bash
# Initialize and deploy compute layer
cd layers/compute/environments/prod
terraform init -backend-config=backend.conf
terraform plan -var-file=terraform.auto.tfvars
terraform apply -var-file=terraform.auto.tfvars
```

### **EKS Post-Deployment**
```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name myproject-prod

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces

# Deploy sample applications
kubectl apply -f k8s-manifests/
```

## Security Best Practices

### 🔒 **Compute Security**

#### **EKS Security**
- **RBAC**: Implement Role-Based Access Control
- **Network Policies**: Restrict pod-to-pod communication
- **Pod Security Standards**: Enforce security contexts and policies
- **Image Scanning**: Scan container images for vulnerabilities

#### **Lambda Security**
- **Least Privilege**: Minimal IAM permissions
- **Environment Variables**: Use Systems Manager Parameter Store or Secrets Manager
- **VPC Configuration**: Only when needed for data access
- **Runtime Security**: Keep runtime versions updated

#### **EC2 Security**
- **Security Groups**: Restrictive inbound rules
- **Instance Metadata**: Use IMDSv2 only
- **Systems Manager**: Use Session Manager instead of SSH
- **Patch Management**: Automated patching with Systems Manager

#### **API Gateway Security**
- **Authentication**: Multiple methods (IAM, Cognito, Lambda authorizers, API Keys)
- **Authorization**: Resource-based policies and method-level permissions
- **Request Validation**: Schema-based input validation and sanitization
- **Rate Limiting**: Usage plans with quotas and throttling
- **WAF Integration**: Web Application Firewall for additional protection
- **CORS Configuration**: Proper cross-origin resource sharing setup

## Troubleshooting

### 🔧 **Common Issues**

#### **EKS Troubleshooting**
```bash
# Check cluster status
kubectl get cs

# Check node status
kubectl describe nodes

# Check pod logs
kubectl logs -f deployment/myapp

# Check cluster autoscaler logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

#### **Lambda Troubleshooting**
- **CloudWatch Logs**: Check function execution logs
- **X-Ray Tracing**: Enable for performance analysis
- **Dead Letter Queues**: Configure for failed function executions
- **VPC Connectivity**: Verify security groups and subnet routing

## Related Documentation

- [Main Project README](../../README.md)
- [Networking Layer README](../networking/README.md)
- [Security Layer README](../security/README.md)
- [Data Layer README](../data/README.md)
- [EKS Module Documentation](../../modules/eks/README.md)
- [AWS Compute Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)

---

> ⚙️ **Compute Foundation**: This layer provides scalable, secure, and cost-effective compute resources for your applications. Choose the right compute service based on your workload characteristics and requirements.
