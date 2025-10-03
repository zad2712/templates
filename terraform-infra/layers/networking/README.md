# Networking Layer

## Overview

The **Networking Layer** provides the foundational network infrastructure for all other layers in the Terraform architecture. This layer creates the Virtual Private Cloud (VPC), subnets, routing, and network connectivity components that serve as the backbone for your AWS infrastructure.

## Purpose

The networking layer establishes:
- **Isolated Network Environment**: Secure VPC with proper CIDR allocation
- **Multi-AZ Architecture**: High availability across multiple availability zones
- **Public/Private Segregation**: Separate subnets for different access patterns
- **Internet Connectivity**: Managed internet and NAT gateways
- **Network Security**: Foundation for network-level security controls

## Architecture

### 🏗️ **Core Components**

#### **VPC (Virtual Private Cloud)**
- Main network container for all resources
- Environment-specific CIDR blocks
- DNS hostname and resolution enabled
- Flow logs for network monitoring

#### **Subnets**
- **Public Subnets**: For internet-facing resources (ALB, NAT Gateway)
- **Private Subnets**: For application and database resources
- **Database Subnets**: Isolated subnets for sensitive data stores
- Multi-AZ distribution for high availability

#### **Routing & Gateways**
- **Internet Gateway**: Public internet access
- **NAT Gateway**: Outbound internet access for private resources
- **Route Tables**: Traffic routing configuration
- **VPC Endpoints**: Private connectivity to AWS services

#### **Network Connectivity**
- **Transit Gateway**: Cross-VPC and on-premises connectivity (optional)
- **VPC Peering**: Direct VPC-to-VPC connections (optional)
- **VPN Gateway**: Secure on-premises connectivity (optional)

## Layer Structure

```
networking/
├── README.md                    # This documentation
├── main.tf                      # Main networking configuration
├── variables.tf                 # Input variables
├── outputs.tf                   # Network outputs for other layers
├── locals.tf                    # Local calculations and logic
├── providers.tf                 # Terraform and provider configuration
└── environments/
    ├── dev/
    │   ├── backend.conf         # S3 backend configuration
    │   └── terraform.auto.tfvars# Dev environment network settings
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

## Environment Configurations

### 🌍 **CIDR Block Allocation**

| Environment | VPC CIDR      | Total IPs | Public Subnets | Private Subnets | Database Subnets |
|-------------|---------------|-----------|----------------|-----------------|------------------|
| **Dev**     | 10.10.0.0/16 | 65,536    | 10.10.1.0/24   | 10.10.10.0/24   | 10.10.50.0/24    |
| **QA**      | 10.20.0.0/16 | 65,536    | 10.20.1.0/24   | 10.20.10.0/24   | 10.20.50.0/24    |
| **UAT**     | 10.30.0.0/16 | 65,536    | 10.30.1.0/24   | 10.30.10.0/24   | 10.30.50.0/24    |
| **Prod**    | 10.40.0.0/16 | 65,536    | 10.40.1.0/24   | 10.40.10.0/24   | 10.40.50.0/24    |

### 🔧 **Multi-AZ Distribution**

Each environment deploys across multiple availability zones:
- **Minimum**: 2 AZs (Dev)
- **Standard**: 3 AZs (QA, UAT, Prod)
- **Automatic**: Uses `data.aws_availability_zones` for dynamic selection

## Modules Used

### **VPC Module**
```hcl
module "vpc" {
  source = "../../modules/vpc"
  
  name               = "${var.project_name}-${var.environment}"
  cidr               = var.vpc_cidr
  availability_zones = var.availability_zones
  
  # Subnet configurations
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets
  
  # Gateway configurations
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
  
  tags = local.common_tags
}
```

### **VPC Endpoints Module** (Optional)
```hcl
module "vpc_endpoints" {
  count  = var.enable_vpc_endpoints ? 1 : 0
  source = "../../modules/vpc-endpoints"
  
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets
  route_table_ids  = module.vpc.private_route_table_ids
  
  tags = local.common_tags
}
```

### **Transit Gateway Module** (Optional)
```hcl
module "transit_gateway" {
  count  = var.enable_transit_gateway ? 1 : 0
  source = "../../modules/transit-gateway"
  
  description                     = "${var.project_name}-${var.environment}-tgw"
  vpc_attachments = {
    vpc = {
      vpc_id     = module.vpc.vpc_id
      subnet_ids = module.vpc.private_subnets
    }
  }
  
