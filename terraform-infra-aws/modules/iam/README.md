# AWS IAM Terraform Module

**Author:** Diego A. Zarate

This module creates comprehensive IAM resources following AWS security best practices and the principle of least privilege. It supports roles, policies, groups, users, service-linked roles, and identity providers with flexible configuration options.

## Features

- **IAM Roles** with flexible assume role policies and conditions
- **Custom IAM Policies** with JSON policy document support
- **IAM Groups** with managed and custom policy attachments
- **IAM Users** with optional access key generation (controlled by feature flags)
- **Service-Linked Roles** for AWS services
- **Identity Providers** (OIDC and SAML) for federated access
- **Instance Profiles** for EC2 roles
- **Account Configuration** with password policy and account alias
- **Comprehensive Security** with input validation and best practices

## Security Principles

### Least Privilege Access
- Minimal required permissions for each role
- Explicit deny policies where appropriate
- Time-bound sessions with configurable duration

### Defense in Depth
- Multiple layers of access control
- Permissions boundaries support
- Conditional access based on context

### Zero Trust Architecture
- Explicit trust relationships
- Continuous verification through conditions
- Minimal network trust assumptions

## Usage

### Basic Service Roles

```hcl
module "iam" {
  source = "../../modules/iam"

  name_prefix = "myapp"

  # Create essential service roles
  iam_roles = {
    ec2_instance = {
      description           = "Role for EC2 instances"
      principal_type        = "Service"
      principal_identifiers = ["ec2.amazonaws.com"]
      aws_managed_policies  = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      max_session_duration = 3600
    }

    lambda_execution = {
      description           = "Role for Lambda functions"
      principal_type        = "Service"
      principal_identifiers = ["lambda.amazonaws.com"]
      aws_managed_policies  = [
        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      ]
      custom_managed_policies = ["lambda_custom_policy"]
      max_session_duration   = 3600
    }
  }

  # Custom policies
  iam_policies = {
    lambda_custom_policy = {
      description = "Custom policy for Lambda functions"
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = "arn:aws:s3:::my-bucket/*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-application"
  }
}
```

### Cross-Account Roles

```hcl
module "cross_account_iam" {
  source = "../../modules/iam"

  name_prefix = "cross-account"

  iam_roles = {
    cross_account_admin = {
      description           = "Cross-account administrative access"
      principal_type        = "AWS"
      principal_identifiers = ["arn:aws:iam::123456789012:root"]
      aws_managed_policies  = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      
      # Require MFA for cross-account access
      assume_role_conditions = [
        {
          test     = "Bool"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["true"]
        },
        {
          test     = "NumericLessThan"
          variable = "aws:MultiFactorAuthAge"
          values   = ["3600"]  # 1 hour
        }
      ]
      
      max_session_duration = 7200  # 2 hours
    }

    readonly_auditor = {
      description           = "Cross-account read-only access for auditing"
      principal_type        = "AWS" 
      principal_identifiers = ["arn:aws:iam::987654321098:role/AuditorRole"]
      aws_managed_policies  = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/SecurityAudit"
      ]
      max_session_duration = 3600
    }
  }

  tags = {
    Environment = "shared"
    Purpose     = "cross-account-access"
  }
}
```

### EKS and Kubernetes Integration

```hcl
module "eks_iam" {
  source = "../../modules/iam"

  name_prefix = "eks-cluster"

  iam_roles = {
    eks_cluster = {
      description           = "EKS cluster service role"
      principal_type        = "Service"
      principal_identifiers = ["eks.amazonaws.com"]
      aws_managed_policies  = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
    }

    eks_node_group = {
      description           = "EKS node group role"
      principal_type        = "Service"
      principal_identifiers = ["ec2.amazonaws.com"]
      aws_managed_policies  = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
    }

    eks_fargate = {
      description           = "EKS Fargate profile execution role"
      principal_type        = "Service"
      principal_identifiers = ["eks-fargate-pods.amazonaws.com"]
      aws_managed_policies  = [
        "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
      ]
    }
  }

  # OIDC provider for EKS service accounts
  oidc_providers = {
    eks_cluster = {
      url             = "https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      client_id_list  = ["sts.amazonaws.com"]
      thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
    }
  }

  tags = {
    Environment = "production"
    Service     = "kubernetes"
  }
}
```

