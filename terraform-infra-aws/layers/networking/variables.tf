# Variable definitions for AWS Networking Layer
# Author: Diego A. Zarate

# Project Configuration Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "Diego A. Zarate"
}

variable "cost_center" {
  description = "Cost center for billing and chargeback"
  type        = string
  default     = "Engineering"
}

# AWS Configuration Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "AWS region must be in the format 'us-east-1'."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified for high availability."
  }
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

# VPC Configuration Variables
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid CIDR notation."
  }
}

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
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for the VPC"
  type        = bool
  default     = false
}

variable "enable_dhcp_options" {
  description = "Enable custom DHCP options"
  type        = bool
  default     = true
}

# Subnet Configuration Variables
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets must be specified for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets must be specified for high availability."
  }
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
  validation {
    condition     = length(var.database_subnet_cidrs) >= 2
    error_message = "At least 2 database subnets must be specified for RDS Multi-AZ."
  }
}

variable "management_subnet_cidrs" {
  description = "List of CIDR blocks for management subnets"
  type        = list(string)
  default     = []
}

variable "cache_subnet_cidrs" {
  description = "List of CIDR blocks for cache subnets"
  type        = list(string)
  default     = []
}

# Internet Gateway Configuration
variable "create_igw" {
  description = "Create Internet Gateway for the VPC"
  type        = bool
  default     = true
}

# NAT Gateway Configuration
variable "nat_gateway_configuration" {
  description = "NAT Gateway configuration options"
  type = object({
    enable_nat_gateway     = bool
    single_nat_gateway     = bool
    one_nat_gateway_per_az = bool
    reuse_nat_ips         = bool
    external_nat_ip_ids   = list(string)
  })
  default = {
    enable_nat_gateway     = true
    single_nat_gateway     = false
    one_nat_gateway_per_az = true
    reuse_nat_ips         = false
    external_nat_ip_ids   = []
  }
}

# VPC Endpoints Configuration
variable "vpc_endpoints" {
  description = "Map of VPC endpoints to create"
  type = map(object({
    enabled = bool
    type    = string
    policy  = string
  }))
  default = {}
}

# Security Groups Configuration
variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    description = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  }))
  default = {}
}

# Network ACLs Configuration
variable "network_acls" {
  description = "Map of Network ACLs to create"
  type = map(object({
    subnet_ids = list(string)
    ingress_rules = list(object({
      rule_number = number
      protocol    = string
      rule_action = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    }))
    egress_rules = list(object({
      rule_number = number
      protocol    = string
      rule_action = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    }))
  }))
  default = {}
}

# Flow Logs Configuration
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_configuration" {
  description = "VPC Flow Logs configuration"
  type = object({
    log_destination_type = string
    log_destination     = string
    traffic_type        = string
    log_format          = string
  })
  default = {
    log_destination_type = "cloud-watch-logs"
    log_destination     = ""
    traffic_type        = "ALL"
    log_format          = null
  }
}

# Transit Gateway Configuration
variable "transit_gateway" {
  description = "Transit Gateway configuration"
  type = object({
    enabled                         = bool
    amazon_side_asn                = number
    auto_accept_shared_attachments = string
    auto_accept_shared_associations = string
    default_route_table_association = string
    default_route_table_propagation = string
    description                     = string
    dns_support                     = string
    vpn_ecmp_support               = string
  })
  default = {
    enabled                         = false
    amazon_side_asn                = 64512
    auto_accept_shared_attachments = "disable"
    auto_accept_shared_associations = "disable"
    default_route_table_association = "enable"
    default_route_table_propagation = "enable"
    description                     = ""
    dns_support                     = "enable"
    vpn_ecmp_support               = "enable"
  }
}

