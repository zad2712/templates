# Core Layer - Local Variables

locals {
  # Common tags applied to all resources
  common_tags = {
    Environment   = var.environment
    Layer        = "core"
    Project      = var.project_name
    ManagedBy    = "terraform"
    Region       = var.aws_region
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }

  # Environment-specific configurations
  environment_config = {
    dev = {
      enable_flow_log    = false
      create_network_acls = false
      single_nat_gateway = true
    }
    qa = {
      enable_flow_log    = false
      create_network_acls = false
      single_nat_gateway = true
    }
    uat = {
      enable_flow_log    = true
      create_network_acls = false
      single_nat_gateway = false
    }
    prod = {
      enable_flow_log    = true
      create_network_acls = true
      single_nat_gateway = false
    }
  }

  # Get current environment configuration
  current_env_config = lookup(local.environment_config, var.environment, local.environment_config.dev)
}