  tags = local.common_tags
}
```

## Key Outputs

The networking layer exposes critical outputs for other layers:

```hcl
# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# Subnet Information
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets" 
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}
```

## Configuration Examples

### **Development Environment**
```hcl
# Minimal configuration for cost optimization
vpc_cidr = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

public_subnets   = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnets  = ["10.10.10.0/24", "10.10.20.0/24"]
database_subnets = ["10.10.50.0/24", "10.10.60.0/24"]

# Cost optimization
enable_nat_gateway = true
single_nat_gateway = true  # Single NAT for cost savings
enable_vpc_endpoints = false
```

### **Production Environment**
```hcl
# Full redundancy and security
vpc_cidr = "10.40.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnets   = ["10.40.1.0/24", "10.40.2.0/24", "10.40.3.0/24"]
private_subnets  = ["10.40.10.0/24", "10.40.20.0/24", "10.40.30.0/24"]
database_subnets = ["10.40.50.0/24", "10.40.60.0/24", "10.40.70.0/24"]

# High availability
enable_nat_gateway = true
single_nat_gateway = false  # NAT in each AZ
enable_vpc_endpoints = true  # Private AWS service access
enable_dns_hostnames = true
enable_dns_support = true
```

## Deployment

### **Prerequisites**
1. **Global Resources**: Deploy global layer first (if exists)
2. **AWS Permissions**: VPC and networking service permissions
3. **Region Selection**: Choose appropriate AWS region

### **Deployment Order**
```bash
# 1. Initialize Terraform
cd layers/networking/environments/dev
terraform init -backend-config=backend.conf

# 2. Plan the deployment
terraform plan -var-file=terraform.auto.tfvars

# 3. Apply changes
terraform apply -var-file=terraform.auto.tfvars
```

### **Using Makefile**
```bash
# Bootstrap networking for dev environment
make bootstrap ENVIRONMENT=dev LAYER=networking

# Deploy networking infrastructure
make deploy ENVIRONMENT=dev LAYER=networking

# Validate deployment
make validate ENVIRONMENT=dev LAYER=networking
```

## Dependencies

### **⬇️ Depends On:**
- **Global Layer**: May reference global KMS keys, IAM roles (optional)
- **AWS Account**: Properly configured AWS account with permissions

### **⬆️ Provides To:**
- **Security Layer**: VPC ID, subnet IDs for security group rules
- **Data Layer**: Database subnet group, VPC for RDS/ElastiCache
- **Compute Layer**: Subnets for EC2, EKS, ECS, ALB placement

## Security Considerations

### **🛡️ Network Security**
- **Private by Default**: Most resources in private subnets
- **Controlled Internet Access**: Public subnets only for necessary resources
- **Network ACLs**: Additional layer of subnet-level filtering
- **Flow Logs**: Network traffic monitoring and auditing

### **🔒 Best Practices**
1. **Least Privilege**: Minimal required network access
2. **Defense in Depth**: Multiple layers of network security
3. **Monitoring**: Enable VPC Flow Logs for traffic analysis
4. **Encryption**: Use VPC endpoints for encrypted AWS service communication

## Monitoring & Troubleshooting

### **📊 Monitoring**
- **VPC Flow Logs**: Network traffic analysis
- **CloudWatch Metrics**: NAT Gateway, Internet Gateway metrics
- **Route Table Monitoring**: Routing configuration validation

### **🔧 Common Issues**

#### **Connectivity Problems**
```bash
# Check route table associations
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx"

# Verify NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-xxxxx"

# Check subnet associations
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
```

#### **CIDR Conflicts**
- Ensure CIDR blocks don't overlap between environments
- Plan for future VPC peering or Transit Gateway connections
- Reserve address space for expansion

## Cost Optimization

### **💰 Cost Factors**
- **NAT Gateway**: Most expensive component (~$45/month per gateway)
- **Data Transfer**: Cross-AZ and internet transfer costs
- **VPC Endpoints**: Per hour and per GB costs

### **🎯 Optimization Strategies**
- **Single NAT Gateway**: Use in dev environments
- **VPC Endpoints**: Reduce data transfer costs for AWS services
- **Right-sizing**: Choose appropriate subnet sizes
- **Resource Cleanup**: Remove unused network resources

## Related Documentation

- [Main Project README](../../README.md)
- [Global Layer README](../../global/README.md)
- [Security Layer README](../security/README.md)
- [VPC Module Documentation](../../modules/vpc/README.md)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)

---

> 💡 **Next Steps**: After networking deployment, proceed with [Security Layer](../security/README.md) configuration.
