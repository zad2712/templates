# AWS Landing Zone Terraform Module

A comprehensive AWS Landing Zone module that implements industry best practices for secure, scalable, and well-architected AWS infrastructure. This module creates a foundational AWS environment following the AWS Well-Architected Framework principles.

## 🏗️ Architecture Overview

This landing zone creates a multi-tier architecture with the following components:

### Network Layer
- **VPC**: Isolated virtual private cloud with DNS support
- **Subnets**: Public, private, and database tiers across multiple availability zones
- **Internet Gateway**: Public internet access for web-facing resources
- **NAT Gateways**: Secure outbound internet access for private resources
- **Route Tables**: Proper traffic routing between tiers

### Security Layer
- **Security Groups**: Tier-based access controls (web, app, database, management)
- **Network ACLs**: Additional network-level security controls
- **IAM Roles**: Least-privilege access for EC2 instances and services
- **KMS Encryption**: Customer-managed encryption keys

### Monitoring & Compliance
- **CloudTrail**: API call logging and governance
- **VPC Flow Logs**: Network traffic monitoring
- **AWS Config**: Resource compliance monitoring
- **GuardDuty**: Threat detection and security monitoring
- **Security Hub**: Centralized security findings
- **CloudWatch**: Metrics and alerting

### Cost & Governance
- **Cost Anomaly Detection**: Proactive cost monitoring
- **Budgets**: Monthly spending alerts
- **AWS Backup**: Automated backup strategy
- **Resource Groups**: Organized resource management
- **Systems Manager**: Configuration parameter storage

## 📋 Features

- ✅ **Multi-AZ Architecture**: High availability across multiple availability zones
- ✅ **Tiered Security**: Web, application, and database security groups with NACLs
- ✅ **Comprehensive Monitoring**: CloudTrail, VPC Flow Logs, CloudWatch, and Config
- ✅ **Threat Detection**: GuardDuty and Security Hub integration
- ✅ **Cost Management**: Budgets, anomaly detection, and cost optimization
- ✅ **Backup Strategy**: Automated backup with AWS Backup service
- ✅ **Encryption**: KMS encryption for all supported services
- ✅ **Compliance**: Pre-configured for security best practices
- ✅ **Scalability**: Designed to support growth and additional services

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- An AWS account with admin access (for initial setup)

### Basic Usage

```hcl
module "aws_landing_zone" {
  source = "path/to/this/module"

  # Required Configuration
  environment       = "prod"
  organization_name = "acme"
  
  # Network Configuration
  vpc_cidr               = "10.0.0.0/16"
  private_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs    = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnet_cidrs  = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  
  # Security & Monitoring
  enable_cloudtrail = true
  enable_guardduty  = true
  enable_config     = true
  
  # Notifications
  sns_email_endpoints = ["admin@acme.com"]
  
  # Cost Management
  budget_limit = 1000
  cost_center  = "Infrastructure"
}
```

### Minimal Configuration (Development)

```hcl
module "aws_landing_zone_dev" {
  source = "path/to/this/module"

  environment       = "dev"
  organization_name = "acme"
  
  # Cost-optimized settings for development
  enable_nat_gateway  = false
  enable_guardduty    = false
  enable_backup_vault = false
}
```

## 📖 Examples

### Complete Production Setup

See `examples/complete/` for a full production-ready configuration with all features enabled.

### Minimal Development Setup

See `examples/minimal/` for a cost-optimized development environment.

## 📚 Module Documentation

### Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `environment` | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| `organization_name` | Name of the organization for resource naming | `string` | n/a | yes |
| `aws_region` | AWS region for resources | `string` | `"us-east-1"` | no |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `availability_zones` | List of availability zones | `list(string)` | `[]` | no |
| `private_subnet_cidrs` | CIDR blocks for private subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `list(string)` | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` | no |
| `database_subnet_cidrs` | CIDR blocks for database subnets | `list(string)` | `["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]` | no |
| `enable_nat_gateway` | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| `enable_vpn_gateway` | Enable VPN Gateway | `bool` | `false` | no |
| `enable_flow_logs` | Enable VPC Flow Logs | `bool` | `true` | no |
| `enable_cloudtrail` | Enable AWS CloudTrail | `bool` | `true` | no |
| `enable_config` | Enable AWS Config | `bool` | `true` | no |
| `enable_guardduty` | Enable Amazon GuardDuty | `bool` | `true` | no |
| `enable_security_hub` | Enable AWS Security Hub | `bool` | `true` | no |
| `enable_cloudwatch_alarms` | Enable CloudWatch alarms | `bool` | `true` | no |
| `enable_backup_vault` | Enable AWS Backup vault | `bool` | `true` | no |
| `sns_email_endpoints` | List of email addresses for SNS notifications | `list(string)` | `[]` | no |
| `budget_limit` | Monthly budget limit in USD | `number` | `100` | no |
| `cost_center` | Cost center tag for billing | `string` | `""` | no |
| `additional_tags` | Additional tags to apply to all resources | `map(string)` | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `private_subnet_ids` | List of IDs of the private subnets |
| `public_subnet_ids` | List of IDs of the public subnets |
| `database_subnet_ids` | List of IDs of the database subnets |
| `database_subnet_group_name` | Name of the database subnet group |
| `internet_gateway_id` | ID of the Internet Gateway |
| `nat_gateway_ids` | List of IDs of the NAT Gateways |
| `web_security_group_id` | ID of the web security group |
| `application_security_group_id` | ID of the application security group |
| `database_security_group_id` | ID of the database security group |
| `kms_key_id` | ID of the KMS key |
| `kms_key_arn` | ARN of the KMS key |
| `ec2_instance_profile_name` | Name of the EC2 instance profile |
| `cloudtrail_arn` | ARN of the CloudTrail |
| `backup_vault_name` | Name of the AWS Backup vault |

## 🔧 Deployment Guide

### Step 1: Configure Variables

Copy and customize the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
environment       = "prod"
organization_name = "yourcompany"
aws_region       = "us-west-2"

# Network settings
vpc_cidr = "10.0.0.0/16"

# Security settings  
enable_cloudtrail = true
enable_guardduty  = true

# Monitoring
sns_email_endpoints = ["admin@yourcompany.com"]

# Cost management
budget_limit = 5000
cost_center  = "platform-engineering"
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Plan Deployment

```bash
terraform plan
```

Review the planned resources carefully before proceeding.

### Step 4: Deploy Infrastructure

```bash
terraform apply
```

### Step 5: Verify Deployment

After successful deployment, verify the following:

1. **VPC and Subnets**: Check that all subnets are created in different AZs
2. **Security Groups**: Verify security group rules are correctly configured
3. **Monitoring**: Confirm CloudTrail, Flow Logs, and Config are active
4. **Backups**: Check that backup plan and vault are created
5. **Costs**: Monitor initial costs in AWS Cost Explorer

## 🛡️ Security Best Practices

This module implements several security best practices:

### Network Security
- **Defense in Depth**: Multiple security layers (SGs, NACLs, subnets)
- **Principle of Least Privilege**: Minimal required access only
- **Network Segmentation**: Separate tiers for web, app, and database

### Data Protection
- **Encryption at Rest**: KMS encryption for all supported services
- **Encryption in Transit**: HTTPS/TLS enforced where applicable
- **Backup Encryption**: Encrypted backups with customer-managed keys

### Monitoring & Compliance
- **Audit Logging**: CloudTrail for all API calls
- **Network Monitoring**: VPC Flow Logs for traffic analysis
- **Compliance Monitoring**: AWS Config for resource compliance
- **Threat Detection**: GuardDuty for security threats

### Access Control
- **IAM Best Practices**: Least privilege IAM roles and policies
- **Multi-Factor Authentication**: Recommended for all users
- **Access Logging**: All access attempts logged and monitored

## 💰 Cost Optimization

### Built-in Cost Controls
- **Budget Alerts**: Proactive budget monitoring
- **Cost Anomaly Detection**: Automated unusual spending alerts
- **Resource Tagging**: Comprehensive tagging for cost allocation
- **Right-sizing**: Optimized default configurations

### Cost Optimization Tips
1. **NAT Gateway**: Consider disabling in development environments
2. **Log Retention**: Adjust log retention periods based on compliance needs
3. **Backup Frequency**: Customize backup schedules for non-critical resources
4. **Monitoring**: Disable advanced monitoring features in dev/test environments

## 🔍 Monitoring & Alerting

### Built-in Monitoring
- **CloudWatch Metrics**: Infrastructure and application metrics
- **VPC Flow Logs**: Network traffic monitoring
- **CloudTrail**: API call auditing
- **Config Rules**: Resource compliance monitoring

### Alert Configuration
Configure SNS email endpoints to receive alerts for:
- Budget threshold exceeded
- Security findings from GuardDuty
- Cost anomalies detected
- Infrastructure issues

### Dashboard Access
After deployment, access monitoring through:
- **CloudWatch Dashboards**: Infrastructure metrics
- **Security Hub**: Security findings and compliance
- **Cost Explorer**: Spending analysis and trends

## 🔧 Customization

### Adding Custom Resources

To extend the landing zone with additional resources:

1. Create new `.tf` files in your root module
2. Reference landing zone outputs as needed
3. Apply consistent tagging strategy

Example:
```hcl
# Add an Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "${var.organization_name}-${var.environment}-alb"
  load_balancer_type = "application"
  security_groups    = [module.aws_landing_zone.web_security_group_id]
  subnets           = module.aws_landing_zone.public_subnet_ids
  
  tags = module.aws_landing_zone.common_tags
}
```

### Environment-Specific Configurations

Use different variable files for different environments:

```bash
# Development
terraform apply -var-file="environments/dev.tfvars"

# Staging  
terraform apply -var-file="environments/staging.tfvars"

# Production
terraform apply -var-file="environments/prod.tfvars"
```

## 📋 Compliance & Standards

This module helps achieve compliance with various frameworks:

### AWS Well-Architected Framework
- **Security Pillar**: Multi-layered security controls
- **Reliability Pillar**: Multi-AZ deployment and backups
- **Performance Pillar**: Optimized network architecture
- **Cost Optimization**: Built-in cost monitoring and controls
- **Operational Excellence**: Comprehensive monitoring and logging

### Industry Standards
- **SOC 2**: Audit trails and access controls
- **PCI DSS**: Network segmentation and monitoring
- **HIPAA**: Encryption and access logging
- **ISO 27001**: Security controls and monitoring

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

## 📄 License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for full details.

## 🆘 Support

### Getting Help

1. **Documentation**: Check this README and inline code comments
2. **Examples**: Review the examples in the `examples/` directory
3. **Issues**: Create an issue in the repository for bugs or questions
4. **AWS Support**: For AWS-specific issues, consult AWS documentation

### Common Issues

#### Issue: "Insufficient permissions" during deployment
**Solution**: Ensure your AWS credentials have the necessary permissions. For initial deployment, admin access is recommended.

#### Issue: "Availability zone not supported" 
**Solution**: Some regions have limited availability zones. Adjust the `availability_zones` variable or use fewer subnets.

#### Issue: High costs in development
**Solution**: Use the minimal example configuration and disable expensive features like NAT Gateway and GuardDuty in development environments.

### Troubleshooting

#### Terraform State Issues
```bash
# Refresh state
terraform refresh

# Import existing resources if needed  
terraform import aws_vpc.main vpc-xxxxxxxxx
```

#### Network Connectivity Issues
1. Check security group rules
2. Verify route table configurations
3. Confirm NAT Gateway status
4. Review VPC Flow Logs

---

## 📊 Resource Overview

This module creates approximately **50-80 resources** depending on configuration:

- **Networking**: 15-20 resources (VPC, subnets, gateways, route tables)
- **Security**: 15-25 resources (security groups, NACLs, IAM roles)
- **Monitoring**: 10-15 resources (CloudWatch, CloudTrail, Config)
- **Storage**: 5-10 resources (S3 buckets, KMS keys)
- **Governance**: 5-10 resources (backup, cost management)

Total estimated monthly cost for a production deployment: **$150-500** depending on data transfer and storage usage.

---

**Built with ❤️ for the AWS community**

For questions, issues, or contributions, please visit our [GitHub repository](https://github.com/your-org/aws-landing-zone-terraform).