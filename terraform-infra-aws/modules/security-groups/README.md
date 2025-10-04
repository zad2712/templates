# AWS Security Groups Terraform Module

**Author:** Diego A. Zarate

This module creates a comprehensive set of security groups following AWS best practices for multi-tier application architectures. It supports web, application, database, cache, management, Lambda, and EKS tiers with customizable rules and automatic tier-to-tier communication setup.

## Features

- **Multi-Tier Architecture Support** with predefined security groups for each tier
- **Automatic Tier-to-Tier Communication** with proper rule relationships
- **Flexible Rule Configuration** with both predefined and custom rules
- **EKS Support** with separate cluster and worker node security groups
- **Lambda Integration** with VPC-enabled function support
- **Management Access** with bastion host and administrative access patterns
- **Custom Security Groups** for specialized requirements
- **Comprehensive Validation** with input validation and best practices enforcement

## Architecture

### Standard 3-Tier Architecture
```
Internet Gateway
        ↓
    Web Tier (ALB/NLB)
        ↓
  Application Tier
        ↓
   Database Tier
```

### Extended Multi-Tier Architecture
```
Internet Gateway
        ↓
    Web Tier (ALB/NLB)
        ↓
  Application Tier ←→ Lambda Functions
        ↓               ↓
   Cache Tier      Database Tier
        ↓               ↓
    EKS Cluster ←→ Management/Bastion
```

## Usage

### Basic 3-Tier Application

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = "myapp"
  vpc_id      = module.vpc.vpc_id

  # Standard 3-tier setup
  create_web_sg = true
  create_app_sg = true
  create_db_sg  = true

  # Port configuration
  app_port      = 8080
  database_port = 5432

  tags = {
    Environment = "production"
    Project     = "my-application"
  }
}
```

### Complete Multi-Tier Architecture

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = "enterprise"
  vpc_id      = module.vpc.vpc_id

  # Enable all tier security groups
  create_web_sg         = true
  create_app_sg         = true
  create_db_sg          = true
  create_cache_sg       = true
  create_management_sg  = true
  create_lambda_sg      = true
  create_eks_cluster_sg = true
  create_eks_workers_sg = true

  # Port configuration
  app_port      = 8080
  database_port = 5432
  cache_port    = 6379

  # Web tier access
  web_http_ingress_cidr_blocks  = ["0.0.0.0/0"]
  web_https_ingress_cidr_blocks = ["0.0.0.0/0"]

  # Management access (restrict to office IPs)
  management_ssh_ingress_cidr_blocks = ["203.0.113.0/24"]

  # EKS pod communication
  eks_pod_cidr_blocks = ["100.64.0.0/16"]

  tags = {
    Environment = "production"
    Project     = "enterprise-app"
    Owner       = "platform-team"
  }
}
```

