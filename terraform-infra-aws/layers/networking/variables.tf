# =============================================================================
# NETWORKING LAYER VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

# =============================================================================
# NETWORK FEATURES
# =============================================================================

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Should be true if you want to create a new VPN Gateway resource and attach it to the VPC"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Should be true if you want to provision VPC endpoints"
  type        = bool
  default     = false
}

variable "vpc_endpoints" {
  description = "List of VPC endpoints to create"
  type        = list(string)
  default     = ["s3", "dynamodb", "ec2", "ssm", "ssmmessages", "ec2messages"]
}

variable "enable_transit_gateway" {
  description = "Should be true if you want to provision Transit Gateway"
  type        = bool
  default     = false
}

# =============================================================================
# TAGGING
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
