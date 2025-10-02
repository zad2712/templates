# VPC Terraform Module

## Overview

This Terraform module creates a comprehensive **Amazon Virtual Private Cloud (VPC)** with multi-tier network architecture following AWS best practices. The module provides a secure, scalable, and highly available network foundation for your AWS infrastructure.

## Features

### 🌐 **Core Network Components**
- **VPC with Custom CIDR**: Flexible IP address range configuration
- **Multi-Tier Subnets**: Public, private, and database subnet tiers
- **Multi-AZ Distribution**: High availability across multiple Availability Zones
- **Route Tables**: Optimized routing for different subnet tiers
- **Internet Gateway**: Public internet access for public subnets
- **NAT Gateways**: Secure outbound internet access for private subnets

### 🔒 **Security Features**
- **Network ACLs**: Subnet-level security controls
- **VPC Flow Logs**: Network traffic monitoring and security analysis
- **DNS Configuration**: Custom DNS resolution with AWS services
- **Security Group Ready**: Foundation for application-level security

### 📊 **Monitoring & Observability**
- **VPC Flow Logs**: Detailed network traffic analysis
- **CloudWatch Integration**: Metrics and monitoring capabilities
- **Cost Optimization**: Efficient NAT Gateway configuration options

## Architecture

### 🏗️ **Network Topology**

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Public Subnet │  │   Public Subnet │  │ Public Subnet│ │
│  │   10.0.1.0/24   │  │   10.0.2.0/24   │  │ 10.0.3.0/24  │ │
│  │   (AZ-1)        │  │   (AZ-2)        │  │  (AZ-3)      │ │
│  │                 │  │                 │  │              │ │
│  │  ┌─────────────┐│  │  ┌─────────────┐│  │ ┌───────────┐│ │
│  │  │ NAT Gateway ││  │  │ NAT Gateway ││  │ │NAT Gateway││ │
│  │  └─────────────┘│  │  └─────────────┘│  │ └───────────┘│ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│           │                      │                   │      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │  Private Subnet │  │  Private Subnet │  │Private Subnet│ │
│  │  10.0.11.0/24   │  │  10.0.12.0/24   │  │10.0.13.0/24  │ │
│  │   (AZ-1)        │  │   (AZ-2)        │  │  (AZ-3)      │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │Database Subnet  │  │Database Subnet  │  │Database Subnet│ │
│  │  10.0.21.0/24   │  │  10.0.22.0/24   │  │10.0.23.0/24  │ │
│  │   (AZ-1)        │  │   (AZ-2)        │  │  (AZ-3)      │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────────────┐
                    │ Internet Gateway│
                    └─────────────────┘
                              │
                        ◄─── Internet ───►
```

### 📋 **Subnet Tiers Explained**

#### **🌍 Public Subnets**
- **Purpose**: Resources that need direct internet access
- **Use Cases**: Load balancers, bastion hosts, NAT gateways
- **Routing**: Direct route to Internet Gateway
- **Security**: Public IP addresses, internet-accessible

#### **🔒 Private Subnets**
- **Purpose**: Application and compute resources
- **Use Cases**: EC2 instances, EKS nodes, application servers
- **Routing**: Internet access via NAT Gateway in same AZ
- **Security**: No direct internet access, outbound only

#### **🗄️ Database Subnets**
- **Purpose**: Database and storage resources
- **Use Cases**: RDS, ElastiCache, DynamoDB VPC endpoints
- **Routing**: No direct internet access
- **Security**: Isolated from internet, internal access only

## Usage Examples

### Basic VPC with Default Configuration

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  # Automatic AZ selection (first 3 available)
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  # NAT Gateway for private subnet internet access
  enable_nat_gateway = true
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Production VPC with Full Features

```hcl
module "production_vpc" {
  source = "../../modules/vpc"

  name = "prod-vpc"
  cidr = "10.0.0.0/16"

  # Explicit AZ specification
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Multi-tier subnet configuration
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  # High availability NAT Gateways (one per AZ)
  enable_nat_gateway     = true
  single_nat_gateway     = false  # One NAT Gateway per AZ
  one_nat_gateway_per_az = true

