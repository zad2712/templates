#####################################################################################################
# Fetch Data Module - Local Values Configuration
# Computed values for remote state access and dynamic configurations
#####################################################################################################

locals {
  #####################################################################################################
  # Environment and Region Resolution
  #####################################################################################################
  
  # Use provided region or fallback to current AWS region
  resolved_aws_region = var.aws_region != null ? var.aws_region : data.aws_region.current.name
  
  # Use provided state bucket region or fallback to resolved AWS region
  resolved_state_bucket_region = var.state_bucket_region != null ? var.state_bucket_region : local.resolved_aws_region

  # Common name prefix for consistent resource identification
  effective_name_prefix = var.name_prefix != "" ? var.name_prefix : ""

  #####################################################################################################
  # State Key Path Construction
  #####################################################################################################
  
  # Base state key structure with flexible workspace handling
  base_state_key_format = var.use_workspace_in_state_key ? "${var.state_key_prefix}/${var.environment}/%s/terraform.tfstate" : "${var.state_key_prefix}/%s/terraform.tfstate"
  
  # Computed state keys for each layer
  core_state_key = var.core_layer_config.state_key != null ? var.core_layer_config.state_key : format(local.base_state_key_format, "core")
  backend_state_key = var.backend_layer_config.state_key != null ? var.backend_layer_config.state_key : format(local.base_state_key_format, "backend")
  frontend_state_key = var.frontend_layer_config.state_key != null ? var.frontend_layer_config.state_key : format(local.base_state_key_format, "frontend")
  data_state_key = var.data_layer_config.state_key != null ? var.data_layer_config.state_key : format(local.base_state_key_format, "data")

  #####################################################################################################
  # Workspace Configuration
  #####################################################################################################
  
  # Workspace resolution for each layer
  core_workspace = var.core_layer_config.workspace != null ? var.core_layer_config.workspace : var.environment
  backend_workspace = var.backend_layer_config.workspace != null ? var.backend_layer_config.workspace : var.environment
  frontend_workspace = var.frontend_layer_config.workspace != null ? var.frontend_layer_config.workspace : var.environment
  data_workspace = var.data_layer_config.workspace != null ? var.data_layer_config.workspace : var.environment

  #####################################################################################################
  # Module Enablement Logic
  #####################################################################################################
  
  # Combined enablement logic - both global flag and specific config must be true
  core_enabled = var.fetch_vpc_module && var.core_layer_config.enabled
  backend_enabled = var.fetch_backend_module && var.backend_layer_config.enabled
  frontend_enabled = var.fetch_frontend_module && var.frontend_layer_config.enabled
  data_enabled = var.fetch_data_module && var.data_layer_config.enabled

  # List of enabled modules for conditional processing
  enabled_modules = compact([
    local.core_enabled ? "core" : "",
    local.backend_enabled ? "backend" : "",
    local.frontend_enabled ? "frontend" : "",
    local.data_enabled ? "data" : ""
  ])

  #####################################################################################################
  # Common Remote State Configuration
  #####################################################################################################
  
  # Base backend configuration for all remote state data sources
  common_backend_config = {
    bucket = var.terraform_state_bucket
    region = local.resolved_state_bucket_region
    encrypt = true
    
    # Optional configurations
    dynamodb_table = var.state_lock_table
    kms_key_id = var.kms_key_id
    
    # Cross-account access configuration
    assume_role_policy = var.assume_role_arn != null ? jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Resource = var.assume_role_arn
        }
      ]
    }) : null
  }

  #####################################################################################################
  # Output Processing Configuration
  #####################################################################################################
  
  # Metadata generation for outputs
  output_metadata = var.include_metadata ? {
    generated_at = timestamp()
    environment = var.environment
    source_region = local.resolved_aws_region
    state_bucket = var.terraform_state_bucket
    state_bucket_region = local.resolved_state_bucket_region
    enabled_modules = local.enabled_modules
    terraform_version = ">=1.13.0"
    module_version = "1.0.0"
  } : {}

  # Output sensitivity configuration
  mark_outputs_sensitive = var.sensitive_outputs

  #####################################################################################################
  # Validation and Helper Functions
  #####################################################################################################
  
  # Validation flags for configuration consistency
  valid_configuration = alltrue([
    # At least one module must be enabled
    length(local.enabled_modules) > 0,
    
    # State bucket must be provided
    var.terraform_state_bucket != "",
    
    # Environment must be valid
    contains(["dev", "qa", "uat", "prod"], var.environment)
  ])

  # Error messages for validation failures
  validation_errors = compact([
    length(local.enabled_modules) == 0 ? "At least one module must be enabled for fetching data" : "",
    var.terraform_state_bucket == "" ? "Terraform state bucket must be provided" : "",
    !contains(["dev", "qa", "uat", "prod"], var.environment) ? "Environment must be one of: dev, qa, uat, prod" : ""
  ])

  #####################################################################################################
  # Advanced Configuration Options
  #####################################################################################################
  
  # Retry configuration for remote state access
  retry_config = {
    max_retries = var.retry_attempts
    retry_delay = "5s"
    timeout = "30s"
  }

  # Performance optimization flags
  performance_config = {
    cache_remote_state = true
    parallel_fetch = length(local.enabled_modules) > 1
    use_etag_validation = true
  }

  #####################################################################################################
  # Future Extensibility Placeholders
  #####################################################################################################
  
  # Reserved for future module types
  future_modules = {
    monitoring = false
    security = false
    logging = false
    networking = false
  }

  # Configuration templates for new modules
  module_config_template = {
    enabled = false
    state_key = null
    workspace = null
    specific_outputs = null
  }
}

#####################################################################################################
# Data Sources for Context Information
#####################################################################################################

# Current AWS region for fallback
data "aws_region" "current" {}

# Current AWS caller identity for validation
data "aws_caller_identity" "current" {}

# Current AWS partition for ARN construction
data "aws_partition" "current" {}