# Global AWS Infrastructure Resources

**Author:** Diego A. Zarate

This directory contains Terraform configurations for global AWS resources that are shared across multiple environments and regions. These resources are typically deployed once and used by all other infrastructure layers.

## 📋 Global Resources

### Core Global Services

- **S3 Buckets**: Terraform state storage, logging, and backup buckets
- **DynamoDB Tables**: Terraform state locking tables
- **IAM Roles**: Cross-account and service roles
- **KMS Keys**: Global encryption keys for cross-region use
- **Route 53**: Global DNS zones and records
- **CloudFront**: Global CDN distributions
- **WAF**: Global web application firewall rules
- **Certificate Manager**: Global SSL/TLS certificates

### Cross-Region Resources

- **IAM Policies**: Global identity and access policies
- **Organizations**: AWS Organizations structure (if applicable)
- **Control Tower**: Landing zone configuration (if applicable)
- **SSO**: Single Sign-On configuration
- **CloudTrail**: Global API logging
- **Config**: Global compliance configuration

## 🗂️ Directory Structure

```
global/
├── README.md                 # This file
├── terraform-state/          # S3 backend and DynamoDB setup
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── dns/                      # Route 53 global DNS
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── certificates/             # ACM global certificates
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── cdn/                      # CloudFront distributions
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── iam/                      # Global IAM resources
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## 🚀 Deployment Order

Global resources should be deployed in the following order:

1. **Terraform State Infrastructure** (S3 + DynamoDB)
2. **Global IAM Roles and Policies**
3. **Global KMS Keys**
4. **DNS Zones** (Route 53)
5. **SSL Certificates** (ACM)
6. **CloudFront Distributions**
7. **Global WAF Rules**

## 🔧 Configuration

Global resources are configured once and shared across all environments. Key considerations:

### Naming Conventions

All global resources follow this naming pattern:
```
<project>-global-<service>-<identifier>
```

Example: `myapp-global-s3-terraform-state`

### Tagging Strategy

Global resources use consistent tagging:

```hcl
global_tags = {
  Project     = var.project_name
  Environment = "global"
  Layer       = "global"
  ManagedBy   = "terraform"
  Repository  = "terraform-infra-aws"
  Author      = "Diego A. Zarate"
  Scope       = "global"
}
```

## 🛡️ Security Considerations

### State Management

- S3 bucket encryption with AWS KMS
- Versioning enabled for state recovery
- DynamoDB table for state locking
- Cross-region replication for disaster recovery
- Bucket policies restricting access

### Access Control

- Principle of least privilege for all IAM roles
- MFA required for sensitive operations
- Cross-account roles for multi-account setups
- Regular access reviews and rotation

### Encryption

- All data encrypted at rest and in transit
- Customer-managed KMS keys where required
- Key rotation policies enabled
- Separate keys for different services

## 🌍 Multi-Region Considerations

### Primary Region
- **us-east-1**: Global services (CloudFront, Route 53, IAM)
- **us-east-1**: Primary region for most services

### Secondary Regions
- **us-west-2**: Disaster recovery region
- **eu-west-1**: European operations (if required)

### Global Service Locations

Some AWS services are global by nature:
- **IAM**: Global service
- **Route 53**: Global DNS
- **CloudFront**: Global CDN
- **WAF**: Can be global or regional

## 🔄 State Management

### Initial Bootstrap

For the initial deployment, you may need to bootstrap the Terraform state infrastructure:

```bash
# Deploy state infrastructure first (local state)
cd global/terraform-state/
terraform init
terraform plan
terraform apply

# Then configure remote state for other global resources
cd ../dns/
terraform init -backend-config=backend.conf
terraform plan
terraform apply
```

### Backend Configuration

After deploying the state infrastructure, all other global resources use remote state:

```hcl
terraform {
  backend "s3" {
    # Configuration loaded from backend.conf
  }
}
```

## 📚 Documentation References

- [AWS Global Infrastructure](https://aws.amazon.com/about-aws/global-infrastructure/)
- [Terraform S3 Backend](https://www.terraform.io/docs/backends/types/s3.html)
- [AWS Multi-Account Strategy](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 🤝 Contributing

When adding global resources:

1. Ensure resources are truly global (used across environments)
2. Follow naming conventions and tagging standards
3. Document any cross-region dependencies
4. Update this README with new resource types
5. Test in a development account first

## 📞 Support

For questions about global infrastructure:

1. Review this documentation
2. Check AWS service limits and quotas
3. Verify IAM permissions
4. Contact the infrastructure team

---

**Note:** Global resources have wide-reaching impact. Always review changes carefully and test in non-production accounts first.