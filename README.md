# Salesforce Application Infrastructure Templates

A comprehensive Terraform infrastructure setup for deploying Salesforce applications on AWS, following best practices and the Well-Architected Framework.

## 🏗️ Architecture Overview

This repository contains a layered infrastructure approach with reusable modules:

```
├── modules/                    # Reusable Terraform modules
│   └── vpc/                   # AWS VPC module with Well-Architected Framework
├── layer/                     # Infrastructure layers
│   ├── core/                  # VPC and networking (foundation)
│   ├── data/                  # Databases and storage
│   ├── backend/               # Application services and APIs  
│   ├── frontend/              # Web applications and CDN
│   └── config/                # Configuration and secrets management
└── Makefile                   # Automation and simplified operations
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.3.0
3. **Make** (usually pre-installed on Unix systems)

```bash
# Check prerequisites
make check-prereqs

# Get help
make help
```

### Deploy Infrastructure

```bash
# Deploy development environment (core layer only)
make dev-setup                 # Initialize and plan
make dev-deploy               # Deploy VPC infrastructure

# Deploy production environment (all layers)
make deploy-all ENV=prod      # Deploy complete infrastructure

# Check status
make status ENV=dev           # Show deployment status
```

## 📖 Makefile Usage

### Environment Management

The Makefile supports four environments with different configurations:

| Environment | CIDR Block | Purpose | Features |
|-------------|------------|---------|----------|
| `dev` | `10.0.0.0/16` | Development | Cost-optimized, single NAT Gateway |
| `qa` | `10.1.0.0/16` | Quality Assurance | Balanced testing environment |
| `uat` | `10.2.0.0/16` | User Acceptance Testing | Pre-production with monitoring |
| `prod` | `10.3.0.0/16` | Production | Full security and high availability |

### Common Commands

```bash
# Individual layer operations
make plan ENV=<env> LAYER=<layer>     # Plan deployment
make apply ENV=<env> LAYER=<layer>    # Apply changes
make destroy ENV=<env> LAYER=<layer>  # Destroy resources
make output ENV=<env> LAYER=<layer>   # Show outputs

# Multi-layer operations  
make init-all                         # Initialize all layers
make plan-all ENV=<env>              # Plan all layers
make deploy-all ENV=<env>            # Deploy all layers (in order)
make destroy-all ENV=<env>           # Destroy all layers (reverse order)

# Development shortcuts
make dev-setup                       # Quick dev environment setup
make dev-deploy                      # Deploy dev environment
make dev-destroy                     # Destroy dev environment

# Utilities
make format-all                      # Format all Terraform files
make validate-all                    # Validate all configurations
make clean                          # Clean temporary files
make status ENV=<env>               # Show environment status
```

### Examples

```bash
# Deploy VPC to development
make apply ENV=dev LAYER=core

# Plan all layers for production
make plan-all ENV=prod

# Check what's deployed in UAT
make status ENV=uat

# Deploy complete production environment
make deploy-all ENV=prod

