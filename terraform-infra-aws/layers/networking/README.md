# AWS Networking Layer Documentation
# Author: Diego A. Zarate

This directory contains the Terraform configuration for the AWS networking infrastructure layer. This layer provides the foundational network components that other layers depend on.

## 🌐 Overview

The networking layer creates a complete VPC infrastructure following AWS best practices and the Well-Architected Framework principles:

### Core Components

- **VPC**: Virtual Private Cloud with DNS support and hostnames enabled
- **Subnets**: Public, private, database, management, and cache subnets across multiple AZs
- **Internet Gateway**: Provides internet access to public subnets
- **NAT Gateways**: Enable outbound internet access for private subnets
- **Route Tables**: Manage traffic routing between subnets and external networks
- **Security Groups**: Application-level firewall rules
- **Network ACLs**: Subnet-level network access control
- **VPC Endpoints**: Secure access to AWS services without internet routing
- **DHCP Options**: Custom DNS and domain settings

## 🏗️ Architecture

### Multi-AZ Design

The infrastructure spans multiple Availability Zones for high availability:

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.x.0.0/16)                   │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │     AZ-a    │  │     AZ-b    │  │        AZ-c         │ │
│  │             │  │             │  │                     │ │
│  │ Public      │  │ Public      │  │ Public              │ │
│  │ 10.x.1.0/24 │  │ 10.x.2.0/24 │  │ 10.x.3.0/24        │ │
│  │             │  │             │  │                     │ │
│  │ Private     │  │ Private     │  │ Private             │ │
│  │ 10.x.11.0/24│  │ 10.x.12.0/24│  │ 10.x.13.0/24       │ │
│  │             │  │             │  │                     │ │
│  │ Database    │  │ Database    │  │ Database            │ │
│  │ 10.x.21.0/24│  │ 10.x.22.0/24│  │ 10.x.23.0/24       │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Traffic Flow

1. **Internet → Public Subnets**: Through Internet Gateway
2. **Public → Private**: Through route tables and security groups
3. **Private → Internet**: Through NAT Gateways in public subnets
4. **Database**: Isolated with no direct internet access

## 📂 File Structure

```
networking/
├── README.md              # This documentation
├── locals.tf             # Local values and computed configurations
├── main.tf               # Primary networking resources
├── outputs.tf            # Output values for other layers
├── providers.tf          # AWS provider configuration
├── variables.tf          # Input variable definitions
└── environments/         # Environment-specific configurations
    ├── dev/
    │   ├── backend.conf
    │   └── terraform.auto.tfvars
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

## 🔧 Configuration

### Environment-Specific Settings

#### Development (dev)
- **CIDR**: 10.0.0.0/16
- **NAT Gateways**: Single (cost-optimized)
- **Monitoring**: Basic
- **Security**: Standard

#### Quality Assurance (qa)
- **CIDR**: 10.1.0.0/16
- **NAT Gateways**: Multiple (one per AZ)
- **Monitoring**: Enhanced
- **Security**: Enhanced with load testing support

#### User Acceptance Testing (uat)
- **CIDR**: 10.2.0.0/16
- **NAT Gateways**: Multiple (production-like)
- **Monitoring**: Enhanced
- **Security**: Production-like

#### Production (prod)
- **CIDR**: 10.3.0.0/16
- **NAT Gateways**: Multiple (high availability)
- **Monitoring**: Comprehensive
- **Security**: Maximum (WAF, GuardDuty, Security Hub)

### Security Groups

Pre-configured security groups for common use cases:

- **web**: HTTP/HTTPS traffic from internet
- **app**: Application traffic from VPC
- **database**: Database access from app subnets
- **load_balancer**: Load balancer traffic management
- **cache**: Redis/Memcached access
- **monitoring**: Prometheus/Grafana access
- **management**: SSH access from authorized networks

### Network ACLs

Layer 4 network access control:

- **Public**: Allow HTTP/HTTPS, deny SSH from internet
- **Private**: Allow all traffic from VPC
- **Database**: Restrict to database ports from app subnets

## 🚀 Deployment

### Prerequisites

1. **AWS Credentials**: Configured with appropriate permissions
2. **Terraform**: Version >= 1.9.0
3. **S3 Backend**: State storage bucket created
4. **DynamoDB**: State locking table created

### Deployment Steps

1. **Initialize Terraform:**
   ```bash
   cd environments/dev
   terraform init -backend-config=backend.conf
   ```

2. **Review and Plan:**
   ```bash
   terraform plan
   ```

3. **Deploy Infrastructure:**
   ```bash
   terraform apply
   ```

4. **Verify Outputs:**
   ```bash
   terraform output
   ```

### Using Management Scripts

```bash
# Initialize all environments
make init-all ENV=dev