# Tagging Variables
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Monitoring Configuration
variable "monitoring" {
  description = "Monitoring and alerting configuration"
  type = object({
    enabled                   = bool
    cloudwatch_log_group      = string
    log_retention_days        = number
    enable_detailed_monitoring = bool
    enable_enhanced_monitoring = bool
    alarms = object({
      high_network_utilization = object({
        enabled   = bool
        threshold = number
      })
      unusual_traffic_patterns = object({
        enabled   = bool
        threshold = number
      })
      nat_gateway_errors = object({
        enabled   = bool
        threshold = number
      })
    })
  })
  default = {
    enabled                   = true
    cloudwatch_log_group      = ""
    log_retention_days        = 14
    enable_detailed_monitoring = false
    enable_enhanced_monitoring = false
    alarms = {
      high_network_utilization = {
        enabled   = false
        threshold = 80
      }
      unusual_traffic_patterns = {
        enabled   = false
        threshold = 5
      }
      nat_gateway_errors = {
        enabled   = false
        threshold = 10
      }
    }
  }
}

# Security Configuration
variable "security_configuration" {
  description = "Security and compliance configuration"
  type = object({
    enable_guardduty              = bool
    enable_security_hub           = bool
    enable_config                 = bool
    enable_cloudtrail            = bool
    enable_waf                   = bool
    enable_ddos_protection       = bool
    enable_network_firewall      = bool
    enable_encryption_in_transit = bool
    enable_encryption_at_rest    = bool
    require_mfa                  = bool
    enable_vpc_flow_logs         = bool
    enable_dns_query_logging     = bool
  })
  default = {
    enable_guardduty              = false
    enable_security_hub           = false
    enable_config                 = false
    enable_cloudtrail            = false
    enable_waf                   = false
    enable_ddos_protection       = false
    enable_network_firewall      = false
    enable_encryption_in_transit = true
    enable_encryption_at_rest    = true
    require_mfa                  = false
    enable_vpc_flow_logs         = true
    enable_dns_query_logging     = false
  }
}

# High Availability and Disaster Recovery
variable "ha_dr_configuration" {
  description = "High availability and disaster recovery configuration"
  type = object({
    multi_az_deployment = bool
    cross_region_backup = bool
    automated_failover  = bool
    rto_minutes        = number
    rpo_minutes        = number
  })
  default = {
    multi_az_deployment = true
    cross_region_backup = false
    automated_failover  = false
    rto_minutes        = 60
    rpo_minutes        = 15
  }
}

# Performance Configuration
variable "performance_configuration" {
  description = "Performance and scaling configuration"
  type = object({
    enable_enhanced_networking = bool
    enable_sr_iov             = bool
    enable_placement_groups    = bool
    dedicated_tenancy         = bool
    enhanced_networking       = bool
    enable_auto_scaling_nat   = bool
    enable_elastic_ips        = bool
  })
  default = {
    enable_enhanced_networking = false
    enable_sr_iov             = false
    enable_placement_groups    = false
    dedicated_tenancy         = false
    enhanced_networking       = false
    enable_auto_scaling_nat   = false
    enable_elastic_ips        = true
  }
}

# Cost Optimization
variable "cost_optimization" {
  description = "Cost optimization settings"
  type = object({
    use_reserved_instances        = bool
    enable_scheduled_scaling      = bool
    delete_unused_resources       = bool
    use_graviton_instances       = bool
    optimize_data_transfer       = bool
    use_vpc_endpoints            = bool
    optimize_nat_gateway_usage   = bool
  })
  default = {
    use_reserved_instances        = false
    enable_scheduled_scaling      = false
    delete_unused_resources       = true
    use_graviton_instances       = false
    optimize_data_transfer       = false
    use_vpc_endpoints            = true
    optimize_nat_gateway_usage   = false
  }
}

# Environment-specific configurations
variable "qa_configuration" {
  description = "QA environment specific configuration"
  type = object({
    enable_load_testing_rules    = bool
    allow_performance_testing    = bool
    enable_chaos_engineering     = bool
    automated_testing_enabled    = bool
  })
  default = {
    enable_load_testing_rules    = false
    allow_performance_testing    = false
    enable_chaos_engineering     = false
    automated_testing_enabled    = false
  }
}

variable "uat_configuration" {
  description = "UAT environment specific configuration"
  type = object({
    enable_user_testing_access   = bool
    allow_external_stakeholders  = bool
    enable_performance_monitoring = bool
    automated_testing_enabled    = bool
    load_testing_enabled         = bool
  })
  default = {
    enable_user_testing_access   = false
    allow_external_stakeholders  = false
    enable_performance_monitoring = false
    automated_testing_enabled    = false
    load_testing_enabled         = false
  }
}