### User Management and Groups

```hcl
module "user_management_iam" {
  source = "../../modules/iam"

  name_prefix = "company"

  # Enable user creation (use with caution)
  create_users = true

  # Groups for different access levels
  iam_groups = {
    developers = {
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
      custom_managed_policies = ["developer_policy"]
      users = ["john_doe", "jane_smith"]
    }

    devops = {
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      users = ["devops_user"]
    }

    readonly = {
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      users = ["auditor", "manager"]
    }
  }

  # Custom developer policy
  iam_policies = {
    developer_policy = {
      description = "Custom policy for developers"
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Deny"
            Action = [
              "iam:*",
              "organizations:*",
              "account:*"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  # Users
  iam_users = {
    john_doe = {
      force_destroy = true
    }
    jane_smith = {
      force_destroy = true
    }
    devops_user = {
      force_destroy = true
    }
    auditor = {
      force_destroy = true
    }
    manager = {
      force_destroy = true
    }
  }

  tags = {
    Environment = "shared"
    Purpose     = "user-management"
  }
}
```

### Service-Linked Roles

```hcl
module "service_linked_roles" {
  source = "../../modules/iam"

  name_prefix = "aws-services"

  service_linked_roles = {
    elasticloadbalancing = {
      aws_service_name = "elasticloadbalancing.amazonaws.com"
      description      = "Service-linked role for Elastic Load Balancing"
    }

    autoscaling = {
      aws_service_name = "autoscaling.amazonaws.com"
      description      = "Service-linked role for Auto Scaling"
    }

    rds = {
      aws_service_name = "rds.amazonaws.com"
      description      = "Service-linked role for Amazon RDS"
    }
  }

  tags = {
    Environment = "shared"
    Purpose     = "aws-service-integration"
  }
}
```

### Federated Identity with SAML

