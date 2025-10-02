# Terraform Infrastructure as Code - AWS Multi-Layer Architecture

This repository contains a comprehensive Terraform infrastructure setup following AWS best practices, designed for multi-environment deployments across different layers.

## 🏗️ Architecture Overview

The infrastructure is organized into **4 distinct layers**, each with **4 environments** (dev, qa, uat, prod):

```
terraform-infra/
├── layers/
│   ├── networking/     # VPC, subnets, gateways, networking components
│   ├── security/       # IAM, KMS, security groups, WAF, certificates
│   ├── compute/        # EC2, Auto Scaling, Load Balancers, ECS, Lambda
│   └── data/          # RDS, ElastiCache, DynamoDB, S3
├── modules/           # Reusable Terraform modules
│   └── vpc/          # VPC module with best practices
├── global/           # Global resources (if any)
├── Makefile          # Automation for Unix/Linux/macOS
└── terraform-manager.ps1  # PowerShell script for Windows
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. **Terraform** >= 1.5.0 - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
3. **AWS Credentials** configured (`aws configure`)

### Initial Setup

1. **Clone and configure the project:**
   ```bash
   git clone <your-repo>
   cd terraform-infra
   ```

2. **Update project configuration:**
   
   Edit the following files to match your project:
   - `Makefile`: Update `PROJECT_NAME` variable
   - `terraform-manager.ps1`: Update `$ProjectName` variable
   - Update `backend.conf` files to replace `PROJECT_NAME` with your actual project name

3. **Bootstrap AWS infrastructure (creates S3 bucket and DynamoDB table for state management):**
   
   **Using Makefile (Linux/macOS):**
   ```bash
   make bootstrap ENV=dev
   make bootstrap ENV=qa
   make bootstrap ENV=uat
   make bootstrap ENV=prod
   ```
   
   **Using PowerShell (Windows):**
   ```powershell
   .\terraform-manager.ps1 -Action bootstrap -Environment dev
   .\terraform-manager.ps1 -Action bootstrap -Environment qa
   .\terraform-manager.ps1 -Action bootstrap -Environment uat
   .\terraform-manager.ps1 -Action bootstrap -Environment prod
   ```

### Deployment

Deploy layers in the following order (dependencies matter):

1. **Networking Layer** (VPC, subnets)
2. **Security Layer** (IAM, KMS, Security Groups)
3. **Compute Layer** (EC2, ALB, ASG)
4. **Data Layer** (RDS, ElastiCache, DynamoDB)

**Example deployment for dev environment:**

```bash
# Using Makefile
make init ENV=dev LAYER=networking
make plan ENV=dev LAYER=networking
make apply ENV=dev LAYER=networking

make init ENV=dev LAYER=security
make plan ENV=dev LAYER=security
make apply ENV=dev LAYER=security

# Continue with compute and data layers...
```

**Or deploy all layers at once:**
```bash
make deploy-all ENV=dev
```

## 📁 Layer Details

### 🌐 Networking Layer
- **VPC** with configurable CIDR
- **Public/Private/Database subnets** across multiple AZs
- **Internet Gateway** and **NAT Gateways**
- **Route tables** and associations
- **VPC Endpoints** (optional)
- **Transit Gateway** (optional, for multi-VPC connectivity)

### 🔒 Security Layer
- **IAM roles and policies** for applications and services
- **KMS keys** for encryption (RDS, S3, general purpose)
- **Security Groups** with configurable rules
- **AWS WAF** (optional)
- **AWS Secrets Manager** integration
- **SSL Certificates** via ACM

### 💻 Compute Layer
- **Application Load Balancer** with target groups
- **Auto Scaling Groups** with launch templates
- **ECS Cluster** (optional)
- **Lambda Functions** (optional)
- Health checks and monitoring integration

### 📊 Data Layer
- **RDS** with Multi-AZ support for production
- **ElastiCache Redis** for caching
- **DynamoDB tables** with encryption
- **S3 buckets** with versioning and encryption
- Automated backups and snapshots

## 🛠️ Usage Examples

### Initialize and Plan
```bash
# Linux/macOS
make init ENV=dev LAYER=networking
make plan ENV=dev LAYER=networking