# Deploy specific environment
make apply LAYER=networking ENV=dev

# Check status
make output LAYER=networking ENV=dev
```

## 📊 Outputs

This layer provides the following outputs for use by other layers:

### Core Infrastructure
- `vpc_id`: VPC identifier
- `public_subnets`: Public subnet IDs
- `private_subnets`: Private subnet IDs
- `database_subnets`: Database subnet IDs
- `security_group_ids`: Map of security group IDs

### Network Components
- `igw_id`: Internet Gateway ID
- `nat_ids`: NAT Gateway IDs
- `route_table_ids`: Route table IDs
- `database_subnet_group_name`: RDS subnet group

### Configuration Details
- `vpc_cidr_block`: VPC CIDR for reference
- `azs`: Availability zones used
- `network_summary`: Complete network overview

## 🔐 Security Features

### Defense in Depth

1. **Network Segmentation**: Separate subnets for different tiers
2. **Security Groups**: Application-level firewall rules
3. **Network ACLs**: Subnet-level access control
4. **VPC Endpoints**: Secure AWS service access
5. **Flow Logs**: Network traffic monitoring

### Encryption

- **In Transit**: All traffic uses TLS where possible
- **At Rest**: VPC Flow Logs encrypted in S3/CloudWatch
- **State**: Terraform state encrypted in S3

### Monitoring

- **VPC Flow Logs**: Capture all network traffic
- **CloudWatch**: Metrics and alarms
- **AWS Config**: Configuration compliance
- **GuardDuty**: Threat detection (production)

## 🚨 Troubleshooting

### Common Issues

#### Connectivity Problems

1. **Check Security Groups**: Ensure proper ingress/egress rules
2. **Verify Route Tables**: Confirm routes to IGW/NAT
3. **Network ACLs**: Check for restrictive rules
4. **DNS Resolution**: Verify DNS settings

#### NAT Gateway Issues

1. **Elastic IP Limits**: Check regional EIP limits
2. **Route Configuration**: Ensure proper routing to NAT
3. **Security Groups**: Allow outbound traffic

#### Subnet Issues

1. **CIDR Conflicts**: Ensure non-overlapping CIDRs
2. **AZ Availability**: Check AZ availability in region
3. **Subnet Sizing**: Ensure adequate IP addresses

### Diagnostic Commands

```bash
# Check VPC configuration
aws ec2 describe-vpcs --vpc-ids <vpc-id>

# Verify route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>"

# Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<vpc-id>"

# Monitor NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<vpc-id>"
```

## 📈 Monitoring and Alerting

### CloudWatch Metrics

- **NAT Gateway**: Bytes processed, packet count, errors
- **VPC Flow Logs**: Traffic analysis and anomaly detection
- **Network ACL**: Denied packets

### Recommended Alarms

1. **High NAT Gateway Usage**: > 80% of capacity
2. **Unusual Traffic Patterns**: Anomaly detection
3. **Security Group Violations**: Denied connections
4. **Network ACL Blocks**: Excessive blocked traffic

## 💰 Cost Optimization

### Development Environment

- Single NAT Gateway
- Reduced logging retention
- Basic monitoring

### Production Environment

- Multiple NAT Gateways for HA
- VPC Endpoints to reduce data transfer costs
- Reserved Capacity for predictable workloads

### Cost Monitoring

- Resource tagging for cost allocation
- CloudWatch cost anomaly detection
- Regular cost reviews and optimization

## 🔄 Maintenance

### Regular Tasks

1. **Security Group Audits**: Remove unused rules
2. **Network ACL Reviews**: Ensure proper restrictions
3. **Flow Log Analysis**: Monitor for suspicious activity
4. **Cost Reviews**: Optimize for cost efficiency

### Updates and Changes

1. **Test in Development**: Always test changes in dev first
2. **Use Terraform Plan**: Review changes before applying
3. **Backup State**: Ensure state backups are current
4. **Document Changes**: Update documentation

---

**Note**: This networking layer is the foundation for all other infrastructure layers. Changes should be carefully planned and tested to avoid disrupting dependent resources.