### Custom Security Groups

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = "custom"
  vpc_id      = module.vpc.vpc_id

  # Standard groups
  create_web_sg = true
  create_app_sg = true

  # Custom security groups for specialized services
  custom_security_groups = {
    elasticsearch = {
      description = "Security group for Elasticsearch cluster"
      ingress_rules = [
        {
          description = "Elasticsearch HTTP"
          from_port   = 9200
          to_port     = 9200
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
        },
        {
          description = "Elasticsearch transport"
          from_port   = 9300
          to_port     = 9300
          protocol    = "tcp"
          self        = true
        }
      ]
      egress_rules = [
        {
          description = "All outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      tags = {
        Service = "elasticsearch"
      }
    }

    monitoring = {
      description = "Security group for monitoring services"
      ingress_rules = [
        {
          description = "Prometheus"
          from_port   = 9090
          to_port     = 9090
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
        },
        {
          description = "Grafana"
          from_port   = 3000
          to_port     = 3000
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
        }
      ]
      egress_rules = [
        {
          description = "Metrics collection"
          from_port   = 0
          to_port     = 65535
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
        }
      ]
      tags = {
        Service = "monitoring"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "monitoring-stack"
  }
}
```

### EKS-Focused Configuration

```hcl
module "eks_security_groups" {
  source = "../../modules/security-groups"

  name_prefix = "eks-cluster"
  vpc_id      = module.vpc.vpc_id

  # EKS-specific groups
  create_eks_cluster_sg = true
  create_eks_workers_sg = true
  create_management_sg  = true

  # Pod networking
  eks_pod_cidr_blocks = [
    "100.64.0.0/16",  # Primary pod CIDR
    "100.65.0.0/16"   # Secondary pod CIDR
  ]

  # Management access for kubectl
  management_ssh_ingress_cidr_blocks = [
    "203.0.113.0/24",  # Office network
    "198.51.100.0/24"  # VPN network
  ]

  # Custom ingress for EKS API server
  eks_cluster_custom_ingress_rules = [
    {
      description = "EKS API access from CI/CD"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.1.0.0/24"]
    }
  ]

  # Custom ingress for worker nodes
  eks_workers_custom_ingress_rules = [
    {
      description = "NodePort services"
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  tags = {
    Environment = "production"
    Service     = "kubernetes"
    Owner       = "platform-team"
  }
}
```

## Security Group Types

### Web Tier Security Group
- **Purpose**: Load balancers (ALB, NLB) and web servers
- **Ingress**: HTTP (80), HTTPS (443) from internet or specified CIDRs
- **Egress**: Application tier on configured port

### Application Tier Security Group  
- **Purpose**: Application servers, containers, and compute instances
- **Ingress**: From web tier, SSH from management
- **Egress**: Database tier, cache tier, internet (for updates/APIs)

### Database Tier Security Group
- **Purpose**: RDS instances, database servers
- **Ingress**: From application tier on database port
- **Egress**: None (databases should not initiate outbound connections)

### Cache Tier Security Group
- **Purpose**: ElastiCache (Redis/Memcached) clusters
- **Ingress**: From application tier on cache port
- **Egress**: None (cache should not initiate outbound connections)

### Management Security Group
- **Purpose**: Bastion hosts, jump servers, administrative access
- **Ingress**: SSH (22) or RDP (3389) from specified CIDRs
- **Egress**: All (for administrative tasks)

### Lambda Security Group
- **Purpose**: VPC-enabled Lambda functions
- **Ingress**: Custom rules (typically none needed)
- **Egress**: Database, cache, internet access

### EKS Cluster Security Group
- **Purpose**: EKS control plane
- **Ingress**: HTTPS from worker nodes, custom API access
- **Egress**: All traffic to worker nodes

### EKS Workers Security Group
- **Purpose**: EKS worker nodes (EC2 instances)
- **Ingress**: From control plane, node-to-node, pod-to-pod
- **Egress**: Control plane HTTPS, internet access

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
| aws_security_group.web | resource |
| aws_security_group.app | resource |
| aws_security_group.db | resource |
| aws_security_group.cache | resource |
| aws_security_group.management | resource |
| aws_security_group.lambda | resource |
| aws_security_group.eks_cluster | resource |
| aws_security_group.eks_workers | resource |
| aws_security_group.custom | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Name prefix for security group resources | `string` | `"app"` | no |
| vpc_id | ID of the VPC where security groups will be created | `string` | n/a | yes |
| create_web_sg | Whether to create web tier security group | `bool` | `true` | no |
| create_app_sg | Whether to create application tier security group | `bool` | `true` | no |
| create_db_sg | Whether to create database tier security group | `bool` | `true` | no |
| create_cache_sg | Whether to create cache tier security group | `bool` | `false` | no |
| create_management_sg | Whether to create management security group | `bool` | `false` | no |
| create_lambda_sg | Whether to create Lambda security group | `bool` | `false` | no |
| create_eks_cluster_sg | Whether to create EKS cluster security group | `bool` | `false` | no |
| create_eks_workers_sg | Whether to create EKS workers security group | `bool` | `false` | no |
| app_port | Port used by application tier | `number` | `8080` | no |
| database_port | Port used by database tier | `number` | `5432` | no |
| cache_port | Port used by cache tier | `number` | `6379` | no |
| web_http_ingress_cidr_blocks | CIDR blocks allowed HTTP access | `list(string)` | `["0.0.0.0/0"]` | no |
| web_https_ingress_cidr_blocks | CIDR blocks allowed HTTPS access | `list(string)` | `["0.0.0.0/0"]` | no |
| custom_security_groups | Map of custom security groups to create | `map(object)` | `{}` | no |
| tags | A map of tags to assign to security groups | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_sg_id | ID of the web tier security group |
| app_sg_id | ID of the application tier security group |
| db_sg_id | ID of the database tier security group |
| cache_sg_id | ID of the cache tier security group |
| management_sg_id | ID of the management security group |
| lambda_sg_id | ID of the Lambda security group |
| eks_cluster_sg_id | ID of the EKS cluster security group |
| eks_workers_sg_id | ID of the EKS workers security group |
| all_sg_ids | Map of all security group types to their IDs |
| custom_sg_ids | Map of custom security group names to IDs |

## Best Practices

### Security Principles
1. **Least Privilege**: Grant minimal required access
2. **Defense in Depth**: Multiple security layers
3. **Segregation**: Separate tiers with appropriate rules
4. **Zero Trust**: Explicit allow rules, deny by default

### Rule Configuration
1. **Specific Ports**: Use specific ports instead of ranges
2. **Source Restriction**: Limit source CIDRs and security groups
3. **Egress Control**: Explicitly define egress rules
4. **Regular Review**: Audit rules regularly for compliance

### Operational Guidelines
1. **Consistent Naming**: Use descriptive, consistent naming conventions
2. **Comprehensive Tagging**: Tag all resources for management
3. **Documentation**: Document custom rules and exceptions
4. **Monitoring**: Enable VPC Flow Logs for traffic analysis

## Security Considerations

### Network Segmentation
- Web tier: Public subnets with internet access
- Application tier: Private subnets with NAT gateway access
- Database tier: Private subnets without internet access
- Management tier: Separate subnets with restricted access

### Access Control
- Implement IP allowlists for administrative access
- Use security groups instead of NACLs for stateful filtering
- Avoid overly permissive rules (0.0.0.0/0 on all ports)
- Regular security group audit and cleanup

### Monitoring and Logging
- Enable VPC Flow Logs for network traffic monitoring
- Monitor security group changes via CloudTrail
- Set up alerts for unauthorized rule modifications
- Implement compliance checks for security group rules

## Troubleshooting

### Common Issues
1. **Connection Timeouts**: Check security group rules and NACLs
2. **Rule Conflicts**: Verify rule precedence and overlaps
3. **Port Accessibility**: Confirm application is listening on configured ports
4. **DNS Resolution**: Check VPC DNS settings and security group rules

### Debugging Commands
```bash
# List security groups
aws ec2 describe-security-groups --group-ids sg-12345678

# Test connectivity
telnet <target-ip> <port>

# Check VPC Flow Logs
aws logs filter-log-events --log-group-name /aws/vpc/flowlogs

# Verify security group rules
aws ec2 describe-security-group-rules --group-ids sg-12345678
```

### Validation Steps
1. Verify security group creation and rule configuration
2. Test connectivity between tiers
3. Validate egress rules for internet access
4. Confirm management access from allowed sources
5. Check EKS cluster and worker node communication

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Author

**Diego A. Zarate**  
Infrastructure Architect & AWS Solutions Architect

For questions or issues, please create an issue in the repository or contact the infrastructure team.