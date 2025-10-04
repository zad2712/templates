# S3 Module

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)

## Overview

This Terraform module creates and manages Amazon S3 (Simple Storage Service) buckets with comprehensive configuration options following AWS best practices and security guidelines. The module supports multiple bucket types, advanced security configurations, lifecycle management, encryption, logging, notifications, CORS, website hosting, and cross-region replication.

## Features

- **Multiple Bucket Types**: Support for application, logging, static website, backup, and data lake buckets
- **Security First**: Comprehensive security configurations with public access blocks and encryption
- **Versioning**: Object versioning with MFA delete protection
- **Encryption**: Server-side encryption with KMS or S3-managed keys
- **Lifecycle Management**: Automated lifecycle rules for cost optimization
- **Access Control**: Flexible bucket policies and IAM integration
- **Logging**: Access logging and CloudTrail integration
- **Notifications**: Lambda, SNS, and SQS event notifications
- **CORS Configuration**: Cross-origin resource sharing support
- **Website Hosting**: Static website hosting configuration
- **Replication**: Cross-region and same-region replication
- **Monitoring**: CloudWatch metrics and alarms integration
- **Compliance**: Support for compliance requirements (PCI DSS, HIPAA, etc.)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           S3 Module                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Application   │  │     Logging     │  │      Backup     │  │
│  │     Buckets     │  │     Buckets     │  │     Buckets     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │ Static Website  │  │   Data Lake     │                      │
│  │     Buckets     │  │     Buckets     │                      │
│  └─────────────────┘  └─────────────────┘                      │
├─────────────────────────────────────────────────────────────────┤
│                      Security Features                          │
│  • KMS/S3 Encryption    • Public Access Blocks                 │
│  • Bucket Policies      • IAM Integration                       │
│  • MFA Delete           • Access Logging                        │
├─────────────────────────────────────────────────────────────────┤
│                   Advanced Features                             │
│  • Lifecycle Rules      • Cross-Region Replication             │
│  • Event Notifications  • CORS Configuration                    │
│  • Website Hosting      • Intelligent Tiering                   │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example

```hcl
module "s3_buckets" {
  source = "./modules/s3"

  name_prefix = "myapp"
  
  s3_buckets = {
    "application-data" = {
      bucket_type        = "application"
      versioning_enabled = true
      encryption = {
        sse_algorithm = "aws:kms"
      }
      lifecycle_rules = [
        {
          id     = "delete_old_versions"
          status = "Enabled"
          noncurrent_version_expiration = {
            noncurrent_days = 90
          }
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-application"
    Owner       = "platform-team"
  }
}
```

### Advanced Example with Multiple Bucket Types

```hcl
module "s3_comprehensive" {
  source = "./modules/s3"

  name_prefix = "enterprise"
  
  s3_buckets = {
    # Application Data Bucket
    "app-data" = {
      bucket_type        = "application"
      versioning_enabled = true
      encryption = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms.key_arns["s3"]
      }
      
      lifecycle_rules = [
        {
          id     = "transition_to_ia"
          status = "Enabled"
          transitions = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            },
            {
              days          = 90
              storage_class = "GLACIER"
            },
            {
              days          = 365
              storage_class = "DEEP_ARCHIVE"
            }
          ]
        }
      ]
      
      notifications = {
        lambda_functions = [
          {
            lambda_function_arn = aws_lambda_function.processor.arn
            events             = ["s3:ObjectCreated:*"]
            filter_suffix      = ".json"
          }
        ]
      }
      
      replication = {
        role_arn = aws_iam_role.replication.arn
        rules = [
          {
            id       = "replicate_all"
            status   = "Enabled"
            destination = {
              bucket             = "enterprise-app-data-backup"
              storage_class      = "STANDARD_IA"
              replica_kms_key_id = module.kms.key_arns["s3"]
            }
          }
        ]
      }
    }
    
    # Static Website Bucket
    "static-website" = {
      bucket_type = "static-website"
      
      public_access_block = {
        block_public_acls       = false
        block_public_policy     = false
        ignore_public_acls      = false
        restrict_public_buckets = false
      }
      
      website = {
        index_document = "index.html"
        error_document = "error.html"
      }
      
      cors_rules = [
        {
          allowed_methods = ["GET", "HEAD"]
          allowed_origins = ["*"]
          allowed_headers = ["*"]
          max_age_seconds = 3000
        }
      ]
    }
    
    # Logging Bucket
    "access-logs" = {
      bucket_type = "logging"
      lifecycle_rules = [
        {
          id     = "delete_old_logs"
          status = "Enabled"
          expiration = {
            days = 90
          }
        }
      ]
    }
    
    # Data Lake Bucket
    "data-lake" = {
      bucket_type = "data-lake"
      encryption = {
        sse_algorithm = "aws:kms"
      }
      
      lifecycle_rules = [
        {
          id     = "intelligent_tiering"
          status = "Enabled"
          transitions = [
            {
              days          = 0
              storage_class = "INTELLIGENT_TIERING"
            }
          ]
        }
      ]
    }
  }

  tags = {
    Environment   = "production"
    Project       = "enterprise-app"
    CostCenter    = "engineering"
    Compliance    = "required"
    DataClass     = "confidential"
  }
}
```

