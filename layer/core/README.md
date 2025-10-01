# Core Layer - VPC Infrastructure

This layer contains the core networking infrastructure using the VPC module. It creates the foundational network components required for all other layers.

## Architecture

The core layer deploys:
- **VPC**: Virtual Private Cloud with configurable CIDR block
- **Subnets**: Public, private, and database subnets across multiple AZs
- **Gateways**: Internet Gateway and NAT Gateways for connectivity
- **Route Tables**: Proper routing configuration for each subnet tier
- **Security**: VPC Flow Logs, Network ACLs, and managed default security group
- **Cost Optimization**: VPC Endpoints for S3 and DynamoDB

## Environment-Specific Configurations

### Development (`dev`)
- **CIDR**: `10.0.0.0/16`
- **AZs**: 2 availability zones
- **NAT Gateway**: Single (cost-optimized)
- **Flow Logs**: Disabled
- **Network ACLs**: Disabled
- **Focus**: Cost optimization and development flexibility

### Quality Assurance (`qa`) 
- **CIDR**: `10.1.0.0/16`
- **AZs**: 2 availability zones
- **NAT Gateway**: Single (cost-optimized)
- **Flow Logs**: Disabled
- **Network ACLs**: Disabled
- **Focus**: Balanced testing environment

### User Acceptance Testing (`uat`)
- **CIDR**: `10.2.0.0/16`
- **AZs**: 3 availability zones
- **NAT Gateway**: Multiple (high availability)
- **Flow Logs**: Enabled
- **Network ACLs**: Disabled
- **Focus**: Pre-production readiness

### Production (`prod`)
- **CIDR**: `10.3.0.0/16`
- **AZs**: 3 availability zones  
- **NAT Gateway**: Multiple (high availability)
- **Flow Logs**: Enabled with CloudWatch
- **Network ACLs**: Enabled
- **Focus**: Maximum security and availability

## Usage

### Using Makefile (Recommended)

The core layer includes a Makefile for simplified operations:

```bash
# From the root directory
make plan ENV=dev LAYER=core          # Plan development deployment
make apply ENV=dev LAYER=core         # Deploy development environment
make destroy ENV=dev LAYER=core       # Destroy development environment
make output ENV=dev LAYER=core        # Show outputs

# From the core layer directory
cd layer/core
make plan ENV=dev                     # Plan development deployment  
make apply ENV=prod                   # Deploy production environment
make output ENV=uat                   # Show UAT outputs
```

### Available Makefile Targets

| Target | Description |
|--------|-------------|
| `help` | Display available commands |
| `init` | Initialize Terraform |
| `plan` | Plan deployment for environment |
| `apply` | Apply deployment for environment |
| `destroy` | Destroy infrastructure |
| `output` | Show Terraform outputs |
| `validate` | Validate configuration |
| `format` | Format Terraform files |
| `clean` | Clean temporary files |

### Multi-Environment Operations

```bash
# Deploy all environments in sequence
make apply ENV=dev LAYER=core
make apply ENV=qa LAYER=core  
make apply ENV=uat LAYER=core
make apply ENV=prod LAYER=core

# Or use the root Makefile for multi-layer operations
make deploy-all ENV=prod              # Deploy all layers for production
make status ENV=dev                   # Check status of all layers
```

### Manual Terraform Commands

If you prefer using Terraform directly:

```bash
# Development
cd layer/core
terraform init
terraform workspace select dev || terraform workspace new dev
terraform plan -var-file="environments/dev/dev.tfvars"
terraform apply -var-file="environments/dev/dev.tfvars"

# Production  
terraform workspace select prod || terraform workspace new prod
terraform plan -var-file="environments/prod/prod.tfvars"
terraform apply -var-file="environments/prod/prod.tfvars"
```

## Outputs

The core layer exposes these outputs for use by other layers:

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC identifier |
| `vpc_cidr_block` | VPC CIDR block |
| `public_subnets` | List of public subnet IDs |
| `private_subnets` | List of private subnet IDs |
| `database_subnets` | List of database subnet IDs |
| `database_subnet_group_name` | RDS subnet group name |
| `internet_gateway_id` | Internet Gateway ID |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `vpc_default_security_group_id` | Default security group ID |

## Security Features

### Network Segmentation
- **Public Subnets**: For load balancers and NAT Gateways
- **Private Subnets**: For application servers and services  
- **Database Subnets**: Isolated tier for databases

### Security Controls
- **VPC Flow Logs**: Network traffic monitoring (UAT/Prod)
- **Network ACLs**: Subnet-level firewall rules (Prod only)
- **Default Security Group**: Managed with deny-all rules
- **VPC Endpoints**: Secure access to AWS services

### Access Control
- **No Direct Internet**: Private and database subnets have no direct internet access
- **NAT Gateways**: Controlled outbound internet access for private subnets
- **Route Tables**: Separate routing for each subnet tier

## Cost Optimization

### Development/QA Optimizations
- Single NAT Gateway to reduce costs
- Flow Logs disabled to avoid log storage costs
- Network ACLs disabled to reduce complexity

### Production Features
- VPC Endpoints for S3 and DynamoDB to reduce data transfer costs
- Multiple NAT Gateways for high availability
- Comprehensive monitoring for cost tracking

## Monitoring and Compliance

### VPC Flow Logs (UAT/Prod)
- **Location**: CloudWatch Logs
- **Retention**: 30 days (configurable)
- **Traffic**: All traffic types
- **Use Cases**: Security monitoring, troubleshooting, compliance

### Tagging Strategy
- **Environment**: Environment identifier
- **Project**: Project name
- **Cost Center**: For cost allocation
- **Compliance**: Regulatory requirements
- **Backup**: Backup requirements

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.3.0
3. **AWS Provider** >= 5.0.0
4. **IAM Permissions** for VPC, EC2, and CloudWatch resources

## Troubleshooting

### Common Issues

1. **CIDR Conflicts**: Ensure CIDR blocks don't overlap with existing VPCs
2. **AZ Availability**: Some AZs might not support all instance types
3. **Resource Limits**: Check VPC, EIP, and NAT Gateway limits
4. **Flow Log Permissions**: Ensure IAM role has CloudWatch Logs permissions

### Validation

```bash
# Validate configuration
terraform validate

# Check plan
terraform plan -var-file="environments/[env]/[env].tfvars"

# Verify resources
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=salesforce-app"
```

## Next Steps

After deploying the core layer:

1. Deploy the **data layer** for databases and storage
2. Deploy the **backend layer** for application services  
3. Deploy the **frontend layer** for web applications
4. Configure monitoring and alerting
5. Set up CI/CD pipelines

## Support

- Review the [VPC module documentation](../../modules/vpc/README.md)
- Check AWS VPC best practices
- Validate network design with security team