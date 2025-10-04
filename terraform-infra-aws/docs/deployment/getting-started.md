# Getting Started Guide

This guide will help you deploy the AWS Terraform Infrastructure from scratch. Follow these steps to get your infrastructure up and running quickly.

## Prerequisites

Before you begin, ensure you have completed all the [prerequisites](./prerequisites.md).

## Quick Start (TL;DR)

For experienced users who want to get started immediately:

```bash
# 1. Clone and navigate
git clone <repository-url>
cd terraform-infra-aws

# 2. Configure environment
cd layers/networking/environments/dev
cp terraform.auto.tfvars.example terraform.auto.tfvars
# Edit terraform.auto.tfvars with your values

# 3. Deploy layers in order
for layer in networking security data compute; do
  cd ../../$layer/environments/dev
  terraform init -backend-config=backend.conf
  terraform plan
  terraform apply -auto-approve
done
```

## Detailed Deployment Steps

### Step 1: Repository Setup

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd terraform-infra-aws
   ```

2. **Review Project Structure**
   ```
   terraform-infra-aws/
   ├── layers/          # Infrastructure layers
   │   ├── networking/  # Layer 1: Network foundation
   │   ├── security/    # Layer 2: Security services
   │   ├── data/        # Layer 3: Data services
   │   └── compute/     # Layer 4: Compute services
   ├── modules/         # Reusable Terraform modules
   └── docs/           # Documentation
   ```

3. **Understand Layer Dependencies**
   ```mermaid
   graph TD
       A[1. Networking] --> B[2. Security]
       B --> C[3. Data]
       C --> D[4. Compute]
   ```
   
   **⚠️ Important**: Layers must be deployed in order due to dependencies.

### Step 2: Environment Configuration

#### Choose Your Environment

| Environment | Purpose | Configuration |
|-------------|---------|---------------|
| **dev** | Development and testing | Single AZ, smaller instances |
| **qa** | Quality assurance | Multi-AZ, moderate sizing |
| **uat** | User acceptance testing | Production-like, limited capacity |
| **prod** | Production workloads | Full HA, performance optimized |

#### Configure AWS Backend

1. **Create S3 Bucket for Terraform State**
   ```bash
   aws s3 mb s3://your-project-terraform-state-dev --region us-east-1
   aws s3api put-bucket-versioning \
     --bucket your-project-terraform-state-dev \
     --versioning-configuration Status=Enabled
   ```

2. **Create DynamoDB Table for State Locking**
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock-dev \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
     --region us-east-1
   ```

3. **Update Backend Configuration**
   
   Edit each layer's `backend.conf` file:
   ```hcl
   # layers/*/environments/dev/backend.conf
   bucket         = "your-project-terraform-state-dev"
   key            = "networking/dev/terraform.tfstate"  # Update per layer
   region         = "us-east-1"
   encrypt        = true
   dynamodb_table = "terraform-state-lock-dev"
   ```

### Step 3: Layer 1 - Networking Deployment

The networking layer provides the foundation VPC, subnets, and network security.

1. **Navigate to Networking Layer**
   ```bash
   cd layers/networking/environments/dev
   ```

2. **Review and Edit Configuration**
   ```bash
   # Copy example configuration
   cp terraform.auto.tfvars.example terraform.auto.tfvars
   
   # Edit configuration
   nano terraform.auto.tfvars
   ```

3. **Key Configuration Parameters**
   ```hcl
   # Project Configuration
   project_name = "your-project-name"
   environment  = "dev"
   aws_region   = "us-east-1"
   
   # VPC Configuration
   vpc_cidr_block = "10.0.0.0/16"
   
   # Common Tags
   common_tags = {
     Project     = "your-project-name"
     Environment = "dev"
     Owner       = "your-team"
     CostCenter  = "engineering"
   }
   ```

4. **Deploy Networking Layer**
   ```bash
   # Initialize Terraform
   terraform init -backend-config=backend.conf
   
   # Review planned changes
   terraform plan
   
   # Apply changes
   terraform apply
   ```

