# Core Layer - Variables

#####################################################################################################
# General Configuration Variables
#####################################################################################################

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "salesforce-app"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

#####################################################################################################
# VPC Configuration Variables
#####################################################################################################

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR."
  }
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
}

#####################################################################################################
# VPC Feature Configuration
#####################################################################################################

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "create_igw" {
  description = "Create an Internet Gateway for the VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IP addresses to instances launched in public subnets"
  type        = bool
  default     = true
}

#####################################################################################################
# Database Configuration
#####################################################################################################

variable "create_database_subnet_group" {
  description = "Create a database subnet group for RDS instances"
  type        = bool
  default     = true
}

variable "create_database_route_table" {
  description = "Create separate route table for database subnets"
  type        = bool
  default     = true
}

#####################################################################################################
# Security Configuration
#####################################################################################################

variable "enable_flow_log" {
  description = "Enable VPC Flow Logs for security monitoring"
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
  description = "Manage the default security group to remove all rules"
  type        = bool
  default     = true
}

variable "create_network_acls" {
  description = "Create Network ACLs for additional subnet-level security"
  type        = bool
  default     = false
}

#####################################################################################################
# Cost Optimization Configuration
#####################################################################################################

variable "enable_s3_endpoint" {
  description = "Enable VPC endpoint for S3 to reduce data transfer costs"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Enable VPC endpoint for DynamoDB to reduce data transfer costs"
  type        = bool
  default     = true
}

#####################################################################################################
# Advanced Configuration
#####################################################################################################

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to add to the VPC"
  type        = list(string)
  default     = []
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for the VPC"
  type        = bool
  default     = false
}

variable "assign_ipv6_address_on_creation" {
  description = "Auto-assign IPv6 addresses to instances launched in subnets"
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "Tenancy of instances launched into the VPC"
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Instance tenancy must be either 'default' or 'dedicated'."
  }
}

#####################################################################################################
# Tagging Configuration
#####################################################################################################

variable "vpc_additional_tags" {
  description = "Additional tags to apply to VPC resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags specific to the VPC resource"
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
  default = {}
}

variable "public_route_table_tags" {
  description = "Additional tags for public route tables"
  type        = map(string)
  default = {}
}

variable "private_route_table_tags" {
  description = "Additional tags for private route tables"
  type        = map(string)
  default = {}
}

variable "database_route_table_tags" {
  description = "Additional tags for database route tables"
  type        = map(string)
  default = {}
}