### S3 with CloudFront Distribution

```hcl
module "s3_cdn" {
  source = "./modules/s3"

  name_prefix = "cdn"
  
  s3_buckets = {
    "static-assets" = {
      bucket_type = "static-website"
      
      # Block public access but allow CloudFront
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      
      bucket_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "AllowCloudFrontAccess"
            Effect    = "Allow"
            Principal = {
              AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
            }
            Action   = "s3:GetObject"
            Resource = "arn:aws:s3:::cdn-static-assets/*"
          }
        ]
      })
      
      cors_rules = [
        {
          allowed_methods = ["GET", "HEAD", "OPTIONS"]
          allowed_origins = ["https://example.com"]
          allowed_headers = ["*"]
          expose_headers  = ["ETag"]
          max_age_seconds = 86400
        }
      ]
    }
  }
}
```

### Backup and Disaster Recovery

```hcl
module "s3_backup" {
  source = "./modules/s3"

  name_prefix = "backup"
  
  s3_buckets = {
    "database-backups" = {
      bucket_type = "backup"
      
      versioning_enabled = true
      mfa_delete        = true
      
      encryption = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms.key_arns["backup"]
      }
      
      lifecycle_rules = [
        {
          id     = "backup_lifecycle"
          status = "Enabled"
          transitions = [
            {
              days          = 1
              storage_class = "STANDARD_IA"
            },
            {
              days          = 30
              storage_class = "GLACIER"
            },
            {
              days          = 90
              storage_class = "DEEP_ARCHIVE"
            }
          ]
          expiration = {
            days = 2555  # 7 years
          }
        }
      ]
      
      notifications = {
        sns_topics = [
          {
            topic_arn = aws_sns_topic.backup_alerts.arn
            events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
          }
        ]
      }
    }
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Name prefix for S3 resources | `string` | `"app"` | no |
| tags | A map of tags to assign to S3 resources | `map(string)` | `{}` | no |
| s3_buckets | Map of S3 buckets to create | `map(object)` | `{}` | no |

### S3 Bucket Configuration Options

Each S3 bucket in the `s3_buckets` map supports the following configuration options:

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `bucket_type` | Type of bucket (application, logging, static-website, backup, data-lake) | `string` | `"application"` |
| `force_destroy` | Allow destruction of non-empty bucket | `bool` | `false` |
| `versioning_enabled` | Enable object versioning | `bool` | `true` |
| `mfa_delete` | Enable MFA delete for versioned objects | `bool` | `false` |
| `encryption` | Server-side encryption configuration | `object` | KMS encryption |
| `public_access_block` | Public access block configuration | `object` | All blocks enabled |
| `lifecycle_rules` | Object lifecycle management rules | `list(object)` | `[]` |
| `bucket_policy` | Custom bucket policy JSON | `string` | `null` |
| `logging` | Access logging configuration | `object` | `null` |
| `notifications` | Event notification configuration | `object` | `null` |
| `cors_rules` | CORS configuration rules | `list(object)` | `null` |
| `website` | Static website hosting configuration | `object` | `null` |
| `replication` | Cross-region replication configuration | `object` | `null` |

## Outputs

| Name | Description |
|------|-------------|
| s3_buckets | Map of S3 bucket information |
| bucket_arns | ARNs of the created S3 buckets |
| bucket_ids | IDs of the created S3 buckets |
| bucket_domain_names | Domain names of the created S3 buckets |
| bucket_regional_domain_names | Regional domain names of the created S3 buckets |
| bucket_policies | Map of S3 bucket policies |
| bucket_versioning_configurations | Map of S3 bucket versioning configurations |
| bucket_encryption_configurations | Map of S3 bucket encryption configurations |
| application_buckets | List of application buckets |
| logging_buckets | List of logging buckets |
| static_website_buckets | List of static website buckets |
| backup_buckets | List of backup buckets |
| data_lake_buckets | List of data lake buckets |
| bucket_count | Total number of S3 buckets created |

## Bucket Types

### Application Buckets
- Default encryption enabled
- Versioning enabled
- Public access blocked
- Lifecycle rules for cost optimization

### Logging Buckets
- Optimized for log storage
- Lifecycle rules for log retention
- Access logging disabled (to prevent loops)

### Static Website Buckets
- Website hosting configuration
- CORS support
- Optional public access
- CloudFront integration ready

### Backup Buckets
- Long-term retention policies
- Transition to cheaper storage classes
- Optional cross-region replication
- Enhanced security settings

### Data Lake Buckets
- Intelligent tiering enabled
- Optimized for analytics workloads
- Lifecycle rules for data archival
- Integration with AWS analytics services

## Security Best Practices

### 1. Encryption
- **Default**: All buckets use KMS encryption by default
- **Options**: Support for S3-managed (SSE-S3) and customer-managed keys (SSE-KMS)
- **Transit**: All data in transit is encrypted using HTTPS/TLS

### 2. Access Control
- **Public Access**: Blocked by default on all buckets
- **IAM Integration**: Supports IAM roles and policies
- **Bucket Policies**: Granular access control with JSON policies
- **MFA Delete**: Optional multi-factor authentication for object deletion

### 3. Monitoring and Auditing
- **CloudTrail**: Integration with AWS CloudTrail for API logging
- **Access Logging**: Server access logging to dedicated logging buckets
- **CloudWatch**: Metrics and alarms for monitoring bucket activity

### 4. Data Protection
- **Versioning**: Object versioning to protect against accidental deletion
- **Replication**: Cross-region replication for disaster recovery
- **Lifecycle**: Automated lifecycle rules to manage object storage classes

## Cost Optimization

### Storage Classes
The module supports automatic transition between storage classes:

1. **Standard**: Default for frequently accessed data
2. **Standard-IA**: Infrequently accessed data (>30 days)
3. **Intelligent Tiering**: Automatic optimization based on access patterns
4. **Glacier**: Long-term archival (>90 days)
5. **Deep Archive**: Lowest cost for rarely accessed data (>365 days)

### Lifecycle Policies
```hcl
lifecycle_rules = [
  {
    id     = "cost_optimization"
    status = "Enabled"
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      },
      {
        days          = 365
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    expiration = {
      days = 2555  # 7 years retention
    }
  }
]
```

## Compliance and Governance

### Regulatory Compliance
- **HIPAA**: Encryption at rest and in transit, access logging
- **PCI DSS**: Secure access controls and encryption
- **SOC 2**: Comprehensive logging and monitoring
- **GDPR**: Data retention and deletion policies

### Tagging Strategy
```hcl
tags = {
  Environment     = "production"
  Project         = "my-app"
  Owner          = "platform-team"
  CostCenter     = "engineering"
  DataClass      = "confidential"
  Compliance     = "required"
  BackupRequired = "true"
  RetentionDays  = "2555"
}
```

## Integration Examples

### Lambda Function Triggers

```hcl
notifications = {
  lambda_functions = [
    {
      lambda_function_arn = aws_lambda_function.image_processor.arn
      events             = ["s3:ObjectCreated:*"]
      filter_prefix      = "images/"
      filter_suffix      = ".jpg"
    }
  ]
}
```

### CloudFront Distribution

```hcl
# S3 bucket for static assets
module "static_assets" {
  source = "./modules/s3"
  