5. **Verify Deployment**
   ```bash
   # Check VPC creation
   aws ec2 describe-vpcs --filters "Name=tag:Project,Values=your-project-name"
   
   # Check subnets
   aws ec2 describe-subnets --filters "Name=tag:Project,Values=your-project-name"
   ```

### Step 4: Layer 2 - Security Deployment

The security layer provides IAM roles, KMS keys, secrets management, and security services.

1. **Navigate to Security Layer**
   ```bash
   cd ../../security/environments/dev
   ```

2. **Review Security Configuration**
   ```bash
   # Edit security-specific settings
   nano terraform.auto.tfvars
   ```

3. **Key Security Parameters**
   ```hcl
   # IAM Configuration
   create_admin_users = false  # Set to true if needed
   
   # KMS Configuration
   enable_key_rotation = false  # true for production
   
   # Secrets Configuration
   enable_secrets_rotation = false  # true for production
   
   # Compliance Configuration
   enable_config_rules = false  # true for production
   enable_guardduty   = false  # true for production
   ```

4. **Deploy Security Layer**
   ```bash
   terraform init -backend-config=backend.conf
   terraform plan
   terraform apply
   ```

5. **Verify Security Resources**
   ```bash
   # Check IAM roles
   aws iam list-roles --query 'Roles[?contains(RoleName, `your-project-name`)]'
   
   # Check KMS keys
   aws kms list-keys --query 'Keys[*].KeyId'
   ```

### Step 5: Layer 3 - Data Deployment

The data layer provides databases, storage, and data processing services.

1. **Navigate to Data Layer**
   ```bash
   cd ../../data/environments/dev
   ```

2. **Configure Data Services**
   ```bash
   nano terraform.auto.tfvars
   ```

3. **Key Data Parameters**
   ```hcl
   # RDS Configuration
   rds_instances = {
     primary = {
       engine         = "mysql"
       instance_class = "db.t3.micro"  # Small for dev
       multi_az       = false          # Single AZ for dev
     }
   }
   
   # DynamoDB Configuration
   dynamodb_tables = {
     user-sessions = {
       billing_mode = "PAY_PER_REQUEST"  # Cost-effective for dev
     }
   }
   
   # S3 Configuration
   s3_buckets = {
     application-data = {
       versioning = false  # Disabled for dev
     }
   }
   ```

4. **Deploy Data Layer**
   ```bash
   terraform init -backend-config=backend.conf
   terraform plan
   terraform apply
   ```

5. **Verify Data Resources**
   ```bash
   # Check RDS instances
   aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier'
   
   # Check S3 buckets
   aws s3 ls | grep your-project-name
   
   # Check DynamoDB tables
   aws dynamodb list-tables
   ```

### Step 6: Layer 4 - Compute Deployment

The compute layer provides application hosting, containers, serverless, and API services.

1. **Navigate to Compute Layer**
   ```bash
   cd ../../compute/environments/dev
   ```

2. **Configure Compute Services**
   ```bash
   nano terraform.auto.tfvars
   ```

3. **Key Compute Parameters**
   ```hcl
   # EKS Configuration (optional for dev)
   enable_eks = false  # Set to true if needed
   
   # ECS Configuration
   enable_ecs = true
   ecs_capacity_providers = ["FARGATE_SPOT"]  # Cost-effective for dev
   
   # Lambda Configuration
   lambda_functions = {
     api-handler = {
       runtime     = "python3.11"
       memory_size = 128  # Minimal for dev
       timeout     = 30
     }
   }
   
   # API Gateway Configuration
   enable_api_gateway = true
   ```

4. **Deploy Compute Layer**
   ```bash
   terraform init -backend-config=backend.conf
   terraform plan
   terraform apply
   ```