  # Security and monitoring
  enable_flow_logs = true
  flow_logs_retention_in_days = 30

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC endpoints for AWS services (cost optimization)
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  tags = {
    Environment = "production"
    Project     = "my-app"
    Backup      = "required"
    Compliance  = "SOC2"
  }
}
```

### Development VPC (Cost-Optimized)

```hcl
module "dev_vpc" {
  source = "../../modules/vpc"

  name = "dev-vpc"
  cidr = "10.1.0.0/16"

  # Smaller subnet configuration for development
  public_subnets   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]
  database_subnets = ["10.1.21.0/24", "10.1.22.0/24"]

  # Single NAT Gateway for cost optimization
  enable_nat_gateway = true
  single_nat_gateway = true

  # Minimal logging for development
  enable_flow_logs = false

  tags = {
    Environment = "development"
    Project     = "my-app"
    CostCenter  = "engineering"
  }
}
```

### Multi-Region VPC Setup

```hcl
# Primary region VPC
module "primary_vpc" {
  source = "../../modules/vpc"

  name = "primary-vpc"
  cidr = "10.0.0.0/16"

  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway = true
  enable_flow_logs   = true

  tags = {
    Environment = "production"
    Region      = "primary"
  }
}

# Secondary region VPC (different CIDR to avoid conflicts)
module "secondary_vpc" {
  source = "../../modules/vpc"
  
  providers = {
    aws = aws.secondary
  }

  name = "secondary-vpc"
  cidr = "10.1.0.0/16"  # Non-overlapping CIDR

  public_subnets   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnets  = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
  database_subnets = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

  enable_nat_gateway = true
  enable_flow_logs   = true

  tags = {
    Environment = "production"
    Region      = "secondary"
  }
}
```

## Configuration Options

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `name` | `string` | Name prefix for all resources |
| `cidr` | `string` | CIDR block for the VPC |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `availability_zones` | `list(string)` | `[]` | List of AZs (auto-detected if empty) |
| `public_subnets` | `list(string)` | `[]` | Public subnet CIDR blocks |
| `private_subnets` | `list(string)` | `[]` | Private subnet CIDR blocks |
| `database_subnets` | `list(string)` | `[]` | Database subnet CIDR blocks |
| `enable_nat_gateway` | `bool` | `true` | Enable NAT Gateways for private subnets |
| `single_nat_gateway` | `bool` | `false` | Use single NAT Gateway for all private subnets |
| `one_nat_gateway_per_az` | `bool` | `true` | Create one NAT Gateway per AZ |
| `enable_flow_logs` | `bool` | `false` | Enable VPC Flow Logs |
| `enable_dns_hostnames` | `bool` | `true` | Enable DNS hostnames in VPC |
| `enable_dns_support` | `bool` | `true` | Enable DNS support in VPC |

### VPC Endpoints Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_s3_endpoint` | `bool` | `false` | Create S3 VPC endpoint |
| `enable_dynamodb_endpoint` | `bool` | `false` | Create DynamoDB VPC endpoint |
| `enable_ec2_endpoint` | `bool` | `false` | Create EC2 VPC endpoint |
| `enable_rds_endpoint` | `bool` | `false` | Create RDS VPC endpoint |

## Outputs

