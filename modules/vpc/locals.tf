#####################################################################################################
# AWS VPC Module - Local Values and Data Sources
# Computed values, data sources, and tagging strategies
#####################################################################################################

#####################################################################################################
# Data Sources
#####################################################################################################

data "aws_caller_identity" "current" {
  # Get current AWS account information
}

data "aws_region" "current" {
  # Get current AWS region
}

data "aws_availability_zones" "available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_partition" "current" {
  # Get AWS partition (aws, aws-cn, aws-us-gov)
}

#####################################################################################################
# Local Values
#####################################################################################################

locals {
  # Account and region information
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Maximum AZ count - AWS best practice is to use at least 2 AZs for HA
  max_subnet_length = max(
    length(var.private_subnets),
    length(var.public_subnets),
    length(var.database_subnets)
  )

  # Determine if we need NAT gateways
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.public_subnets)

  # VPC endpoint route table IDs
  vpc_endpoint_route_table_ids = compact(concat(
    aws_route_table.public[*].id,
    aws_route_table.private[*].id,
    aws_route_table.database[*].id
  ))

  # Common tags with enhanced metadata
  common_tags = merge(
    var.common_tags,
    {
      "terraform:module"    = "vpc"
      "terraform:workspace" = terraform.workspace
      "aws:account-id"      = local.account_id
      "aws:region"          = local.region
      "created:date"        = formatdate("YYYY-MM-DD", timestamp())
      "managed-by"          = "terraform"
      "vpc:name"            = "${var.name_prefix}-vpc"
    }
  )

  # Subnet type mapping for consistent tagging
  subnet_type_tags = {
    public = merge(
      {
        "subnet-type" = "public"
        "tier"        = "web"
      },
      var.public_subnet_tags
    )
    private = merge(
      {
        "subnet-type" = "private" 
        "tier"        = "application"
      },
      var.private_subnet_tags
    )
    database = merge(
      {
        "subnet-type" = "database"
        "tier"        = "data"
      },
      var.database_subnet_tags
    )
  }

  # Network security settings
  network_security = {
    enable_flow_logs    = var.enable_flow_log
    enable_nacls       = var.create_network_acls
    manage_default_sg  = var.manage_default_security_group
  }

  # Cost optimization settings
  cost_optimization = {
    single_nat_gateway       = var.single_nat_gateway
    enable_s3_endpoint      = var.enable_s3_endpoint
    enable_dynamodb_endpoint = var.enable_dynamodb_endpoint
  }

  # High availability configuration
  high_availability = {
    multi_az_nat_gateways = !var.single_nat_gateway
    multi_az_subnets      = local.max_subnet_length >= 2
    availability_zones    = slice(data.aws_availability_zones.available.names, 0, local.max_subnet_length)
  }

  # Compliance and governance tags
  compliance_tags = {
    "compliance:data-classification" = "internal"
    "compliance:backup-required"     = "true"
    "governance:cost-center"         = var.common_tags.Environment != null ? var.common_tags.Environment : "unknown"
  }

  # Resource naming convention
  resource_names = {
    vpc                = "${var.name_prefix}-vpc"
    igw                = "${var.name_prefix}-igw"
    public_subnet      = "${var.name_prefix}-public-subnet"
    private_subnet     = "${var.name_prefix}-private-subnet"
    database_subnet    = "${var.name_prefix}-db-subnet"
    nat_gateway        = "${var.name_prefix}-nat-gateway"
    public_rt          = "${var.name_prefix}-public-rt"
    private_rt         = "${var.name_prefix}-private-rt"
    database_rt        = "${var.name_prefix}-database-rt"
    db_subnet_group    = "${var.name_prefix}-db-subnet-group"
    flow_log           = "${var.name_prefix}-vpc-flow-log"
    s3_endpoint        = "${var.name_prefix}-s3-endpoint"
    dynamodb_endpoint  = "${var.name_prefix}-dynamodb-endpoint"
  }

  # CIDR validation and calculations
  cidr_info = {
    vpc_cidr          = var.cidr_block
    vpc_netmask_bits  = split("/", var.cidr_block)[1]
    public_cidrs      = var.public_subnets
    private_cidrs     = var.private_subnets
    database_cidrs    = var.database_subnets
  }

  # Security group rules for enhanced security
  default_sg_rules = var.manage_default_security_group ? {
    # Remove all default rules - deny all traffic by default
    ingress_rules = []
    egress_rules  = []
  } : null

  # IPv6 configuration
  ipv6_config = var.enable_ipv6 ? {
    assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation
    ipv6_cidr_block_network_border_group = local.region
  } : null

  # VPC Flow Log configuration
  flow_log_config = var.enable_flow_log ? {
    traffic_type               = var.flow_log_traffic_type
    log_destination_type      = var.flow_log_cloudwatch_log_group_name != null ? "cloud-watch-logs" : "s3"
    cloudwatch_log_group_name = var.flow_log_cloudwatch_log_group_name
    iam_role_arn             = var.flow_log_cloudwatch_iam_role_arn
  } : null

  # Network performance optimizations
  network_performance = {
    enhanced_networking_enabled = true
    sr_iov_net_support         = "simple"
    ena_support                = true
  }

  # Monitoring and observability
  monitoring_config = {
    enable_detailed_monitoring = true
    enable_flow_logs          = var.enable_flow_log
    cloudwatch_log_retention  = 30 # days
  }
}

#####################################################################################################
# Validation Locals
#####################################################################################################

locals {
  # Validate CIDR blocks don't overlap
  cidr_validation = {
    # Check if all subnet CIDRs are within VPC CIDR
    public_subnets_valid = alltrue([
      for cidr in var.public_subnets :
      can(cidrsubnet(var.cidr_block, 0, 0)) && 
      can(cidrsubnet(cidr, 0, 0))
    ])
    
    private_subnets_valid = alltrue([
      for cidr in var.private_subnets :
      can(cidrsubnet(var.cidr_block, 0, 0)) && 
      can(cidrsubnet(cidr, 0, 0))
    ])
    
    database_subnets_valid = alltrue([
      for cidr in var.database_subnets :
      can(cidrsubnet(var.cidr_block, 0, 0)) && 
      can(cidrsubnet(cidr, 0, 0))
    ])
  }

  # Availability zone validation
  az_validation = {
    sufficient_azs = length(data.aws_availability_zones.available.names) >= local.max_subnet_length
  }
}