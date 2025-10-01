#####################################################################################################
# AWS VPC Module - Variables Configuration
# Input variables for the VPC module with validation and defaults
#####################################################################################################

variable "name_prefix" {
  description = "Prefix for naming resources to ensure uniqueness and organization"
  type        = string

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 20
    error_message = "Name prefix must be between 1 and 20 characters."
  }
}

variable "cidr_block" {
  description = "CIDR block for the VPC. Must be a valid IPv4 CIDR block"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC. Required for EFS, RDS, and other services"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC. Required for EFS, RDS, and other services"
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets. Maximum of 3 subnets recommended for high availability"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnets) <= 6
    error_message = "Maximum of 6 public subnets are allowed."
  }
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets. Should match public subnets count for balanced architecture"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  validation {
    condition     = length(var.private_subnets) <= 6
    error_message = "Maximum of 6 private subnets are allowed."
  }
}

variable "database_subnets" {
  description = "List of CIDR blocks for database subnets. Minimum of 2 subnets required for RDS Multi-AZ"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  validation {
    condition     = length(var.database_subnets) == 0 || length(var.database_subnets) >= 2
    error_message = "Database subnets must be empty or contain at least 2 subnets for Multi-AZ deployment."
  }
}

variable "create_igw" {
  description = "Create an Internet Gateway for the VPC. Required for public internet access"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access. Required for private subnet outbound connectivity"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets. Cost-effective but reduces availability"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IP addresses to instances launched in public subnets"
  type        = bool
  default     = true
}

variable "create_database_subnet_group" {
  description = "Create a database subnet group for RDS instances"
  type        = bool
  default     = true
}

variable "create_database_route_table" {
  description = "Create separate route table for database subnets. Recommended for security isolation"
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Enable VPC Flow Logs for security monitoring and troubleshooting"
  type        = bool
  default     = false
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture in VPC Flow Logs"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_traffic_type)
    error_message = "Flow log traffic type must be ALL, ACCEPT, or REJECT."
  }
}

variable "flow_log_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_iam_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs to CloudWatch"
  type        = string
  default     = null
}

variable "manage_default_security_group" {
  description = "Manage the default security group. Recommended to remove all rules for security"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable VPC endpoint for S3. Cost-effective for S3 access from private subnets"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Enable VPC endpoint for DynamoDB. Cost-effective for DynamoDB access from private subnets"
  type        = bool
  default     = true
}

variable "create_network_acls" {
  description = "Create Network ACLs for additional subnet-level security. Defense in depth approach"
  type        = bool
  default     = false
}

#####################################################################################################
# Tagging Variables
#####################################################################################################

variable "common_tags" {
  description = "Common tags to apply to all resources. Should include project, environment, owner information"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "vpc_tags" {
  description = "Additional tags for the VPC resource"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default = {
    "kubernetes.io/role/elb" = "1"
  }
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}

variable "public_route_table_tags" {
  description = "Additional tags for public route tables"
  type        = map(string)
  default     = {}
}

variable "private_route_table_tags" {
  description = "Additional tags for private route tables"
  type        = map(string)
  default     = {}
}

variable "database_route_table_tags" {
  description = "Additional tags for database route tables"
  type        = map(string)
  default     = {}
}

#####################################################################################################
# Advanced Configuration Variables
#####################################################################################################

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to add to the VPC for IP address expansion"
  type        = list(string)
  default     = []
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for the VPC. Future-proofing for IPv6 adoption"
  type        = bool
  default     = false
}

variable "assign_ipv6_address_on_creation" {
  description = "Auto-assign IPv6 addresses to instances launched in subnets"
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "Tenancy of instances launched into the VPC. 'dedicated' for compliance requirements"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Instance tenancy must be either 'default' or 'dedicated'."
  }
}