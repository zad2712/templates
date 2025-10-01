#####################################################################################################
# Fetch Data Module - Main Configuration
# Remote state data sources for accessing infrastructure module outputs
#####################################################################################################

#####################################################################################################
# Validation Check
#####################################################################################################

# Ensure configuration is valid before proceeding
resource "null_resource" "configuration_validation" {
  count = local.valid_configuration ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'Configuration validation failed: ${join(", ", local.validation_errors)}' && exit 1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#####################################################################################################
# Core Layer Remote State (VPC Module)
#####################################################################################################

data "terraform_remote_state" "core" {
  count   = local.core_enabled ? 1 : 0
  backend = "s3"

  config = {
    # S3 Backend Configuration
    bucket = var.terraform_state_bucket
    key    = local.core_state_key
    region = local.resolved_state_bucket_region

    # Encryption Configuration
    encrypt = true
    kms_key_id = var.kms_key_id

    # State Locking Configuration
    dynamodb_table = var.state_lock_table

    # Cross-Account Access Configuration
    assume_role_arn = var.assume_role_arn

    # Workspace Configuration
    workspace_key_prefix = var.use_workspace_in_state_key ? "" : "env:"
  }

  # Workspace selection
  workspace = local.core_workspace
}

#####################################################################################################
# Backend Layer Remote State (Future Extensibility)
#####################################################################################################

data "terraform_remote_state" "backend" {
  count   = local.backend_enabled ? 1 : 0
  backend = "s3"

  config = {
    # S3 Backend Configuration
    bucket = var.terraform_state_bucket
    key    = local.backend_state_key
    region = local.resolved_state_bucket_region

    # Encryption Configuration
    encrypt = true
    kms_key_id = var.kms_key_id

    # State Locking Configuration
    dynamodb_table = var.state_lock_table

    # Cross-Account Access Configuration
    assume_role_arn = var.assume_role_arn

    # Workspace Configuration
    workspace_key_prefix = var.use_workspace_in_state_key ? "" : "env:"
  }

  # Workspace selection
  workspace = local.backend_workspace
}

#####################################################################################################
# Frontend Layer Remote State (Future Extensibility)
#####################################################################################################

data "terraform_remote_state" "frontend" {
  count   = local.frontend_enabled ? 1 : 0
  backend = "s3"

  config = {
    # S3 Backend Configuration
    bucket = var.terraform_state_bucket
    key    = local.frontend_state_key
    region = local.resolved_state_bucket_region

    # Encryption Configuration
    encrypt = true
    kms_key_id = var.kms_key_id

    # State Locking Configuration
    dynamodb_table = var.state_lock_table

    # Cross-Account Access Configuration
    assume_role_arn = var.assume_role_arn

    # Workspace Configuration
    workspace_key_prefix = var.use_workspace_in_state_key ? "" : "env:"
  }

  # Workspace selection
  workspace = local.frontend_workspace
}

#####################################################################################################
# Data Layer Remote State (Future Extensibility)
#####################################################################################################

data "terraform_remote_state" "data" {
  count   = local.data_enabled ? 1 : 0
  backend = "s3"

  config = {
    # S3 Backend Configuration
    bucket = var.terraform_state_bucket
    key    = local.data_state_key
    region = local.resolved_state_bucket_region

    # Encryption Configuration
    encrypt = true
    kms_key_id = var.kms_key_id

    # State Locking Configuration
    dynamodb_table = var.state_lock_table

    # Cross-Account Access Configuration
    assume_role_arn = var.assume_role_arn

    # Workspace Configuration
    workspace_key_prefix = var.use_workspace_in_state_key ? "" : "env:"
  }

  # Workspace selection
  workspace = local.data_workspace
}

#####################################################################################################
# Output Processing Logic
#####################################################################################################

locals {
  # Core layer (VPC) outputs processing
  core_outputs = local.core_enabled && length(data.terraform_remote_state.core) > 0 ? (
    var.core_layer_config.specific_outputs != null ? 
      { for k, v in data.terraform_remote_state.core[0].outputs : k => v if contains(var.core_layer_config.specific_outputs, k) } :
      data.terraform_remote_state.core[0].outputs
  ) : {}

  # Backend layer outputs processing
  backend_outputs = local.backend_enabled && length(data.terraform_remote_state.backend) > 0 ? (
    var.backend_layer_config.specific_outputs != null ?
      { for k, v in data.terraform_remote_state.backend[0].outputs : k => v if contains(var.backend_layer_config.specific_outputs, k) } :
      data.terraform_remote_state.backend[0].outputs
  ) : {}

  # Frontend layer outputs processing
  frontend_outputs = local.frontend_enabled && length(data.terraform_remote_state.frontend) > 0 ? (
    var.frontend_layer_config.specific_outputs != null ?
      { for k, v in data.terraform_remote_state.frontend[0].outputs : k => v if contains(var.frontend_layer_config.specific_outputs, k) } :
      data.terraform_remote_state.frontend[0].outputs
  ) : {}

  # Data layer outputs processing
  data_outputs = local.data_enabled && length(data.terraform_remote_state.data) > 0 ? (
    var.data_layer_config.specific_outputs != null ?
      { for k, v in data.terraform_remote_state.data[0].outputs : k => v if contains(var.data_layer_config.specific_outputs, k) } :
      data.terraform_remote_state.data[0].outputs
  ) : {}

  # Combined outputs based on format preference
  structured_outputs = {
    core     = local.core_outputs
    backend  = local.backend_outputs
    frontend = local.frontend_outputs
    data     = local.data_outputs
    metadata = local.output_metadata
  }

  flat_outputs = merge(
    { for k, v in local.core_outputs : "core_${k}" => v },
    { for k, v in local.backend_outputs : "backend_${k}" => v },
    { for k, v in local.frontend_outputs : "frontend_${k}" => v },
    { for k, v in local.data_outputs : "data_${k}" => v },
    var.include_metadata ? { metadata = local.output_metadata } : {}
  )

  raw_outputs = merge(
    local.core_outputs,
    local.backend_outputs,
    local.frontend_outputs,
    local.data_outputs
  )

  # Final output selection based on format
  final_outputs = var.output_format == "structured" ? local.structured_outputs : (
    var.output_format == "flat" ? local.flat_outputs : local.raw_outputs
  )
}

#####################################################################################################
# Health Check and Validation Resources
#####################################################################################################

# Health check for remote state accessibility
resource "null_resource" "remote_state_health_check" {
  count = length(local.enabled_modules) > 0 ? 1 : 0

  triggers = {
    enabled_modules = join(",", local.enabled_modules)
    state_bucket = var.terraform_state_bucket
    environment = var.environment
  }

  provisioner "local-exec" {
    command = "echo 'Successfully accessed remote state for modules: ${join(", ", local.enabled_modules)}'"
  }

  depends_on = [
    data.terraform_remote_state.core,
    data.terraform_remote_state.backend,
    data.terraform_remote_state.frontend,
    data.terraform_remote_state.data
  ]
}

# Configuration summary for debugging
locals {
  configuration_summary = {
    environment = var.environment
    enabled_modules = local.enabled_modules
    state_bucket = var.terraform_state_bucket
    state_bucket_region = local.resolved_state_bucket_region
    output_format = var.output_format
    include_metadata = var.include_metadata
    
    state_keys = {
      core = local.core_enabled ? local.core_state_key : "disabled"
      backend = local.backend_enabled ? local.backend_state_key : "disabled"  
      frontend = local.frontend_enabled ? local.frontend_state_key : "disabled"
      data = local.data_enabled ? local.data_state_key : "disabled"
    }
    
    workspaces = {
      core = local.core_enabled ? local.core_workspace : "disabled"
      backend = local.backend_enabled ? local.backend_workspace : "disabled"
      frontend = local.frontend_enabled ? local.frontend_workspace : "disabled"
      data = local.data_enabled ? local.data_workspace : "disabled"
    }
  }
}