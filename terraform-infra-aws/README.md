# AWS Infrastructure as Code - Well-Architected Framework

**Author:** Diego A. Zarate

This repository contains a complete AWS infrastructure implementation using Terraform, following the AWS Well-Architected Framework principles and best practices.

## 🏗️ Architecture Overview

This infrastructure is built on the AWS Well-Architected Framework's 6 pillars:

- **Operational Excellence**: Automated deployment, monitoring, and operations
- **Security**: Defense in depth with IAM, encryption, and network security
- **Reliability**: Multi-AZ deployment, auto-scaling, and disaster recovery
- **Performance Efficiency**: Right-sizing, caching, and content delivery optimization
- **Cost Optimization**: Resource tagging, lifecycle policies, and cost monitoring
- **Sustainability**: Efficient resource utilization and energy-conscious design

## 📋 Infrastructure Layers

The infrastructure is organized into logical layers for better maintainability and separation of concerns:

### 🌐 Networking Layer
- **VPC** with public/private subnets across multiple AZs
- **Internet Gateway** and **NAT Gateways** for connectivity
- **Route Tables** and **Network ACLs** for traffic control
- **VPC Endpoints** for secure AWS service access
- **Transit Gateway** for multi-VPC connectivity
- **Security Groups** for application-level security

### 🔒 Security Layer
- **IAM** roles, policies, and OIDC providers
- **KMS** encryption keys for data protection
- **AWS Secrets Manager** for secrets management
- **CloudTrail** for API logging and compliance
- **AWS Config** for compliance monitoring
- **Security Hub** for centralized security findings
- **GuardDuty** for threat detection
- **WAF** for web application protection

### 💾 Data Layer
- **RDS** with Multi-AZ deployment and read replicas
- **DynamoDB** with encryption and backup
- **S3** buckets with lifecycle policies and versioning
- **ElastiCache** for Redis/Memcached caching
- **Aurora** clusters for high-performance databases
- **DocumentDB** for document-based workloads

### ⚡ Compute Layer
- **EKS** clusters for container orchestration
- **Lambda** functions for serverless computing
- **API Gateway** for API management
- **Application Load Balancer** for traffic distribution
- **Auto Scaling Groups** for EC2 fleet management
- **CloudFront** for content delivery
- **ECS** for container services

## 🗂️ Directory Structure

```
terraform-infra-aws/
├── README.md                    # This file
├── Makefile                     # Common operations
├── terraform-manager.sh         # Management script (Linux/macOS)
├── terraform-manager.ps1        # Management script (Windows)
├── global/                      # Global shared resources
├── layers/                      # Infrastructure layers
│   ├── networking/              # VPC, subnets, gateways
│   ├── security/               # IAM, KMS, security services
│   ├── data/                   # Databases and storage
│   └── compute/                # EKS, Lambda, compute resources
└── modules/                    # Reusable Terraform modules
    ├── vpc/                    # VPC and networking
    ├── eks/                    # EKS cluster
    ├── rds/                    # RDS databases
    ├── lambda/                 # Lambda functions
    ├── iam/                    # IAM resources
    ├── kms/                    # KMS encryption
    ├── s3/                     # S3 buckets
    ├── security-groups/        # Security groups
    ├── api-gateway/            # API Gateway
    ├── dynamodb/               # DynamoDB tables
    ├── elasticache/            # ElastiCache clusters
    ├── secrets-manager/        # Secrets Manager
    ├── waf/                    # WAF rules
    └── vpc-endpoints/          # VPC endpoints
```

## 🌍 Environments

The infrastructure supports multiple environments with proper isolation:

- **dev**: Development environment with minimal resources
- **qa**: Quality Assurance environment for testing
- **uat**: User Acceptance Testing environment
- **prod**: Production environment with high availability and performance

Each environment has its own:
- Backend configuration (`backend.conf`)
- Variable definitions (`terraform.auto.tfvars`)
- State management
- Resource tagging strategy

## 🚀 Quick Start

