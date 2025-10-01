# AWS VPC Terraform Module

A comprehensive Terraform module for creating a secure, scalable, and cost-optimized Amazon Web Services (AWS) Virtual Private Cloud (VPC) following the AWS Well-Architected Framework principles.

## 🏗️ Architecture Overview

This module creates a production-ready VPC with the following components:

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS VPC                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Public AZ-A   │  │   Public AZ-B   │  │   Public AZ-C   │ │
│  │  10.0.1.0/24    │  │  10.0.2.0/24    │  │  10.0.3.0/24    │ │
│  │                 │  │                 │  │                 │ │
│  │  ┌─────────────┐│  │  ┌─────────────┐│  │  ┌─────────────┐│ │
│  │  │ NAT Gateway ││  │  │ NAT Gateway ││  │  │ NAT Gateway ││ │
│  │  └─────────────┘│  │  └─────────────┘│  │  └─────────────┘│ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                      │                      │       │
│           └──────────────────────┼──────────────────────┘       │
│                                  │                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Private AZ-A   │  │  Private AZ-B   │  │  Private AZ-C   │ │
│  │  10.0.11.0/24   │  │  10.0.12.0/24   │  │  10.0.13.0/24   │ │
│  │                 │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                  │                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Database AZ-A   │  │ Database AZ-B   │  │ Database AZ-C   │ │
│  │  10.0.21.0/24   │  │  10.0.22.0/24   │  │  10.0.23.0/24   │ │
│  │                 │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                  │
                        ┌─────────────────┐
                        │ Internet Gateway│
                        └─────────────────┘
                                  │
                            ┌─────────────┐
                            │  Internet   │
                            └─────────────┘
```

## 🎯 AWS Well-Architected Framework Alignment

This module implements the following Well-Architected pillars:

### 🔒 Security Pillar
- **Network Segmentation**: Separate public, private, and database tiers
- **Least Privilege**: Private subnets with no direct internet access
- **Defense in Depth**: Optional Network ACLs for subnet-level security
- **VPC Flow Logs**: Network traffic monitoring for security analysis
- **Default Security Group**: Managed with deny-all rules

### 🛡️ Reliability Pillar
- **Multi-AZ Design**: Resources deployed across multiple Availability Zones
- **Fault Tolerance**: Multiple NAT Gateways for high availability
- **Automated Recovery**: Self-healing NAT Gateways and route tables

### 🚀 Performance Efficiency Pillar
- **VPC Endpoints**: S3 and DynamoDB endpoints for improved performance
- **Optimal Routing**: Efficient routing between subnets and internet
- **Enhanced Networking**: Support for enhanced networking features

### 💰 Cost Optimization Pillar
- **Single NAT Gateway Option**: Cost-effective option for development environments
- **VPC Endpoints**: Reduce data transfer costs for AWS services
- **Right-Sizing**: Configurable subnet sizes and counts

### 🔧 Operational Excellence Pillar
- **Infrastructure as Code**: Fully defined in Terraform
- **Comprehensive Tagging**: Consistent resource tagging strategy
- **Monitoring**: VPC Flow Logs and CloudWatch integration
- **Documentation**: Comprehensive documentation and examples

## 🚀 Quick Start

### Basic Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  name_prefix = "my-app"
  cidr_block  = "10.0.0.0/16"

  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  common_tags = {
    Environment = "production"
    Project     = "my-application"
    Owner       = "platform-team"
  }
}
```

### Production Configuration

```hcl
module "production_vpc" {
  source = "./modules/vpc"

  name_prefix = "prod-myapp"
  cidr_block  = "10.0.0.0/16"

  # Multi-AZ setup for high availability
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  # High availability NAT Gateways
  enable_nat_gateway = true
  single_nat_gateway = false

  # Security features
  enable_flow_log                    = true
  flow_log_cloudwatch_log_group_name = "/aws/vpc/flowlogs"
  manage_default_security_group      = true
  create_network_acls               = true

  # Cost optimization
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # Enhanced tagging
  common_tags = {
    Environment             = "production"
    Project                = "my-application"
    Owner                  = "platform-team"
    "backup:required"      = "true"
    "compliance:required"  = "true"
  }

  vpc_tags = {
    "kubernetes.io/cluster/prod-cluster" = "shared"
  }
}
```

### Development Configuration

```hcl
module "development_vpc" {
  source = "./modules/vpc"

  name_prefix = "dev-myapp"
  cidr_block  = "10.1.0.0/16"

  # Minimal setup for development
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]

  # Cost-optimized NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true

  # Basic security
  manage_default_security_group = true

  common_tags = {
    Environment = "development"
    Project     = "my-application"
    Owner       = "dev-team"
  }
}
```

## 📋 Features

