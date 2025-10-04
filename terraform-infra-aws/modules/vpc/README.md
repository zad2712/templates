# AWS VPC Terraform Module

**Author:** Diego A. Zarate

This module creates a VPC (Virtual Private Cloud) with configurable subnets, internet gateway, NAT gateways, and associated networking components following AWS best practices.

## Features

- **VPC** with customizable CIDR block and DNS settings
- **Public Subnets** with Internet Gateway for internet access
- **Private Subnets** with NAT Gateway for outbound internet access
- **Database Subnets** for isolated database resources
- **ElastiCache Subnets** for caching infrastructure
- **Intra Subnets** for internal communication only
- **IPv6 Support** with dual-stack configuration
- **DHCP Options** for custom DNS and domain settings
- **VPN Gateway** for hybrid cloud connectivity
- **Comprehensive Tagging** with environment-specific tags

## Usage

### Basic VPC with Public and Private Subnets

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name = "my-vpc"
  cidr_block = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Production VPC with All Subnet Types

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name = "production-vpc"
  cidr_block = "10.0.0.0/16"

  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  elasticache_subnets = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "prod"
    Project     = "my-project"
  }
}
```

### IPv6 Enabled VPC

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name = "ipv6-vpc"
  cidr_block = "10.0.0.0/16"

  enable_ipv6 = true

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  public_subnet_ipv6_prefixes  = [0, 1, 2]
  private_subnet_ipv6_prefixes = [3, 4, 5]

  public_subnet_assign_ipv6_address_on_creation  = true
  private_subnet_assign_ipv6_address_on_creation = false

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
    Project     = "ipv6-project"
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
| aws_vpc.this | resource |
| aws_vpc_dhcp_options.this | resource |
| aws_vpc_dhcp_options_association.this | resource |
| aws_internet_gateway.this | resource |
| aws_vpn_gateway.this | resource |
| aws_vpn_gateway_attachment.this | resource |
| aws_subnet.public | resource |
| aws_subnet.private | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name to be used on all resources as identifier | `string` | `""` | no |
| cidr_block | The IPv4 CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| azs | A list of availability zones names or ids in the region | `list(string)` | `[]` | no |
| public_subnets | A list of public subnets inside the VPC | `list(string)` | `[]` | no |
| private_subnets | A list of private subnets inside the VPC | `list(string)` | `[]` | no |
| database_subnets | A list of database subnets inside the VPC | `list(string)` | `[]` | no |
| elasticache_subnets | A list of elasticache subnets inside the VPC | `list(string)` | `[]` | no |
| enable_nat_gateway | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `false` | no |
| single_nat_gateway | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| enable_dns_hostnames | Should be true to enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable_dns_support | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| enable_ipv6 | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC | `bool` | `false` | no |
| tags | A map of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnets | List of IDs of public subnets |
| private_subnets | List of IDs of private subnets |
| database_subnets | List of IDs of database subnets |
| elasticache_subnets | List of IDs of elasticache subnets |
| igw_id | The ID of the Internet Gateway |
| nat_ids | List of IDs of the NAT gateways |
| nat_public_ips | List of public Elastic IPs associated with the NAT gateways |

## Examples

### Cost-Optimized Development Environment

```hcl
module "dev_vpc" {
  source = "../../modules/vpc"

  name = "dev-vpc"
  cidr_block = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  # Cost optimization for development
  enable_nat_gateway = true
  single_nat_gateway = true  # Single NAT for cost savings
  
  # Minimal configuration
  enable_vpn_gateway = false
  enable_dhcp_options = false

  tags = {
    Environment = "dev"
    CostCenter  = "development"
    Project     = "my-app"
  }
}
```

### High Availability Production Environment

```hcl
module "prod_vpc" {
  source = "../../modules/vpc"

  name = "prod-vpc"
  cidr_block = "10.0.0.0/16"

  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  elasticache_subnets = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]

  # High availability configuration
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # Enterprise features
  enable_vpn_gateway  = true
  enable_dhcp_options = true
  
  dhcp_options_domain_name = "company.local"
  dhcp_options_domain_name_servers = ["10.0.0.2", "AmazonProvidedDNS"]

  tags = {
    Environment = "prod"
    CostCenter  = "operations"
    Project     = "my-app"
    Compliance  = "required"
  }
}
```

## Best Practices

1. **CIDR Planning**: Use non-overlapping CIDR blocks across environments
2. **Multi-AZ Deployment**: Always use at least 2 availability zones for high availability
3. **NAT Gateway Strategy**: Use single NAT for dev, multiple NAT for production
4. **Tagging**: Implement comprehensive tagging for cost allocation and management
5. **Security**: Follow least privilege principle for subnet routing
6. **Monitoring**: Enable VPC Flow Logs for network monitoring

## Security Considerations

- Public subnets should only contain load balancers and NAT gateways
- Private subnets for application servers and compute resources
- Database subnets should be isolated with no internet routing
- Use security groups and NACLs for defense in depth
- Enable VPC Flow Logs for network monitoring and forensics

## Cost Optimization

- Use single NAT gateway for development environments
- Consider VPC endpoints to reduce data transfer costs
- Implement proper subnet sizing to avoid IP waste
- Use appropriate instance tenancy (shared vs dedicated)
- Monitor and optimize data transfer patterns

## Troubleshooting

### Common Issues

1. **CIDR Conflicts**: Ensure non-overlapping IP ranges
2. **AZ Unavailability**: Check AZ availability in your region
3. **Route Configuration**: Verify internet and NAT gateway routes
4. **Security Group Rules**: Check for blocking security group rules

### Debugging Commands

```bash
# Check VPC configuration
aws ec2 describe-vpcs --vpc-ids <vpc-id>

# Verify subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>"
```

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Author

**Diego A. Zarate**  
Infrastructure Architect & AWS Solutions Architect

For questions or issues, please create an issue in the repository or contact the infrastructure team.