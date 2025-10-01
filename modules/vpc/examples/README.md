# VPC Module Examples

This directory contains examples demonstrating different ways to use the VPC module.

## Available Examples

### 1. Basic Example (`basic.tf`)
Demonstrates the simplest usage of the VPC module suitable for development environments.

**Features:**
- Basic VPC with public and private subnets
- Single NAT Gateway (cost-effective)
- Minimal configuration
- Simple tagging

**Usage:**
```bash
cd examples
terraform init
terraform plan -var-file=basic.tfvars
terraform apply
```

### 2. Production Example (`production.tf`)
Shows a production-ready configuration with all security and monitoring features enabled.

**Features:**
- Multi-AZ deployment across 3 availability zones
- Separate database subnets
- VPC Flow Logs enabled
- Network ACLs for additional security
- Multiple NAT Gateways for high availability
- VPC endpoints for cost optimization
- Comprehensive security groups
- CloudWatch logging
- Comprehensive tagging strategy

**Usage:**
```bash
cd examples
terraform init
terraform plan -var-file=production.tfvars
terraform apply
```

### 3. Complete Example (`complete.tf`)
Demonstrates VPC integration with a full application stack including ALB, ECS, and RDS.

**Features:**
- Complete 3-tier architecture (Web, App, Database)
- Application Load Balancer in public subnets
- ECS Fargate services in private subnets
- RDS PostgreSQL in database subnets
- Security groups with proper tier isolation
- Secrets Manager integration
- CloudWatch logging

**Usage:**
```bash
cd examples
terraform init
terraform plan
terraform apply
```

## Variable Files

Create `.tfvars` files for each example to customize the configuration:

### basic.tfvars
```hcl
aws_region  = "us-west-2"
environment = "dev"
```

### production.tfvars
```hcl
aws_region   = "us-east-1"
environment  = "prod"
project_name = "my-app"
owner        = "platform-team"
```

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (>= 1.3.0)
3. **AWS provider** (>= 5.0.0)

## Required IAM Permissions

The following IAM permissions are required to run these examples:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "logs:*",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "ecs:*",
                "elasticloadbalancing:*",
                "rds:*",
                "secretsmanager:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## Cleanup

To destroy the resources created by any example:

```bash
terraform destroy
```

## Cost Considerations

- **Basic Example**: ~$45-60/month (single NAT Gateway)
- **Production Example**: ~$135-180/month (3 NAT Gateways)
- **Complete Example**: ~$200-300/month (includes ALB, ECS, RDS)

*Costs are approximate and vary by region and actual usage.*

## Security Notes

- All examples follow security best practices
- Database passwords are generated randomly and stored in Secrets Manager
- Security groups follow least privilege principle
- Network ACLs provide additional defense in depth
- VPC Flow Logs enabled for monitoring (production example)

## Customization

You can customize these examples by:

1. Modifying CIDR blocks to match your network requirements
2. Adjusting the number of availability zones
3. Enabling/disabling features based on your needs
4. Adding additional security groups or resources
5. Integrating with existing infrastructure

## Troubleshooting

1. **Plan fails with CIDR conflicts**: Ensure CIDR blocks don't overlap with existing VPCs
2. **NAT Gateway creation fails**: Check Elastic IP limits in your account
3. **RDS creation fails**: Verify you have at least 2 database subnets in different AZs
4. **Permission errors**: Ensure your IAM user/role has the required permissions

## Next Steps

After running these examples, consider:

1. Setting up monitoring and alerting
2. Implementing backup strategies
3. Adding auto-scaling policies
4. Configuring CI/CD pipelines
5. Implementing disaster recovery procedures