  s3_buckets = {
    "cdn-assets" = {
      bucket_type = "static-website"
      
      bucket_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
            }
            Action   = "s3:GetObject"
            Resource = "${module.static_assets.bucket_arns["cdn-assets"]}/*"
          }
        ]
      })
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = module.static_assets.bucket_regional_domain_names["cdn-assets"]
    origin_id   = "S3-${module.static_assets.bucket_ids["cdn-assets"]}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  # ... rest of CloudFront configuration
}
```

### Cross-Region Replication

```hcl
# Primary bucket
module "primary_bucket" {
  source = "./modules/s3"
  
  s3_buckets = {
    "primary-data" = {
      replication = {
        role_arn = aws_iam_role.replication.arn
        rules = [
          {
            id     = "replicate_all"
            status = "Enabled"
            destination = {
              bucket             = module.backup_bucket.bucket_arns["backup-data"]
              storage_class      = "STANDARD_IA"
              replica_kms_key_id = module.kms.key_arns["s3"]
            }
          }
        ]
      }
    }
  }
}

# Backup bucket (different region)
module "backup_bucket" {
  source = "./modules/s3"
  
  providers = {
    aws = aws.backup_region
  }
  
  s3_buckets = {
    "backup-data" = {
      bucket_type = "backup"
    }
  }
}
```

## Monitoring and Alerting

### CloudWatch Metrics
The module automatically enables the following CloudWatch metrics:
- **BucketSizeBytes**: Total size of objects in bucket
- **NumberOfObjects**: Number of objects in bucket
- **AllRequests**: Total number of requests
- **GetRequests**: Number of GET requests
- **PutRequests**: Number of PUT requests

### CloudWatch Alarms Example

```hcl
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  alarm_name          = "s3-bucket-size-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"  # Daily
  statistic           = "Average"
  threshold           = "1000000000000"  # 1TB
  alarm_description   = "This metric monitors S3 bucket size"
  
  dimensions = {
    BucketName  = module.s3_buckets.bucket_ids[each.key]
    StorageType = "StandardStorage"
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Troubleshooting

### Common Issues

#### 1. Bucket Name Already Exists
```
Error: BucketAlreadyExists: The requested bucket name is not available
```
**Solution**: S3 bucket names must be globally unique. Modify the `name_prefix` or bucket name.

#### 2. Access Denied Errors
```
Error: AccessDenied: Access Denied
```
**Solutions**:
- Check IAM permissions for the Terraform execution role
- Verify bucket policies don't conflict with public access blocks
- Ensure MFA requirements are met if MFA delete is enabled

#### 3. Replication Configuration Errors
```
Error: InvalidRequest: Replication configuration is not valid
```
**Solutions**:
- Verify the replication role has proper permissions
- Ensure destination bucket exists and is in a different region
- Check that versioning is enabled on both source and destination buckets

#### 4. CORS Configuration Issues
```
Error: The CORS configuration must be valid
```
**Solutions**:
- Verify allowed methods are valid HTTP methods
- Check that origins use proper format (https://example.com)
- Ensure max_age_seconds is within valid range (0-3600)

### Debugging Commands

```bash
# Check bucket configuration
aws s3api get-bucket-location --bucket bucket-name

# Verify bucket policy
aws s3api get-bucket-policy --bucket bucket-name

# Check public access block
aws s3api get-public-access-block --bucket bucket-name

# Verify encryption configuration
aws s3api get-bucket-encryption --bucket bucket-name

# Check lifecycle configuration
aws s3api get-bucket-lifecycle-configuration --bucket bucket-name

# Verify replication configuration
aws s3api get-bucket-replication --bucket bucket-name
```

### Performance Optimization

#### 1. Request Rate Optimization
- Use appropriate prefixes for high request rates
- Implement exponential backoff for retries
- Consider using Transfer Acceleration for global uploads

#### 2. Large Object Handling
- Use multipart uploads for objects > 100MB
- Enable Transfer Acceleration for large file uploads
- Consider S3 Batch Operations for bulk operations

#### 3. Access Patterns
- Use Intelligent Tiering for unknown access patterns
- Implement lifecycle policies based on access frequency
- Monitor CloudWatch metrics to optimize storage classes

## Advanced Configuration

### Custom Bucket Policies

```hcl
# IP-based access restriction
bucket_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Sid       = "IPAllow"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        "arn:aws:s3:::bucket-name",
        "arn:aws:s3:::bucket-name/*"
      ]
      Condition = {
        IpAddress = {
          "aws:SourceIp" = ["203.0.113.0/24", "198.51.100.0/24"]
        }
      }
    }
  ]
})
```

### Event Notifications with Filtering

```hcl
notifications = {
  lambda_functions = [
    {
      lambda_function_arn = aws_lambda_function.image_processor.arn
      events             = ["s3:ObjectCreated:Put", "s3:ObjectCreated:Post"]
      filter_prefix      = "uploads/images/"
      filter_suffix      = ".jpg"
    }
  ]
  sns_topics = [
    {
      topic_arn     = aws_sns_topic.document_processing.arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "documents/"
      filter_suffix = ".pdf"
    }
  ]
  sqs_queues = [
    {
      queue_arn     = aws_sqs_queue.processing_queue.arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "processing/"
    }
  ]
}
```

### Multi-Region Disaster Recovery

```hcl
# Primary region configuration
module "primary_storage" {
  source = "./modules/s3"
  
  s3_buckets = {
    "critical-data" = {
      versioning_enabled = true
      
      replication = {
        role_arn = aws_iam_role.replication.arn
        rules = [
          {
            id       = "disaster_recovery"
            status   = "Enabled"
            priority = 1
            destination = {
              bucket             = "critical-data-dr"
              storage_class      = "STANDARD_IA"
              replica_kms_key_id = module.kms_dr.key_arns["s3"]
              account_id         = data.aws_caller_identity.current.account_id
            }
          }
        ]
      }
    }
  }
}

# Disaster recovery region
module "dr_storage" {
  source = "./modules/s3"
  
  providers = {
    aws = aws.dr_region
  }
  
  s3_buckets = {
    "critical-data-dr" = {
      bucket_type = "backup"
      
      # Failback replication
      replication = {
        role_arn = aws_iam_role.replication_dr.arn
        rules = [
          {
            id       = "failback"
            status   = "Disabled"  # Enable during DR scenarios
            priority = 1
            destination = {
              bucket        = "critical-data"
              storage_class = "STANDARD"
            }
          }
        ]
      }
    }
  }
}
```

## Migration Strategies

### Migrating from Existing Buckets

```hcl
# Import existing bucket
resource "aws_s3_bucket" "imported" {
  bucket = "existing-bucket-name"
  
  lifecycle {
    prevent_destroy = true
  }
}

# Then configure with module
module "migrated_buckets" {
  source = "./modules/s3"
  
  s3_buckets = {
    "existing-bucket-name" = {
      # Configuration matching existing setup
      versioning_enabled = true
      # ... other settings
    }
  }
}
```

### Zero-Downtime Migration

```bash
# 1. Import existing resources
terraform import module.s3_buckets.aws_s3_bucket.this["bucket-name"] bucket-name
terraform import module.s3_buckets.aws_s3_bucket_versioning.this["bucket-name"] bucket-name

# 2. Update configuration gradually
# 3. Validate with terraform plan
terraform plan

# 4. Apply changes
terraform apply
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

### Development Guidelines

- Follow Terraform best practices
- Use meaningful variable names and descriptions
- Add comprehensive validation rules
- Include examples in documentation
- Test with multiple AWS regions
- Ensure backward compatibility

## License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for full details.

## Authors

- **Diego A. Zarate** - *Initial work* - [GitHub Profile](https://github.com/dzarate)

## Acknowledgments

- AWS S3 documentation and best practices
- Terraform AWS Provider documentation
- AWS Well-Architected Framework
- Community feedback and contributions

---

**Note**: This module follows semantic versioning. Please check the [CHANGELOG](CHANGELOG.md) for version-specific changes and migration guides.