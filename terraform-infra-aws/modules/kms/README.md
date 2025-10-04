# AWS KMS Terraform Module

**Author:** Diego A. Zarate

This module creates and manages AWS Key Management Service (KMS) keys with comprehensive policy management, rotation, multi-region support, and grants. It follows AWS encryption best practices and provides both standard service keys and custom key configurations.

## Features

- **Customer Managed Keys** with automatic rotation and custom policies
- **Service-Specific Keys** for AWS services (S3, EBS, RDS, Lambda, etc.)
- **Multi-Region Keys** with replica key support
- **Key Grants** for fine-grained access control
- **External Keys** for Bring Your Own Key (BYOK) scenarios
- **Comprehensive Policies** with least privilege access
- **Key Aliases** for easy identification and management

## Security Architecture

### Encryption at Rest Strategy
```
Application Layer
       ↓
KMS Key Management
       ↓
Service Integration
       ↓
Data Protection
```

### Key Hierarchy
- **Root Keys**: Customer managed keys with full control
- **Service Keys**: Dedicated keys for each AWS service
- **Application Keys**: Custom keys for application-specific encryption
- **External Keys**: Customer-provided key material (BYOK)

## Usage

### Standard Service Keys (Recommended)

```hcl
module "kms" {
  source = "../../modules/kms"

  name_prefix = "myapp"
  
  # Create standard service keys automatically
  create_standard_keys = true

  tags = {
    Environment = "production"
    Project     = "my-application"
  }
}

# Usage in other resources
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.kms.service_key_ids["s3"]
      sse_algorithm     = "aws:kms"
    }
  }
}
```

### Custom Application Keys

```hcl
module "application_kms" {
  source = "../../modules/kms"

  name_prefix = "myapp"
  
  # Disable standard keys, use only custom keys
  create_standard_keys = false

  kms_keys = {
    application_data = {
      description         = "Encryption key for application data"
      enable_key_rotation = true
      rotation_period_in_days = 90
      
      # Define who can administer the key
      key_administrators = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KMSAdminRole"
      ]
      
      # Define who can use the key
      key_users = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ApplicationRole"
      ]
      
      # Allow specific AWS services
      service_principals = ["lambda", "s3"]
    }

    database_encryption = {
      description         = "Encryption key for database"
      enable_key_rotation = true
      
      key_administrators = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DBAdminRole"
      ]
      
      key_users = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ApplicationRole"
      ]
      
      service_principals = ["rds"]
      
      # Key grants for fine-grained access
      grants = {
        rds_grant = {
          grantee_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RDSRole"
          operations        = ["Decrypt", "DescribeKey"]
          constraints = {
            encryption_context_equals = {
              "aws:rds:db-cluster-id" = "my-cluster"
            }
          }
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "secure-application"
  }
}
```

### Multi-Region Keys for Global Applications

```hcl
module "global_kms" {
  source = "../../modules/kms"

  name_prefix = "global-app"

  kms_keys = {
    global_application = {
      description         = "Global encryption key for multi-region app"
      multi_region        = true
      enable_key_rotation = true
      
      # Replicate to other regions
      replica_regions = ["us-west-2", "eu-west-1", "ap-southeast-1"]
      
      key_administrators = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GlobalKMSAdmin"
      ]
      
      key_users = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GlobalAppRole"
      ]
      
      # Cross-account access for shared services
      external_accounts = ["123456789012", "987654321098"]
    }
  }

  tags = {
    Environment = "production"
    Scope       = "global"
  }
}
```

### Cross-Account Key Sharing

```hcl
module "shared_kms" {
  source = "../../modules/kms"

  name_prefix = "shared"

  kms_keys = {
    cross_account_logs = {
      description = "Shared key for cross-account logging"
      
      # Custom policy for complex access patterns
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "Enable IAM User Permissions"
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            }
            Action   = "kms:*"
            Resource = "*"
          },
          {
            Sid    = "Allow CloudTrail Service"
            Effect = "Allow"
            Principal = {
              Service = "cloudtrail.amazonaws.com"
            }
            Action = [
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            Resource = "*"
            Condition = {
              StringEquals = {
                "aws:SourceAccount" = [
                  data.aws_caller_identity.current.account_id,
                  "123456789012"  # Trusted account
                ]
              }
            }
          }
        ]
      })
    }
  }

  tags = {
    Environment = "shared"
    Purpose     = "cross-account"
  }
}
```

