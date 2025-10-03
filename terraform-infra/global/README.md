# Global Terraform Configuration

## Overview

The `global` folder contains Terraform configurations for **account-wide shared resources** that are deployed once per AWS account and used across all environments and layers. These resources are foundational components that need to exist before any environment-specific infrastructure can be deployed.

## Purpose

The global configuration serves several critical purposes:

### 🏗️ **Foundation Infrastructure**
- Resources that are shared across all environments (dev, qa, uat, prod)
- Account-level configurations that don't belong to any specific environment
- Infrastructure that must exist before layer-specific resources can be deployed

### 🔒 **Security & Compliance**
- Account-wide security policies and configurations
- Cross-account IAM roles and policies
- Security baseline that applies to the entire AWS account

### 💰 **Cost Management**
- Centralized billing and cost allocation tags
- Account-wide cost controls and budgets
- Resource quotas and service limits

### 🔧 **Operational Excellence**
- Centralized logging and monitoring infrastructure
- Account-level CloudTrail configuration
- AWS Config rules for compliance monitoring

## What Goes in Global?

### ✅ **Should be in Global:**

#### **State Management Infrastructure**
- S3 buckets for Terraform state storage
- DynamoDB tables for state locking
- KMS keys for state encryption

#### **Account-Level IAM Resources**
- Cross-account roles
- Service-linked roles
- Account-wide policies
- OIDC providers for CI/CD integration

#### **Shared Networking Components**
- Route 53 hosted zones for the organization
- Cross-region VPC peering connections
- Transit Gateway (if used across regions)

#### **Security Foundations**
- AWS Config configuration recorder
- CloudTrail for account-level auditing
- GuardDuty detector (if account-wide)
- Security Hub configuration

#### **Compliance & Monitoring**
- AWS Organizations SCPs (if applicable)
- Account-wide CloudWatch log groups
- SNS topics for account-wide notifications

#### **Cost Management**
- AWS Budgets for account monitoring
- Cost anomaly detection
- Billing alerts and notifications

### ❌ **Should NOT be in Global:**

#### **Environment-Specific Resources**
- VPCs, subnets, route tables
- Application-specific resources
- Environment-specific security groups
- Load balancers and compute resources

#### **Layer-Specific Components**
- Database instances
- Application servers
- Caching layers
- Storage for specific applications

## Structure

```
global/
├── README.md                    # This documentation
├── main.tf                      # Main configuration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── locals.tf                    # Local calculations
├── providers.tf                 # Provider configuration
├── backend.conf                 # Backend configuration
└── terraform.auto.tfvars        # Variable values
```

## Deployment Strategy

### 🚀 **Deployment Order**
1. **Global resources** (this folder) - Deploy FIRST
2. **Networking layer** - Deploy second
3. **Security layer** - Deploy third
4. **Data layer** - Deploy fourth
5. **Compute layer** - Deploy last

### 🔄 **State Management**
Global resources often include the Terraform state storage infrastructure itself. This creates a "chicken and egg" problem that can be solved by:

1. **Manual Bootstrap**: Create S3 bucket and DynamoDB table manually first
2. **Local State**: Deploy global resources with local state, then migrate to remote state
3. **Separate Account**: Use a separate "management" account for state storage

## Example Use Cases

### 🏢 **Multi-Account Setup**
```hcl
# Cross-account IAM role for CI/CD
resource "aws_iam_role" "cicd_cross_account_role" {
  name = "cicd-cross-account-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.cicd_account_id}:root"
        }
      }
    ]
  })
}
```