```hcl
module "federated_iam" {
  source = "../../modules/iam"

  name_prefix = "federated"

  # SAML identity provider
  saml_providers = {
    corporate_sso = {
      saml_metadata_document = file("${path.module}/corporate-sso-metadata.xml")
    }
  }

  # Federated access roles
  iam_roles = {
    federated_admin = {
      description           = "Federated administrative access"
      principal_type        = "Federated"
      principal_identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/corporate-sso"
      ]
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      
      assume_role_conditions = [
        {
          test     = "StringEquals"
          variable = "SAML:Role"
          values   = ["Administrator"]
        }
      ]
      
      max_session_duration = 3600
    }

    federated_readonly = {
      description           = "Federated read-only access"
      principal_type        = "Federated"
      principal_identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/corporate-sso"
      ]
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      
      assume_role_conditions = [
        {
          test     = "StringEquals"
          variable = "SAML:Role"
          values   = ["ReadOnly"]
        }
      ]
      
      max_session_duration = 3600
    }
  }

  tags = {
    Environment = "shared"
    Purpose     = "federated-access"
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

## Resources

| Name | Type |
|------|------|
| aws_iam_role | resource |
| aws_iam_policy | resource |
| aws_iam_group | resource |
| aws_iam_user | resource |
| aws_iam_role_policy_attachment | resource |
| aws_iam_group_policy_attachment | resource |
| aws_iam_group_membership | resource |
| aws_iam_access_key | resource |
| aws_iam_instance_profile | resource |
| aws_iam_service_linked_role | resource |
| aws_iam_openid_connect_provider | resource |
| aws_iam_saml_provider | resource |
| aws_iam_account_password_policy | resource |
| aws_iam_account_alias | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Name prefix for IAM resources | `string` | `"app"` | no |
| iam_roles | Map of IAM roles to create | `map(object)` | `{}` | no |
| iam_policies | Map of custom IAM policies to create | `map(object)` | `{}` | no |
| iam_groups | Map of IAM groups to create | `map(object)` | `{}` | no |
| iam_users | Map of IAM users to create | `map(object)` | `{}` | no |
| create_users | Whether to create IAM users | `bool` | `false` | no |
| create_access_keys | Whether to create access keys for users | `bool` | `false` | no |
| service_linked_roles | Map of service-linked roles to create | `map(object)` | `{}` | no |
| oidc_providers | Map of OIDC identity providers | `map(object)` | `{}` | no |
| saml_providers | Map of SAML identity providers | `map(object)` | `{}` | no |
| password_policy | Account password policy configuration | `object` | `{...}` | no |
| account_alias | The account alias for the AWS account | `string` | `null` | no |
| tags | A map of tags to assign to IAM resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arns | Map of role names to their ARNs |
| role_names | Map of role names to their names |
| policy_arns | Map of policy names to their ARNs |
| group_arns | Map of group names to their ARNs |
| user_arns | Map of user names to their ARNs |
| instance_profile_arns | Map of instance profile names to their ARNs |
| access_key_ids | Map of user names to their access key IDs |
| secret_access_keys | Map of user names to their secret access keys (sensitive) |
| all_roles | Complete information about all created roles |
| security_summary | Summary of IAM security configuration |

## Best Practices

### Security Guidelines
1. **Principle of Least Privilege**: Grant minimal required permissions
2. **Use Roles over Users**: Prefer IAM roles for applications and services
3. **Enable MFA**: Require multi-factor authentication for sensitive operations
4. **Regular Rotation**: Rotate access keys and credentials regularly
5. **Monitor Usage**: Use CloudTrail and Access Analyzer for monitoring

### Role Design Patterns
1. **Service Roles**: Dedicated roles for each AWS service
2. **Cross-Account Roles**: Separate roles for cross-account access
3. **Federated Roles**: Integration with corporate identity providers
4. **Emergency Roles**: Break-glass access for incident response

### Policy Management
1. **Managed Policies**: Use AWS managed policies when possible
2. **Custom Policies**: Create custom policies for specific requirements
3. **Inline Policies**: Use sparingly for unique, one-off permissions
4. **Policy Versioning**: Track changes and maintain policy versions

## Security Considerations

### Access Control
- Implement conditions in assume role policies
- Use permissions boundaries to limit maximum permissions
- Regular access reviews and cleanup of unused roles/users
- Implement temporary credentials where possible

### Monitoring and Auditing
- Enable CloudTrail for all IAM operations
- Use AWS Config for compliance monitoring
- Implement alerting for sensitive IAM changes
- Regular access pattern analysis

### Compliance
- Follow organizational security policies
- Implement regulatory compliance requirements
- Document all custom policies and exceptions
- Regular security assessments

## Troubleshooting

### Common Issues
1. **Access Denied**: Check role permissions and trust policies
2. **Role Assumption Failures**: Verify assume role policy conditions
3. **Policy Size Limits**: Break large policies into smaller, focused policies
4. **Circular Dependencies**: Avoid creating circular role dependencies

### Debugging Commands
```bash
# Check role details
aws iam get-role --role-name <role-name>

# List attached policies
aws iam list-attached-role-policies --role-name <role-name>

# Simulate policy evaluation
aws iam simulate-principal-policy --policy-source-arn <role-arn> --action-names <action>

# Check assume role policy
aws sts assume-role --role-arn <role-arn> --role-session-name test
```

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Author

**Diego A. Zarate**  
Infrastructure Architect & AWS Solutions Architect

For questions or issues, please create an issue in the repository or contact the infrastructure team.