# Terraform Infrastructure Templates

This repository contains enterprise-grade Infrastructure as Code (IaC) templates for both AWS and Azure cloud platforms, following best practices for multi-layer architecture, security, and scalability.

## 📁 Repository Structure

```
templates/
├── terraform-infra-aws/      # AWS Infrastructure Templates
│   ├── layers/               # Infrastructure layers (networking, security, data, compute)
│   ├── modules/              # Reusable AWS service modules
│   ├── global/               # Global shared resources
│   └── terraform-manager.ps1 # Management script
│
└── terraform-infra-azure/    # Azure Infrastructure Templates
    ├── layers/               # Infrastructure layers (networking, security, data, compute)
    ├── modules/              # Reusable Azure service modules
    ├── global/               # Global shared resources
    └── terraform-manager.ps1 # Management script
```

## 🏗️ Infrastructure Architecture

Both AWS and Azure templates follow the same **4-layer architecture**:

1. **🌐 Networking Layer** - Virtual networks, subnets, security groups, gateways
2. **🔒 Security Layer** - IAM/RBAC, key management, security services
3. **🗄️ Data Layer** - Databases, storage, caching services
4. **⚙️ Compute Layer** - Kubernetes, serverless, application services

## 🚀 Quick Start

### Prerequisites

- **Terraform** >= 1.9.0
- **PowerShell** >= 7.0 (Windows) or **Bash** (Linux/macOS)

For AWS:
- **AWS CLI** >= 2.0
- **AWS Account** with appropriate permissions

For Azure:
- **Azure CLI** >= 2.50.0
- **Azure Subscription** with appropriate permissions

### Getting Started with AWS

```bash
cd terraform-infra-aws

# Configure AWS credentials
aws configure

# Bootstrap backend (one-time setup)
.\terraform-manager.ps1 -Action bootstrap -Environment dev

# Deploy networking layer
.\terraform-manager.ps1 -Action deploy-all -Environment dev -Layer networking
```

### Getting Started with Azure

```bash
cd terraform-infra-azure

# Login to Azure
az login

# Bootstrap backend (one-time setup)
.\terraform-manager.ps1 -Action bootstrap -Environment dev

# Deploy networking layer
.\terraform-manager.ps1 -Action deploy-all -Environment dev -Layer networking
```

## 🌍 Multi-Environment Support

Both platforms support multiple environments:
- **dev** - Development environment
- **qa** - Quality assurance environment  
- **uat** - User acceptance testing environment
- **prod** - Production environment

Each environment has isolated state and configuration.

## 📦 Service Mapping

| Category | AWS Service | Azure Service | Module |
|----------|-------------|---------------|---------|
| **Compute** | EKS | AKS | `eks` / `aks` |
| | Lambda | Functions | `lambda` / `function-app` |
| | EC2 | Virtual Machines | `ec2` / `virtual-machine` |
| **Networking** | VPC | Virtual Network | `vpc` / `virtual-network` |
| | Security Groups | Network Security Groups | `security-groups` / `network-security-group` |
| | ALB/NLB | Application Gateway | `alb` / `application-gateway` |
| **Data** | RDS | SQL Database | `rds` / `sql-database` |
| | DynamoDB | Cosmos DB | `dynamodb` / `cosmos-db` |
| | ElastiCache | Redis Cache | `elasticache` / `redis-cache` |
| **Storage** | S3 | Storage Account | `s3` / `storage-account` |
| **Security** | IAM | RBAC + Managed Identity | `iam` / `rbac` |
| | KMS | Key Vault | `kms` / `key-vault` |
| | WAF | Web Application Firewall | `waf` / `waf` |

## 🛠️ Management Commands

Both platforms use similar management scripts:

```bash
# Available actions
bootstrap     # Create backend resources
init          # Initialize Terraform
plan          # Generate execution plan
apply         # Apply changes
destroy       # Destroy resources
validate      # Validate configuration
format        # Format files
output        # Show outputs
clean         # Clean local state
deploy-all    # Complete deployment workflow

# Usage examples
.\terraform-manager.ps1 -Action plan -Environment dev -Layer networking
make plan ENV=dev LAYER=networking  # Using Makefile
```

## 🔐 Security Best Practices

### AWS
- IAM least privilege access
- VPC with private subnets
- Encryption at rest and in transit
- Security Groups with minimal access
- KMS key management
- CloudTrail logging

### Azure
- RBAC with custom roles
- Virtual Network with NSGs
- Managed Identity authentication
- Private Endpoints for services
- Key Vault for secrets
- Azure Monitor logging

## 💰 Cost Optimization

- **Resource Tagging** for cost allocation
- **Auto Scaling** based on metrics
- **Spot/Reserved Instances** where appropriate
- **Storage Tiering** for optimal costs
- **Right-sizing** recommendations
- **Budget Alerts** and monitoring

## 📊 Monitoring & Observability

### AWS
- CloudWatch for metrics and logs
- AWS X-Ray for distributed tracing
- CloudTrail for API logging
- AWS Config for compliance

### Azure
- Azure Monitor for metrics and logs
- Application Insights for APM
- Log Analytics for centralized logging
- Azure Security Center for compliance

## 🔄 CI/CD Integration

Templates support integration with:
- **GitHub Actions**
- **Azure DevOps Pipelines**
- **AWS CodePipeline**
- **GitLab CI/CD**
- **Jenkins**

Example pipeline configurations included in each platform directory.

## 📖 Documentation

Each platform includes comprehensive documentation:
- Architecture diagrams
- Module documentation
- Variable descriptions
- Output explanations
- Best practices guides
- Troubleshooting guides

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow platform-specific conventions
4. Update documentation
5. Test thoroughly
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions and support:
- Open an issue in this repository
- Check platform-specific documentation
- Review cloud provider documentation

---

**Built with ❤️ for Multi-Cloud Infrastructure**