### 🔐 **Shared State Infrastructure**
```hcl
# S3 bucket for Terraform state (all environments)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.organization}-terraform-state"
  
  tags = {
    Purpose = "Terraform State Storage"
    Global  = "true"
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.organization}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### 📊 **Account-Wide Monitoring**
```hcl
# CloudTrail for account-wide API logging
resource "aws_cloudtrail" "account_trail" {
  name           = "${var.organization}-account-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_log_file_validation   = true
}
```

## Best Practices

### 🎯 **Design Principles**
1. **Single Source of Truth**: Global resources should be the authoritative source for shared infrastructure
2. **Minimal Coupling**: Avoid tight coupling between global and environment-specific resources
3. **Change Management**: Global changes affect all environments - implement strict change control
4. **Documentation**: Document all global resources and their dependencies clearly

### 🛡️ **Security Considerations**
1. **Least Privilege**: Global IAM resources should follow least privilege principles
2. **MFA Requirements**: Consider requiring MFA for accessing global resources
3. **Audit Logging**: Ensure comprehensive logging of all global resource changes
4. **Encryption**: Encrypt all data at rest and in transit

### 🔧 **Operational Guidelines**
1. **Backup Strategy**: Implement robust backup strategies for global resources
2. **Disaster Recovery**: Plan for disaster recovery of global infrastructure
3. **Monitoring**: Set up comprehensive monitoring and alerting
4. **Access Control**: Implement strict access controls for global resource management

## Dependencies

### ⬆️ **Global Outputs Used By:**
- **Networking Layer**: May use global KMS keys, IAM roles
- **Security Layer**: Uses global IAM policies, audit configurations
- **Data Layer**: Uses global KMS keys, backup configurations
- **Compute Layer**: Uses global IAM roles, monitoring infrastructure

### ⬇️ **Global Depends On:**
- **AWS Account Setup**: Account must exist and be properly configured
- **Initial Permissions**: Sufficient permissions to create account-wide resources
- **Manual Bootstrap**: May require manual creation of initial state storage

## Common Patterns

### 🔑 **KMS Key Sharing**
```hcl
# Global KMS key for cross-environment encryption
resource "aws_kms_key" "global_encryption" {
  description = "Global encryption key for ${var.organization}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}

output "global_kms_key_id" {
  description = "Global KMS key ID for encryption"
  value       = aws_kms_key.global_encryption.key_id
}
```

### 📡 **SNS Topic for Notifications**
```hcl
# Global SNS topic for account-wide notifications
resource "aws_sns_topic" "account_notifications" {
  name = "${var.organization}-account-notifications"
  
  tags = {
    Purpose = "Account-wide notifications"
    Global  = "true"
  }
}
```

## Deployment Commands

### 🚀 **Initial Deployment**
```bash
# Navigate to global directory
cd terraform-infra/global

# Initialize Terraform (may use local backend initially)
terraform init

# Plan the deployment
terraform plan -var-file="terraform.auto.tfvars"

# Apply the changes
terraform apply -var-file="terraform.auto.tfvars"
```

### 🔄 **Using Makefile (if available)**
```bash
# Bootstrap global resources
make bootstrap ENVIRONMENT=global LAYER=global

# Deploy global resources
make deploy ENVIRONMENT=global LAYER=global
```

## Migration and Updates

### ⚡ **Zero-Downtime Updates**
When updating global resources:
1. Plan changes carefully - they affect all environments
2. Use blue-green deployment patterns where possible
3. Implement proper rollback procedures
4. Coordinate with all environment deployments

### 📋 **Change Management Process**
1. **Assessment**: Evaluate impact on all environments
2. **Testing**: Test changes in isolated environment first
3. **Communication**: Notify all stakeholders of planned changes
4. **Execution**: Deploy during maintenance windows
5. **Verification**: Verify all environments remain functional

## Troubleshooting

### ❗ **Common Issues**

#### **State Lock Conflicts**
```bash
# If state is locked, force unlock (use with caution)
terraform force-unlock LOCK_ID
```

#### **Permission Errors**
- Ensure AWS credentials have sufficient permissions
- Check if SCPs (Service Control Policies) are blocking actions
- Verify IAM policies allow required actions

#### **Resource Conflicts**
- Check for existing resources with same names
- Verify resource names follow organization naming conventions
- Ensure resources aren't managed by other tools

## Related Documentation

- [Main README](../README.md) - Overall project documentation
- [Layer Architecture](../README.md#architecture) - Understanding the layer approach
- [Environment Strategy](../README.md#environments) - Environment management
- [Security Guidelines](../README.md#security) - Security best practices

---

> 💡 **Remember**: Global resources are the foundation of your infrastructure. Changes here can impact all environments, so proceed with caution and proper planning.