### External Keys (BYOK)

```hcl
module "byok_kms" {
  source = "../../modules/kms"

  name_prefix = "byok"

  # External keys for regulatory compliance
  external_keys = {
    compliance_key = {
      description             = "External key for regulatory compliance"
      key_material_base64     = var.external_key_material
      valid_to               = "2025-12-31T23:59:59Z"
      deletion_window_in_days = 7
      
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "Enable IAM User Permissions"
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            }
            Action   = "kms:*"
            Resource = "*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Compliance  = "required"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| aws.replica | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_kms_key | resource |
| aws_kms_alias | resource |
| aws_kms_grant | resource |
| aws_kms_replica_key | resource |
| aws_kms_external_key | resource |
| aws_iam_policy_document | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Name prefix for KMS resources | `string` | `"app"` | no |
| create_standard_keys | Create standard service keys | `bool` | `true` | no |
| kms_keys | Map of KMS keys to create | `map(object)` | `{}` | no |
| external_keys | Map of external KMS keys | `map(object)` | `{}` | no |
| tags | A map of tags to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_ids | Map of key names to their IDs |
| key_arns | Map of key names to their ARNs |
| alias_names | Map of key names to their alias names |
| service_key_ids | Map of AWS service names to key IDs |
| encryption_configuration | Encryption config for other modules |
| all_keys | Complete information about all keys |

## Best Practices

### Key Management
1. **Enable Rotation**: Always enable automatic key rotation
2. **Least Privilege**: Grant minimal required permissions
3. **Service Keys**: Use dedicated keys per AWS service
4. **Monitoring**: Enable CloudTrail for key usage monitoring
5. **Backup**: Document key policies and access patterns

### Security Guidelines
1. **Multi-Factor Authentication**: Require MFA for sensitive operations
2. **Cross-Account Access**: Use explicit account conditions
3. **Encryption Context**: Use encryption context for additional security
4. **Regular Audits**: Review key policies and access regularly
5. **Compliance**: Follow regulatory requirements for key management

### Operational Excellence
1. **Consistent Naming**: Use descriptive, consistent key names
2. **Comprehensive Tagging**: Tag all keys for management
3. **Documentation**: Document key purposes and access patterns
4. **Automation**: Automate key lifecycle management
5. **Disaster Recovery**: Plan for key recovery scenarios

## Security Considerations

### Access Control
- Implement least privilege access principles
- Use IAM policies and key policies together
- Regular access reviews and cleanup
- Monitor key usage patterns

### Encryption Context
- Use encryption context for additional security
- Implement context-based access controls
- Document context requirements
- Validate context in applications

### Multi-Region Strategy
- Plan for disaster recovery scenarios
- Understand cross-region replication
- Monitor replica key health
- Test failover procedures

## Compliance and Governance

### Regulatory Requirements
- FIPS 140-2 Level 2 validation
- GDPR encryption requirements
- PCI DSS key management
- SOC compliance standards

### Audit and Monitoring
- CloudTrail integration for all key operations
- CloudWatch metrics for key usage
- AWS Config rules for key compliance
- Regular security assessments

## Troubleshooting

### Common Issues
1. **Access Denied**: Check IAM and key policies
2. **Key Not Found**: Verify key exists and alias mapping
3. **Rotation Failures**: Check service permissions
4. **Cross-Region Issues**: Verify replica key configuration

### Debugging Commands
```bash
# List KMS keys
aws kms list-keys

# Describe key details
aws kms describe-key --key-id <key-id>

# Check key policy
aws kms get-key-policy --key-id <key-id> --policy-name default

# Test encryption/decryption
aws kms encrypt --key-id <key-id> --plaintext "test"
aws kms decrypt --ciphertext-blob <encrypted-data>
```

## Performance Considerations

### Request Limits
- KMS has API rate limits per region
- Plan for high-volume encryption operations
- Implement exponential backoff
- Use data keys for bulk encryption

### Cost Optimization
- Understand KMS pricing model
- Optimize key usage patterns
- Consider key consolidation where appropriate
- Monitor usage with CloudWatch

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Author

**Diego A. Zarate**  
Infrastructure Architect & AWS Solutions Architect

For questions or issues, please create an issue in the repository or contact the infrastructure team.