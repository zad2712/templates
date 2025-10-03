# Security Layer

## Overview

The **Security Layer** provides comprehensive security controls, identity and access management, encryption, and compliance frameworks for your AWS infrastructure. This layer builds upon the networking foundation to implement defense-in-depth security strategies across all environments.

## Purpose

The security layer establishes:
- **Identity & Access Management**: IAM roles, policies, and service accounts
- **Network Security**: Security groups, NACLs, and WAF configurations
- **Encryption & Key Management**: KMS keys and certificate management
- **Compliance & Auditing**: Security baseline and monitoring
- **Secrets Management**: Secure storage and rotation of sensitive data

## Architecture

### 🔒 **Core Security Components**

#### **Identity & Access Management (IAM)**
- **Service Roles**: For EC2, EKS, Lambda, and other AWS services
- **Cross-Account Roles**: For CI/CD and multi-account access
- **Instance Profiles**: EC2 and ECS task execution roles
- **OIDC Providers**: For GitHub Actions and external authentication

#### **Network Security**
- **Security Groups**: Application-level firewall rules
- **Network ACLs**: Subnet-level network filtering
- **WAF (Web Application Firewall)**: Protection for web applications
- **Shield**: DDoS protection for public-facing resources

#### **Encryption & Certificates**
- **KMS Keys**: Customer-managed encryption keys
- **ACM Certificates**: SSL/TLS certificates for HTTPS
- **Parameter Store**: Encrypted configuration storage
- **Secrets Manager**: Dynamic secrets with rotation

#### **Monitoring & Compliance**
- **CloudTrail**: API call logging and auditing
- **Config Rules**: Compliance and configuration monitoring
- **GuardDuty**: Threat detection and security monitoring
- **Security Hub**: Centralized security findings

## Layer Structure

```
security/
├── README.md                    # This documentation
├── main.tf                      # Main security configuration
├── variables.tf                 # Input variables
├── outputs.tf                   # Security outputs for other layers
├── locals.tf                    # Local security calculations
├── providers.tf                 # Terraform and provider configuration
└── environments/
    ├── dev/
    │   ├── backend.conf         # S3 backend configuration
    │   └── terraform.auto.tfvars# Dev security settings
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

## Modules Used

### **IAM Module**
```hcl
module "iam" {
  source = "../../modules/iam"
  
  # Service roles for different AWS services
  service_roles = var.service_roles
  
  # Cross-account access roles
  cross_account_roles = var.cross_account_roles
  
  # OIDC providers for CI/CD
  oidc_providers = var.oidc_providers
  
  tags = local.common_tags
}
```

### **Security Groups Module**
```hcl
module "security_groups" {
  source = "../../modules/security-groups"
  
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  
  # Security group configurations
  security_groups = var.security_groups
  
  tags = local.common_tags
}
```

### **KMS Module**
```hcl
module "kms" {
  source = "../../modules/kms"
  
  # KMS key configurations
  kms_keys = var.kms_keys
  
  # Cross-account access
  cross_account_access = var.kms_cross_account_access
  
  tags = local.common_tags
}
```

### **WAF Module** (Optional)
```hcl
module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "../../modules/waf"
  
  name = "${var.project_name}-${var.environment}-waf"
  
  # WAF rules and conditions
  waf_rules = var.waf_rules
  
  tags = local.common_tags
}
```

### **Secrets Manager Module**
```hcl
module "secrets_manager" {
  source = "../../modules/secrets-manager"
  
  # Secret configurations
  secrets = var.secrets
  
  # Automatic rotation settings
  enable_rotation = var.enable_secrets_rotation
  
  tags = local.common_tags
}
```

## Security Group Configurations

### 🛡️ **Standard Security Groups**

#### **ALB Security Group**
```hcl
alb = {
  description = "Security group for Application Load Balancer"
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access from internet"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access from internet"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [data.terraform_remote_state.networking.outputs.vpc_cidr_block]
      description = "Outbound to VPC"
    }
  ]
}
```

#### **EC2 Security Group**
```hcl
ec2 = {
  description = "Security group for EC2 instances"
  ingress_rules = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = "alb"
      description              = "HTTP from ALB"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [data.terraform_remote_state.networking.outputs.vpc_cidr_block]
      description = "SSH from VPC"
    }
  ]
}
```

#### **EKS Security Groups**
```hcl
eks_cluster = {
  description = "Security group for EKS cluster"
  ingress_rules = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = "eks_nodes"
      description              = "HTTPS from worker nodes"
    }
  ]
}

eks_nodes = {
  description = "Security group for EKS worker nodes"
  ingress_rules = [
    {
      from_port = 0
      to_port   = 65535
      protocol  = "tcp"
      self      = true
      description = "Node to node communication"
    },
    {
      from_port                = 1025
      to_port                  = 65535
      protocol                 = "tcp"
      source_security_group_id = "eks_cluster"
      description              = "Cluster to node communication"
    }
  ]
}
```

## IAM Role Configurations

### 👤 **Service Roles**

#### **EC2 Instance Role**
```hcl
ec2 = {
  service = "ec2.amazonaws.com"
  policies = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  inline_policies = {
    s3_access = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["${module.s3.bucket_arn}/*"]
    }
  }
}
```

#### **EKS Cluster Role**
```hcl
eks_cluster = {
  service = "eks.amazonaws.com"
  policies = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}

eks_node_group = {
  service = "ec2.amazonaws.com"
  policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}