### Network Information

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_arn` | ARN of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `internet_gateway_id` | ID of the Internet Gateway |

### Subnet Information

| Output | Description |
|--------|-------------|
| `public_subnets` | List of IDs of public subnets |
| `private_subnets` | List of IDs of private subnets |
| `database_subnets` | List of IDs of database subnets |
| `public_subnet_arns` | List of ARNs of public subnets |
| `private_subnet_arns` | List of ARNs of private subnets |

### Route Tables

| Output | Description |
|--------|-------------|
| `public_route_table_ids` | List of IDs of public route tables |
| `private_route_table_ids` | List of IDs of private route tables |
| `database_route_table_ids` | List of IDs of database route tables |

### NAT Gateway Information

| Output | Description |
|--------|-------------|
| `nat_gateway_ids` | List of IDs of NAT Gateways |
| `nat_public_ips` | List of public IP addresses of NAT Gateways |

## Best Practices

### 🔒 **Security Best Practices**

1. **Network Segmentation**
   - Use separate subnets for different tiers (web, app, database)
   - Implement security groups and NACLs for defense in depth
   - Use private subnets for application and database resources

2. **Access Control**
   - Minimize public subnet usage
   - Use bastion hosts or Systems Manager Session Manager for private access
   - Implement VPC endpoints to reduce internet traffic

3. **Monitoring & Logging**
   - Enable VPC Flow Logs for security analysis
   - Monitor NAT Gateway usage and costs
   - Set up CloudWatch alarms for unusual traffic patterns

### ⚡ **Performance Best Practices**

1. **Subnet Design**
   - Distribute resources across multiple AZs for high availability
   - Size subnets appropriately for expected growth
   - Use consistent subnet naming and tagging

2. **NAT Gateway Optimization**
   - Use one NAT Gateway per AZ for production workloads
   - Consider single NAT Gateway for development environments
   - Monitor data transfer costs

3. **DNS Configuration**
   - Enable DNS hostnames and support for AWS service integration
   - Consider Route 53 private hosted zones for internal DNS

### 💰 **Cost Optimization**

1. **NAT Gateway Strategy**
   - **Production**: One NAT Gateway per AZ for high availability
   - **Development**: Single NAT Gateway to reduce costs
   - **Testing**: Consider NAT instances for minimal workloads

2. **VPC Endpoints**
   - Implement VPC endpoints for frequently used AWS services
   - Reduce data transfer costs by keeping traffic within AWS
   - Monitor endpoint usage and costs

3. **Subnet Sizing**
   - Right-size subnets to avoid IP address waste
   - Plan for future growth but avoid over-provisioning
   - Use smaller subnets for development environments

## Integration Examples

### EKS Integration

```hcl
module "vpc" {
  source = "../../modules/vpc"
  
  name = "eks-vpc"
  cidr = "10.0.0.0/16"
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway = true
  
  # EKS-specific tags
  tags = {
    "kubernetes.io/cluster/my-cluster" = "shared"
  }
}

# EKS cluster using the VPC
module "eks" {
  source = "../../modules/eks"
  
  cluster_name = "my-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
}
```

### RDS Integration

```hcl
module "vpc" {
  source = "../../modules/vpc"
  
  # VPC configuration with database subnets
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

# RDS subnet group using database subnets
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = module.vpc.database_subnets
  
  tags = {
    Name = "Main DB subnet group"
  }
}
```

## Troubleshooting

### Common Issues

#### **Insufficient IP Addresses**
```bash
# Check subnet utilization
aws ec2 describe-subnets --subnet-ids subnet-xxx --query 'Subnets[0].AvailableIpAddressCount'

# Solution: Resize subnets or add additional subnets
```

#### **NAT Gateway Connectivity Issues**
```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways --nat-gateway-ids nat-xxx

# Check route table configuration
aws ec2 describe-route-tables --route-table-ids rtb-xxx
```

#### **DNS Resolution Problems**
```bash
# Verify DNS settings
aws ec2 describe-vpcs --vpc-ids vpc-xxx --query 'Vpcs[0].{DNS_Support:DnsSupport,DNS_Hostnames:DnsHostnames}'
```

### Monitoring Commands

```bash
# Monitor VPC Flow Logs
aws logs describe-log-groups --log-group-name-prefix "/aws/vpc/flowlogs"

# Check NAT Gateway metrics
aws cloudwatch get-metric-statistics --namespace AWS/NatGateway --metric-name BytesOutToDestination

# Verify subnet associations
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxx"
```

## Requirements

- **Terraform**: >= 1.6.0
- **AWS Provider**: ~> 5.70
- **Minimum Permissions**: VPC creation, subnet management, route table management

## Related Documentation

- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html)

---

> 🌐 **Network Foundation**: This VPC module provides the secure, scalable network foundation for your entire AWS infrastructure with enterprise-grade security and monitoring built-in.