# Format and validate code
make format-all
make validate-all
```

## 🏛️ Infrastructure Layers

### 1. Core Layer (`layer/core`)
**Foundation networking infrastructure**

- **Purpose**: VPC, subnets, gateways, and routing
- **Dependencies**: None (foundation layer)
- **Outputs**: VPC ID, subnet IDs, security groups
- **Module**: Uses `modules/vpc`

```bash
make apply ENV=prod LAYER=core
```

### 2. Data Layer (`layer/data`) 
**Databases and storage services**

- **Purpose**: RDS, ElastiCache, S3 buckets
- **Dependencies**: Core layer
- **Outputs**: Database endpoints, storage ARNs

```bash
make apply ENV=prod LAYER=data
```

### 3. Backend Layer (`layer/backend`)
**Application services and APIs**

- **Purpose**: ECS, Lambda, API Gateway, Load Balancers
- **Dependencies**: Core and Data layers
- **Outputs**: Service endpoints, load balancer ARNs

```bash  
make apply ENV=prod LAYER=backend
```

### 4. Frontend Layer (`layer/frontend`)
**Web applications and content delivery**

- **Purpose**: CloudFront, S3 static hosting, WAF
- **Dependencies**: Backend layer
- **Outputs**: CDN endpoints, web URLs

```bash
make apply ENV=prod LAYER=frontend  
```

### 5. Config Layer (`layer/config`)
**Configuration and secrets management**

- **Purpose**: Parameter Store, Secrets Manager, IAM roles
- **Dependencies**: All other layers
- **Outputs**: Configuration ARNs, role ARNs

```bash
make apply ENV=prod LAYER=config
```

## 🔧 VPC Module Features

The `modules/vpc` provides enterprise-grade networking:

### Security Features
- ✅ Multi-AZ deployment for high availability
- ✅ Network segmentation (public/private/database tiers)
- ✅ VPC Flow Logs for security monitoring
- ✅ Network ACLs for defense in depth
- ✅ Managed default security group

### Cost Optimization  
- ✅ VPC Endpoints for S3 and DynamoDB
- ✅ Configurable NAT Gateway deployment
- ✅ Environment-specific resource sizing

### Compliance
- ✅ AWS Well-Architected Framework alignment
- ✅ Comprehensive resource tagging
- ✅ Infrastructure as Code best practices

## 🛠️ Development Workflow

### 1. Setup Development Environment

```bash
# Clone repository
git clone <repository-url>
cd templates

# Check prerequisites
make check-prereqs

# Initialize development environment
make dev-setup
```

### 2. Make Changes

```bash
# Format code
make format-all

# Validate changes
make validate-all

# Plan changes
make plan ENV=dev LAYER=core
```

### 3. Test and Deploy

```bash  
# Test in development
make apply ENV=dev LAYER=core

# Verify outputs
make output ENV=dev LAYER=core

# Promote to higher environments
make apply ENV=qa LAYER=core
make apply ENV=uat LAYER=core
make apply ENV=prod LAYER=core
```

## 📋 Best Practices

### Environment Progression
1. **Development**: Rapid iteration and testing
2. **QA**: Integration testing and validation
3. **UAT**: User acceptance and performance testing  
4. **Production**: Stable, monitored, and backed up

### Deployment Order
Always deploy layers in dependency order:
1. Core (networking foundation)
2. Data (databases and storage)
3. Backend (application services)
4. Frontend (web applications)
5. Config (configuration and secrets)

### Safety Measures
- Always run `plan` before `apply`
- Use workspaces for environment isolation
- Review outputs after deployment
- Test in lower environments first

## 🔍 Troubleshooting

### Common Issues

**Terraform initialization fails:**
```bash
make clean-all          # Clean all Terraform files
make init LAYER=core    # Reinitialize
```

**CIDR conflicts:**
- Check existing VPCs in the region
- Verify CIDR blocks in environment tfvars files
- Ensure no overlap with on-premises networks

**Permission errors:**
```bash
make check-aws          # Verify AWS credentials
aws sts get-caller-identity  # Check current user/role
```

**Resource limits:**
- Check VPC limits (default: 5 per region)
- Verify EIP limits (default: 5 per region)
- Confirm NAT Gateway limits

### Debug Commands

```bash
# Show current state
make status ENV=<env>

# List resources
make state-list ENV=<env> LAYER=<layer>

# Show detailed outputs
make output ENV=<env> LAYER=<layer>

# Refresh state
make refresh ENV=<env> LAYER=<layer>
```

## 📚 Additional Tools

### Optional but Recommended

```bash
# Install terraform-docs for documentation
# Install tfsec for security scanning
make security-scan

# Install tflint for linting  
make lint

# Install infracost for cost estimation
make costs ENV=prod
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following established patterns
4. Format and validate code: `make format-all && make validate-all`
5. Test in development environment
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📞 Support

- 📖 **Documentation**: Check layer-specific README files
- 🐛 **Issues**: Create an issue in the repository
- 💡 **Questions**: Review the troubleshooting section
- 🏗️ **Architecture**: See `modules/vpc/README.md` for detailed VPC documentation

**Made with ❤️ for scalable infrastructure**