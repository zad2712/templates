# Local values for AWS Networking Layer
# Author: Diego A. Zarate

locals {
  # Environment-specific naming
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags merged with additional metadata
  common_tags = merge(var.common_tags, {
    Name        = "${local.name_prefix}-networking"
    Layer       = "networking"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    LastUpdated = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  })
  
  # Availability zones calculation
  azs = slice(var.availability_zones, 0, min(length(var.availability_zones), 3))
  az_count = length(local.azs)
  
  # Subnet calculations
  public_subnets = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
  database_subnets = var.database_subnet_cidrs
  
  # Management and cache subnets (optional)
  management_subnets = length(var.management_subnet_cidrs) > 0 ? var.management_subnet_cidrs : []
  cache_subnets = length(var.cache_subnet_cidrs) > 0 ? var.cache_subnet_cidrs : []
  
  # NAT Gateway configuration
  nat_gateway_count = var.nat_gateway_configuration.single_nat_gateway ? 1 : (
    var.nat_gateway_configuration.one_nat_gateway_per_az ? local.az_count : 1
  )
  
  # VPC Endpoints that should be created
  vpc_endpoints_to_create = {
    for name, config in var.vpc_endpoints : name => config
    if config.enabled
  }
  
  # Security groups to create
  security_groups_to_create = {
    for name, config in var.security_groups : name => config
    if length(config.ingress_rules) > 0 || length(config.egress_rules) > 0
  }
  
  # Flow logs configuration
  flow_logs_log_group_name = var.flow_logs_configuration.log_destination_type == "cloud-watch-logs" ? (
    var.flow_logs_configuration.log_destination != "" ? 
    var.flow_logs_configuration.log_destination : 
    "/aws/vpc/flowlogs/${var.environment}"
  ) : null
  
  # Environment-specific configurations
  is_production = var.environment == "prod"
  is_development = var.environment == "dev"
  is_testing = contains(["qa", "uat"], var.environment)
  
  # Cost optimization flags
  enable_single_nat = var.cost_optimization.optimize_nat_gateway_usage || local.is_development
  enable_vpc_endpoints = var.cost_optimization.use_vpc_endpoints
  
  # Security configurations based on environment
  security_level = local.is_production ? "high" : (local.is_testing ? "medium" : "basic")
  
  # Monitoring configuration
  monitoring_enabled = var.monitoring.enabled
  detailed_monitoring = var.monitoring.enable_detailed_monitoring || local.is_production
  
  # DHCP options
  dhcp_options_domain_name = var.aws_region == "us-east-1" ? "ec2.internal" : "${var.aws_region}.compute.internal"
  
  # Transit Gateway configuration
  create_transit_gateway = var.transit_gateway.enabled && (local.is_production || local.is_testing)
  
  # Route table associations
  public_route_table_associations = {
    for i, subnet in aws_subnet.public : i => {
      subnet_id      = subnet.id
      route_table_id = aws_route_table.public[0].id
    }
  }
  
  private_route_table_associations = {
    for i, subnet in aws_subnet.private : i => {
      subnet_id = subnet.id
      route_table_id = var.nat_gateway_configuration.single_nat_gateway ? 
        aws_route_table.private[0].id : 
        aws_route_table.private[i % local.nat_gateway_count].id
    }
  }
  
  # Network ACL subnet associations
  public_nacl_associations = {
    for i, subnet in aws_subnet.public : "public-${i}" => {
      network_acl_id = aws_network_acl.public[0].id
      subnet_id      = subnet.id
    }
  }
  
  private_nacl_associations = {
    for i, subnet in aws_subnet.private : "private-${i}" => {
      network_acl_id = aws_network_acl.private[0].id
      subnet_id      = subnet.id
    }
  }
  
  database_nacl_associations = {
    for i, subnet in aws_subnet.database : "database-${i}" => {
      network_acl_id = try(aws_network_acl.database[0].id, aws_network_acl.private[0].id)
      subnet_id      = subnet.id
    }
  }
}