### Core Features
- ✅ **VPC Creation** with customizable CIDR blocks
- ✅ **Multi-AZ Public Subnets** with Internet Gateway routing
- ✅ **Multi-AZ Private Subnets** with NAT Gateway routing
- ✅ **Database Subnets** with DB Subnet Group creation
- ✅ **Internet Gateway** for public internet access
- ✅ **NAT Gateways** for private subnet outbound connectivity
- ✅ **Route Tables** with automatic associations

### Security Features
- ✅ **VPC Flow Logs** for network monitoring
- ✅ **Default Security Group** management (deny-all)
- ✅ **Network ACLs** for additional subnet-level security
- ✅ **DNS Resolution** with customizable settings

### Performance & Cost Optimization
- ✅ **VPC Endpoints** for S3 and DynamoDB
- ✅ **Single NAT Gateway** option for cost savings
- ✅ **IPv6 Support** (optional) for future-proofing
- ✅ **Enhanced Networking** support

### Operational Excellence
- ✅ **Comprehensive Tagging** with governance support
- ✅ **Multiple Environment** configurations
- ✅ **Validation Rules** for input parameters
- ✅ **Complete Output Values** for integration

## 📊 Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix for naming resources | `string` | n/a | yes |
| `cidr_block` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `public_subnets` | List of public subnet CIDR blocks | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| `private_subnets` | List of private subnet CIDR blocks | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]` | no |
| `database_subnets` | List of database subnet CIDR blocks | `list(string)` | `["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]` | no |
| `enable_nat_gateway` | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| `single_nat_gateway` | Use single NAT Gateway for all private subnets | `bool` | `false` | no |
| `enable_dns_hostnames` | Enable DNS hostnames in VPC | `bool` | `true` | no |
| `enable_dns_support` | Enable DNS support in VPC | `bool` | `true` | no |
| `map_public_ip_on_launch` | Auto-assign public IPs in public subnets | `bool` | `true` | no |
| `enable_flow_log` | Enable VPC Flow Logs | `bool` | `false` | no |
| `flow_log_traffic_type` | Type of traffic for Flow Logs | `string` | `"ALL"` | no |
| `manage_default_security_group` | Manage default security group | `bool` | `true` | no |
| `enable_s3_endpoint` | Enable VPC endpoint for S3 | `bool` | `true` | no |
| `enable_dynamodb_endpoint` | Enable VPC endpoint for DynamoDB | `bool` | `true` | no |
| `create_network_acls` | Create Network ACLs for subnets | `bool` | `false` | no |
| `common_tags` | Common tags for all resources | `map(string)` | `{}` | no |

<details>
<summary>📖 View All Variables</summary>

### Advanced Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `create_igw` | Create Internet Gateway | `bool` | `true` | no |
| `create_database_subnet_group` | Create DB subnet group | `bool` | `true` | no |
| `create_database_route_table` | Create separate database route table | `bool` | `true` | no |
| `flow_log_cloudwatch_log_group_name` | CloudWatch Log Group for Flow Logs | `string` | `null` | no |
| `flow_log_cloudwatch_iam_role_arn` | IAM role ARN for Flow Logs | `string` | `null` | no |
| `secondary_cidr_blocks` | Secondary CIDR blocks for VPC | `list(string)` | `[]` | no |
| `enable_ipv6` | Enable IPv6 support | `bool` | `false` | no |
| `assign_ipv6_address_on_creation` | Auto-assign IPv6 addresses | `bool` | `false` | no |
| `instance_tenancy` | Instance tenancy (default/dedicated) | `string` | `"default"` | no |

### Tagging Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_tags` | Additional tags for VPC | `map(string)` | `{}` | no |
| `public_subnet_tags` | Additional tags for public subnets | `map(string)` | `{"kubernetes.io/role/elb" = "1"}` | no |
| `private_subnet_tags` | Additional tags for private subnets | `map(string)` | `{"kubernetes.io/role/internal-elb" = "1"}` | no |
| `database_subnet_tags` | Additional tags for database subnets | `map(string)` | `{}` | no |
| `public_route_table_tags` | Additional tags for public route tables | `map(string)` | `{}` | no |
| `private_route_table_tags` | Additional tags for private route tables | `map(string)` | `{}` | no |
| `database_route_table_tags` | Additional tags for database route tables | `map(string)` | `{}` | no |

</details>

## 📤 Output Values

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_arn` | ARN of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `public_subnets` | IDs of public subnets |
| `private_subnets` | IDs of private subnets |
| `database_subnets` | IDs of database subnets |
| `database_subnet_group` | ID of database subnet group |
| `igw_id` | ID of the Internet Gateway |
| `nat_ids` | IDs of NAT Gateways |
| `nat_public_ips` | Public IPs of NAT Gateways |
| `public_route_table_ids` | IDs of public route tables |
| `private_route_table_ids` | IDs of private route tables |
| `vpc_endpoint_s3_id` | ID of S3 VPC endpoint |
| `vpc_endpoint_dynamodb_id` | ID of DynamoDB VPC endpoint |

<details>
<summary>📖 View All Outputs</summary>

### Complete Output Reference

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_arn` | ARN of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `vpc_instance_tenancy` | Tenancy of instances in VPC |
| `vpc_enable_dns_support` | DNS support status |
| `vpc_enable_dns_hostnames` | DNS hostnames status |
| `vpc_main_route_table_id` | ID of main route table |
| `vpc_default_network_acl_id` | ID of default network ACL |
| `vpc_default_security_group_id` | ID of default security group |
| `vpc_owner_id` | AWS account ID that owns VPC |
| `igw_id` | ID of Internet Gateway |
| `igw_arn` | ARN of Internet Gateway |
| `public_subnets` | List of public subnet IDs |
| `public_subnet_arns` | List of public subnet ARNs |
| `public_subnets_cidr_blocks` | List of public subnet CIDR blocks |
| `private_subnets` | List of private subnet IDs |
| `private_subnet_arns` | List of private subnet ARNs |
| `private_subnets_cidr_blocks` | List of private subnet CIDR blocks |
| `database_subnets` | List of database subnet IDs |
| `database_subnet_arns` | List of database subnet ARNs |
| `database_subnets_cidr_blocks` | List of database subnet CIDR blocks |
| `database_subnet_group` | ID of database subnet group |
| `database_subnet_group_name` | Name of database subnet group |
| `public_route_table_ids` | List of public route table IDs |
| `private_route_table_ids` | List of private route table IDs |
| `database_route_table_ids` | List of database route table IDs |
| `nat_ids` | List of NAT Gateway IDs |
| `nat_public_ips` | List of NAT Gateway public IPs |
| `natgw_ids` | List of NAT Gateway IDs (alias) |
| `vpc_endpoint_s3_id` | ID of S3 VPC endpoint |
| `vpc_endpoint_s3_prefix_list_id` | Prefix list ID of S3 endpoint |
| `vpc_endpoint_dynamodb_id` | ID of DynamoDB VPC endpoint |
| `vpc_endpoint_dynamodb_prefix_list_id` | Prefix list ID of DynamoDB endpoint |
| `public_network_acl_id` | ID of public network ACL |
| `private_network_acl_id` | ID of private network ACL |
| `database_network_acl_id` | ID of database network ACL |
| `azs` | List of availability zones |
| `name_prefix` | Name prefix used |
| `region` | AWS region |
| `vpc_flow_log_id` | ID of VPC Flow Log |

</details>

## 🏆 Best Practices

### Network Design
- **Use at least 2 Availability Zones** for high availability
- **Separate tiers** with public, private, and database subnets
- **Reserve IP space** for future expansion (don't use /24 if you might need /16)
- **Plan CIDR blocks** carefully to avoid overlaps with other VPCs or on-premises networks

### Security
- **Enable VPC Flow Logs** for security monitoring and troubleshooting
- **Use Network ACLs** for additional defense in depth (stateless firewall)
- **Manage default security group** to deny all traffic by default
- **Use VPC endpoints** to avoid data traversing the internet

### Cost Optimization
- **Use single NAT Gateway** for development environments
- **Enable VPC endpoints** for frequently used AWS services (S3, DynamoDB)
- **Right-size subnets** to avoid wasted IP addresses
- **Monitor NAT Gateway** data processing charges

### Operational Excellence
- **Use consistent tagging** for cost allocation and management
- **Document network architecture** and IP allocation strategy
- **Implement monitoring** with CloudWatch and VPC Flow Logs
- **Use Infrastructure as Code** for version control and reproducibility

## 🔍 Usage Examples

### Integration with Application Load Balancer

```hcl
# Create VPC
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix = "web-app"
  cidr_block  = "10.0.0.0/16"
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false
  
  common_tags = {
    Environment = "production"
    Application = "web-app"
  }
}

# Application Load Balancer in public subnets
resource "aws_lb" "web" {
  name               = "web-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.vpc.public_subnets

  tags = {
    Environment = "production"
  }
}
```

### Integration with RDS Database

```hcl
# Create VPC with database subnets
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix = "database-app"
  cidr_block  = "10.0.0.0/16"
  
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  
  create_database_subnet_group = true
  
  common_tags = {
    Environment = "production"
    Application = "database-app"
  }
}

# RDS instance using the database subnet group
resource "aws_db_instance" "main" {
  identifier = "main-database"
  
  engine         = "postgresql"
  engine_version = "14.9"
  instance_class = "db.t3.medium"
  
  allocated_storage = 20
  storage_type      = "gp3"
  
  db_name  = "myapp"
  username = "dbadmin"
  password = random_password.db_password.result
  
  db_subnet_group_name = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.database.id]
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"
  
  skip_final_snapshot = false
  final_snapshot_identifier = "main-database-final-snapshot"
  
  tags = {
    Environment = "production"
  }
}
```

### Integration with EKS Cluster

```hcl
# Create VPC optimized for Kubernetes
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix = "eks-cluster"
  cidr_block  = "10.0.0.0/16"
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false
  
  # EKS-specific tags
  public_subnet_tags = {
    "kubernetes.io/cluster/my-cluster" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }
  
  private_subnet_tags = {
    "kubernetes.io/cluster/my-cluster"     = "shared"
    "kubernetes.io/role/internal-elb"      = "1"
  }
  
  common_tags = {
    Environment = "production"
    Application = "kubernetes"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "my-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = concat(module.vpc.public_subnets, module.vpc.private_subnets)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}
```

## 🔧 Advanced Configuration

### Multi-Region Setup

```hcl
# Primary region VPC
module "vpc_primary" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.us_east_1
  }
  
  name_prefix = "primary"
  cidr_block  = "10.0.0.0/16"
  
  # Configuration...
}

# Secondary region VPC
module "vpc_secondary" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.us_west_2
  }
  
  name_prefix = "secondary" 
  cidr_block  = "10.1.0.0/16"  # Non-overlapping CIDR
  
  # Configuration...
}

# VPC Peering between regions
resource "aws_vpc_peering_connection" "cross_region" {
  provider = aws.us_east_1
  
  vpc_id      = module.vpc_primary.vpc_id
  peer_vpc_id = module.vpc_secondary.vpc_id
  peer_region = "us-west-2"
  
  tags = {
    Name = "primary-to-secondary"
  }
}
```

### IPv6 Configuration

```hcl
module "vpc_ipv6" {
  source = "./modules/vpc"
  
  name_prefix = "ipv6-enabled"
  cidr_block  = "10.0.0.0/16"
  
  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  
  common_tags = {
    Environment = "production"
    IPv6        = "enabled"
  }
}
```

## 🛠️ Troubleshooting

### Common Issues

1. **NAT Gateway Creation Fails**
   - Ensure Internet Gateway is created first
   - Check Elastic IP limits in your account
   - Verify public subnet exists for NAT Gateway placement

2. **Subnet CIDR Overlaps**
   - Use the built-in validation to check CIDR conflicts
   - Plan your network addressing scheme carefully
   - Use CIDR calculators for subnet planning

3. **Route Table Issues**
   - Check route table associations
   - Verify NAT Gateway and IGW routes
   - Ensure correct route priorities

### Debugging with Flow Logs

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  # ... other configuration ...
  
  enable_flow_log                    = true
  flow_log_traffic_type              = "ALL"
  flow_log_cloudwatch_log_group_name = "/aws/vpc/flowlogs"
}

# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30

  tags = {
    Environment = "production"
  }
}

