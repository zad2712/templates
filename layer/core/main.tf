# Core Layer - Main Configuration

terraform {
  required_version = ">= 1.3.0"
}

#####################################################################################################
# VPC Module - Core Network Infrastructure
#####################################################################################################

module "vpc" {
  source = "../../modules/vpc"

  name_prefix = "${var.project_name}-${var.environment}"
  cidr_block  = var.vpc_cidr_block

  # Subnet configuration
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # Internet Gateway
  create_igw = var.create_igw
  map_public_ip_on_launch = var.map_public_ip_on_launch

  # Database configuration
  create_database_subnet_group = var.create_database_subnet_group
  create_database_route_table  = var.create_database_route_table

  # Security features
  enable_flow_log                    = var.enable_flow_log
  flow_log_traffic_type              = var.flow_log_traffic_type
  flow_log_cloudwatch_log_group_name = var.flow_log_cloudwatch_log_group_name
  flow_log_cloudwatch_iam_role_arn   = var.flow_log_cloudwatch_iam_role_arn
  manage_default_security_group      = var.manage_default_security_group
  create_network_acls                = var.create_network_acls

  # VPC Endpoints for cost optimization
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  # Advanced configuration
  secondary_cidr_blocks               = var.secondary_cidr_blocks
  enable_ipv6                        = var.enable_ipv6
  assign_ipv6_address_on_creation    = var.assign_ipv6_address_on_creation
  instance_tenancy                   = var.instance_tenancy

  # Comprehensive tagging
  common_tags = merge(local.common_tags, var.vpc_additional_tags)
  
  vpc_tags                   = var.vpc_tags
  public_subnet_tags         = var.public_subnet_tags
  private_subnet_tags        = var.private_subnet_tags
  database_subnet_tags       = var.database_subnet_tags
  public_route_table_tags    = var.public_route_table_tags
  private_route_table_tags   = var.private_route_table_tags
  database_route_table_tags  = var.database_route_table_tags
}