### Prerequisites

- **Terraform** >= 1.9.0
- **AWS CLI** configured with appropriate credentials
- **jq** for JSON processing
- **make** for running Makefile commands

### Environment Setup

1. **Configure AWS credentials:**
   ```bash
   aws configure
   # or use environment variables, IAM roles, or SSO
   ```

2. **Initialize and deploy networking layer (dev environment):**
   ```bash
   cd layers/networking/environments/dev
   terraform init -backend-config=backend.conf
   terraform plan
   terraform apply
   ```

3. **Deploy remaining layers in order:**
   ```bash
   # Security layer
   cd ../../../security/environments/dev
   terraform init -backend-config=backend.conf
   terraform apply

   # Data layer
   cd ../../../data/environments/dev
   terraform init -backend-config=backend.conf
   terraform apply

   # Compute layer
   cd ../../../compute/environments/dev
   terraform init -backend-config=backend.conf
   terraform apply
   ```

### Using Management Scripts

For Linux/macOS:
```bash
./terraform-manager.sh init networking dev
./terraform-manager.sh apply networking dev
./terraform-manager.sh plan security dev
```

For Windows PowerShell:
```powershell
.\terraform-manager.ps1 init networking dev
.\terraform-manager.ps1 apply networking dev
.\terraform-manager.ps1 plan security dev
```

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md) - Step-by-step deployment instructions
- [CI/CD Pipeline](docs/CICD.md) - Automated deployment setup
- [Security Guide](docs/SECURITY.md) - Security implementation details
- [Operations Guide](docs/OPERATIONS.md) - Day-to-day operations and maintenance
- [Monitoring](docs/MONITORING.md) - CloudWatch, logging, and alerting setup
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🏷️ Tagging Strategy

All resources are tagged with:

```hcl
common_tags = {
  Environment     = var.environment
  Project         = var.project_name
  Owner           = var.owner
  CostCenter      = var.cost_center
  ManagedBy       = "terraform"
  Repository      = "terraform-infra-aws"
  Author          = "Diego A. Zarate"
  CreatedDate     = timestamp()
}
```

## 🛡️ Security Best Practices

- **Principle of Least Privilege**: IAM policies grant minimum required permissions
- **Encryption in Transit**: All communications use TLS/SSL
- **Encryption at Rest**: All storage services use AWS KMS encryption
- **Network Segmentation**: Public/private subnets with proper routing
- **Security Monitoring**: CloudTrail, Config, and Security Hub enabled
- **Secrets Management**: No hardcoded credentials, use Secrets Manager
- **Regular Updates**: Automated patching and security updates

## 🔄 State Management

Terraform state is stored in S3 with:
- **Encryption**: Server-side encryption with AWS KMS
- **Versioning**: Enabled for state recovery
- **Locking**: DynamoDB table prevents concurrent modifications
- **Backup**: Cross-region replication for disaster recovery

## 💰 Cost Optimization

- **Resource Tagging**: Comprehensive tagging for cost allocation
- **Right Sizing**: Appropriate instance types and sizes
- **Reserved Instances**: Long-term cost savings for predictable workloads
- **Spot Instances**: Cost-effective compute for fault-tolerant workloads
- **Lifecycle Policies**: Automated data archival and deletion
- **CloudWatch**: Monitoring and alerting for cost anomalies

## 🤝 Contributing

1. Follow the existing code structure and naming conventions
2. Ensure all resources are properly tagged
3. Update documentation for any changes
4. Test in dev environment before promoting
5. Use semantic versioning for releases

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 Author

**Diego A. Zarate**
- Infrastructure Architect
- AWS Solutions Architect
- DevOps Engineer

## 📞 Support

For questions, issues, or contributions, please:
1. Check the troubleshooting guide
2. Review existing documentation
3. Create an issue in the repository
4. Contact the infrastructure team

---

*This infrastructure follows AWS Well-Architected Framework principles and AWS best practices for security, reliability, and cost optimization.*