```

#### **Lambda Execution Role**
```hcl
lambda = {
  service = "lambda.amazonaws.com"
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
}
```

## KMS Key Management

### 🔐 **Encryption Keys**

#### **General Purpose Key**
```hcl
general = {
  description = "General purpose KMS key for ${var.environment}"
  key_usage   = "ENCRYPT_DECRYPT"
  key_spec    = "SYMMETRIC_DEFAULT"
  
  # Key policy for cross-service access
  policy_statements = [
    {
      sid    = "EnableFullAccess"
      effect = "Allow"
      principals = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      actions   = ["kms:*"]
      resources = ["*"]
    }
  ]
}
```

#### **EBS Volume Encryption**
```hcl
ebs = {
  description = "KMS key for EBS volume encryption"
  key_usage   = "ENCRYPT_DECRYPT"
  
  # Allow EC2 service to use the key
  policy_statements = [
    {
      sid    = "AllowEC2Service"
      effect = "Allow"
      principals = {
        Service = "ec2.amazonaws.com"
      }
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ]
      resources = ["*"]
    }
  ]
}
```

## Environment-Specific Configurations

### 🌍 **Development Environment**
```hcl
# Relaxed security for development
enable_waf = false
enable_guardduty = false

# Basic security groups
security_groups = {
  alb = { /* basic ALB rules */ }
  ec2 = { /* basic EC2 rules */ }
}

# Minimal KMS keys
kms_keys = {
  general = { /* general purpose key */ }
}
```

### 🏭 **Production Environment**
```hcl
# Full security suite
enable_waf = true
enable_guardduty = true
enable_security_hub = true
enable_config = true

# Comprehensive security groups
security_groups = {
  alb         = { /* restrictive ALB rules */ }
  ec2         = { /* restrictive EC2 rules */ }
  rds         = { /* database security */ }
  eks_cluster = { /* EKS cluster security */ }
  eks_nodes   = { /* EKS node security */ }
}

# Multiple encryption keys
kms_keys = {
  general   = { /* general purpose */ }
  ebs       = { /* EBS encryption */ }
  rds       = { /* database encryption */ }
  s3        = { /* S3 encryption */ }
  secrets   = { /* secrets manager */ }
}
```

## Key Outputs

```hcl
# Security Group IDs
output "security_group_ids" {
  description = "Map of security group names to IDs"
  value       = module.security_groups.security_group_ids
}

# IAM Role Information
output "service_roles" {
  description = "Map of service roles"
  value = {
    for name, role in module.iam.service_roles : name => {
      arn                   = role.arn
      name                  = role.name
      instance_profile_name = role.instance_profile_name
    }
  }
}

# KMS Key Information
output "kms_key_ids" {
  description = "Map of KMS key names to key IDs"
  value       = module.kms.key_ids
}

output "kms_key_arns" {
  description = "Map of KMS key names to ARNs"
  value       = module.kms.key_arns
}
```

## Security Best Practices

### 🛡️ **Implementation Guidelines**

#### **Principle of Least Privilege**
- Grant minimum required permissions
- Use specific resource ARNs in policies
- Implement time-limited access where possible
- Regular access reviews and cleanup

#### **Defense in Depth**
- Multiple layers of security controls
- Network and application-level filtering
- Encryption at rest and in transit
- Comprehensive monitoring and alerting

#### **Secrets Management**
- Never store secrets in code or configuration
- Use AWS Secrets Manager for dynamic secrets
- Implement automatic rotation where possible
- Use IAM roles instead of access keys

#### **Monitoring and Auditing**
- Enable CloudTrail in all regions
- Implement real-time alerting for critical events
- Regular security assessments
- Compliance monitoring and reporting

## Compliance Frameworks

### 📋 **Supported Standards**

#### **SOC 2 Type II**
- Encryption controls
- Access management
- Monitoring and logging
- Change management

#### **PCI DSS** (when applicable)
- Network segmentation
- Encryption requirements
- Access controls
- Monitoring and testing

#### **GDPR** (for EU data)
- Data encryption
- Access logging
- Data retention policies
- Breach notification capabilities

## Deployment

### **Prerequisites**
1. **Networking Layer**: Must be deployed first
2. **AWS Permissions**: IAM and security service permissions
3. **Compliance Requirements**: Understand regulatory needs

### **Deployment Commands**
```bash
# Initialize and deploy security layer
cd layers/security/environments/prod
terraform init -backend-config=backend.conf
terraform plan -var-file=terraform.auto.tfvars
terraform apply -var-file=terraform.auto.tfvars
```

## Monitoring & Alerts

### 📊 **Security Monitoring**

#### **CloudWatch Alarms**
- Failed login attempts
- Unusual API activity
- Security group changes
- KMS key usage patterns

#### **GuardDuty Findings**
- Malicious IP activity
- Cryptocurrency mining
- Data exfiltration attempts
- Compromised credentials

#### **Config Rules**
- Security group compliance
- Encryption configuration
- IAM policy compliance
- Resource configuration drift

## Incident Response

### 🚨 **Security Incident Procedures**

#### **Immediate Response**
1. **Identify**: Determine scope and impact
2. **Contain**: Isolate affected resources
3. **Assess**: Evaluate damage and risk
4. **Communicate**: Notify stakeholders

#### **Recovery Steps**
1. **Remediate**: Fix vulnerabilities
2. **Restore**: Bring systems back online
3. **Monitor**: Enhanced monitoring post-incident
4. **Review**: Post-incident analysis and lessons learned

## Related Documentation

- [Main Project README](../../README.md)
- [Networking Layer README](../networking/README.md)
- [IAM Module Documentation](../../modules/iam/README.md)
- [Security Groups Module](../../modules/security-groups/README.md)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)

---

> 🔒 **Security First**: This layer provides the foundation for secure operations. Regular reviews and updates are essential for maintaining security posture.