# IAM role for Flow Logs
resource "aws_iam_role" "flow_logs" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 🔒 Security Considerations

### Network Security

1. **Default Security Group**: Always manage the default security group to remove permissive rules
2. **Network ACLs**: Use as an additional layer of security (defense in depth)
3. **VPC Flow Logs**: Enable for security monitoring and incident response
4. **Private Subnets**: Keep application and database tiers in private subnets

### Access Control

1. **IAM Policies**: Use least privilege principles for VPC management
2. **Resource Tagging**: Implement consistent tagging for access control
3. **VPC Endpoints**: Use to avoid data traversing the public internet

### Compliance

1. **Data Residency**: Ensure VPC is created in compliant regions
2. **Encryption**: Enable encryption for VPC Flow Logs
3. **Audit Trails**: Use AWS CloudTrail for API audit logging

## 📈 Performance Optimization

### Network Performance

1. **Enhanced Networking**: Enable for high-performance computing workloads
2. **Placement Groups**: Use cluster placement groups for low-latency applications
3. **Instance Types**: Choose network-optimized instances for bandwidth-intensive workloads

### Cost Optimization

1. **NAT Gateway**: Use single NAT Gateway for development environments
2. **VPC Endpoints**: Reduce data transfer costs for AWS service access
3. **Monitoring**: Use VPC Flow Log analysis for cost optimization insights

## 📚 Additional Resources

- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [VPC Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the established patterns
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

## 📄 License

This module is released under the MIT License. See LICENSE file for details.

---

## 📞 Support

For questions, issues, or contributions:
- Create an issue in the repository
- Review existing documentation
- Check AWS VPC documentation for service-specific questions

**Made with ❤️ by the Platform Team**