5. **Verify Compute Resources**
   ```bash
   # Check ECS clusters
   aws ecs list-clusters
   
   # Check Lambda functions
   aws lambda list-functions --query 'Functions[*].FunctionName'
   
   # Check API Gateway APIs
   aws apigateway get-rest-apis --query 'items[*].name'
   ```

## Post-Deployment Verification

### Infrastructure Health Check

1. **Network Connectivity**
   ```bash
   # Check VPC endpoints
   aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[*].VpcEndpointType'
   
   # Verify security groups
   aws ec2 describe-security-groups --filters "Name=tag:Project,Values=your-project-name"
   ```

2. **Application Health**
   ```bash
   # Check ECS service status
   aws ecs describe-services --cluster your-cluster-name --services your-service-name
   
   # Test Lambda function
   aws lambda invoke --function-name your-function-name response.json
   ```

3. **Database Connectivity**
   ```bash
   # Check RDS status
   aws rds describe-db-instances --db-instance-identifier your-db-instance
   
   # Test DynamoDB access
   aws dynamodb scan --table-name your-table-name --limit 1
   ```

### Security Validation

1. **IAM Configuration**
   ```bash
   # Verify IAM roles
   aws iam get-role --role-name your-ecs-role
   
   # Check attached policies
   aws iam list-attached-role-policies --role-name your-ecs-role
   ```

2. **Encryption Status**
   ```bash
   # Verify S3 bucket encryption
   aws s3api get-bucket-encryption --bucket your-bucket-name
   
   # Check RDS encryption
   aws rds describe-db-instances --query 'DBInstances[*].StorageEncrypted'
   ```

3. **Network Security**
   ```bash
   # Check security group rules
   aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
   
   # Verify VPC flow logs
   aws ec2 describe-flow-logs
   ```

## Next Steps

### Development Environment Setup

1. **Configure Local Development**
   ```bash
   # Install kubectl for EKS access
   aws eks update-kubeconfig --region us-east-1 --name your-cluster-name
   
   # Verify cluster access
   kubectl get nodes
   ```

2. **Set Up Application Deployment**
   ```bash
   # Create deployment pipeline
   # Configure CI/CD integration
   # Set up monitoring and alerting
   ```

### Environment Promotion

Once development environment is validated:

1. **Deploy QA Environment**
   ```bash
   # Follow same steps with qa environment configurations
   cd layers/*/environments/qa
   ```

2. **Production Deployment**
   ```bash
   # Use production-grade configurations
   # Enable all security features
   # Configure monitoring and backup
   ```

## Common Issues and Solutions

### Terraform State Issues

**Problem**: State lock errors
```bash
Error: Error locking state: Error acquiring the state lock
```

**Solution**: Release the lock manually
```bash
terraform force-unlock <lock-id>
```

### AWS Resource Limits

**Problem**: Service quota exceeded
```bash
Error: LimitExceededException: Cannot exceed quota for PoliciesPerRole
```

**Solution**: Request quota increase or optimize IAM policies
```bash
aws service-quotas get-service-quota --service-code iam --quota-code L-0DA4ABF3
```

### Network Connectivity

**Problem**: Lambda function cannot reach RDS
```bash
Error: Unable to connect to database
```

**Solution**: Verify security group rules and subnet routing
```bash
# Check security groups allow Lambda subnet to RDS port
# Verify Lambda is in private subnet with route to NAT gateway
```

## Getting Help

- **Documentation**: Check the [troubleshooting guide](./troubleshooting.md)
- **AWS Support**: Use AWS Support for service-specific issues
- **Community**: Check AWS forums and Stack Overflow
- **Internal Support**: Contact your platform team

## Clean Up (Development Only)

To destroy the development environment:

```bash
# Destroy in reverse order
for layer in compute data security networking; do
  cd layers/$layer/environments/dev
  terraform destroy -auto-approve
done
```

⚠️ **Warning**: This will permanently delete all resources. Use with caution!

---

**Congratulations!** You have successfully deployed the AWS Terraform Infrastructure. Your next steps should be to configure monitoring, set up CI/CD pipelines, and deploy your applications.