# Windows
.\terraform-manager.ps1 -Action init -Environment dev -Layer networking
.\terraform-manager.ps1 -Action plan -Environment dev -Layer networking
```

### Apply Changes
```bash
# Linux/macOS
make apply ENV=dev LAYER=networking

# Windows
.\terraform-manager.ps1 -Action apply -Environment dev -Layer networking
```

### View Outputs
```bash
# Linux/macOS
make output ENV=dev LAYER=networking

# Windows
.\terraform-manager.ps1 -Action output -Environment dev -Layer networking
```

### Destroy Resources
```bash
# Linux/macOS
make destroy ENV=dev LAYER=networking

# Windows
.\terraform-manager.ps1 -Action destroy -Environment dev -Layer networking
```

## 🎯 Environment-Specific Configuration

Each environment has its own configuration in `layers/{layer}/environments/{env}/terraform.auto.tfvars`:

- **Dev**: Minimal resources for development
- **QA**: Testing environment with moderate resources
- **UAT**: Production-like environment for user acceptance testing
- **Prod**: Full production configuration with high availability

## 🔐 State Management

- **Remote State**: Stored in S3 with versioning enabled
- **State Locking**: DynamoDB table prevents concurrent modifications
- **Encryption**: State files are encrypted at rest
- **Separation**: Each layer and environment has its own state file

## 📊 Addressing Plan

The infrastructure uses a carefully planned IP addressing scheme:

| Environment | VPC CIDR      | Public Subnets | Private Subnets | Database Subnets |
|-------------|---------------|----------------|-----------------|------------------|
| Dev         | 10.10.0.0/16  | 10.10.0.0/24   | 10.10.128.0/24  | 10.10.240.0/28   |
| QA          | 10.20.0.0/16  | 10.20.0.0/24   | 10.20.128.0/24  | 10.20.240.0/28   |
| UAT         | 10.30.0.0/16  | 10.30.0.0/24   | 10.30.128.0/24  | 10.30.240.0/28   |
| Prod        | 10.40.0.0/16  | 10.40.0.0/24   | 10.40.192.0/24  | 10.40.240.16/28  |

## 🎨 Customization

### Adding New Environments
1. Create new directories in each layer: `layers/{layer}/environments/{new_env}/`
2. Add `backend.conf` and `terraform.auto.tfvars` files
3. Update validation rules in variables.tf files
4. Update automation scripts

### Adding New Resources
1. Create new modules in the `modules/` directory
2. Reference modules in the appropriate layer's `main.tf`
3. Add variables to `variables.tf`
4. Add outputs to `outputs.tf`

### Modifying Existing Resources
1. Update the relevant module or layer configuration
2. Run `terraform plan` to review changes
3. Apply changes using the automation scripts

## 🧪 Validation and Testing

```bash
# Validate Terraform syntax
make validate ENV=dev LAYER=networking

# Format Terraform files
make format

# Lint Terraform files (requires tflint)
make lint

# Clean up temporary files
make clean
```

## 🔍 Troubleshooting

### Common Issues

1. **State Lock Errors**: Use `terraform force-unlock <LOCK_ID>` if needed
2. **Resource Conflicts**: Check if resources already exist in AWS
3. **Permission Errors**: Ensure AWS credentials have sufficient permissions
4. **Backend Errors**: Verify S3 bucket and DynamoDB table exist

### Debug Mode
Add `-var debug=true` to enable additional logging and outputs.

## 📚 Best Practices Implemented

- ✅ **Layered Architecture**: Separation of concerns across networking, security, compute, and data
- ✅ **Environment Separation**: Isolated state and resources per environment  
- ✅ **Remote State**: S3 backend with DynamoDB locking
- ✅ **Encryption**: All data encrypted at rest and in transit
- ✅ **Tagging Strategy**: Consistent tagging for cost tracking and management
- ✅ **High Availability**: Multi-AZ deployments for production
- ✅ **Security**: Least privilege IAM, security groups, and network segmentation
- ✅ **Automation**: Scripts for common operations
- ✅ **Documentation**: Comprehensive documentation and examples

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the existing patterns
4. Test changes in a dev environment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For questions or issues:
1. Check this README and documentation
2. Review Terraform and AWS documentation
3. Open an issue in the repository
4. Contact the DevOps team

---

**Note**: Always test changes in development environments before applying to production!