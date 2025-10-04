# =============================================================================
# COMPUTE LAYER - AKS, Function Apps, App Services, and Compute Services
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {}
}

# Configure Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Layer       = "compute"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Naming convention
  resource_group_name = "${var.project_name}-${var.environment}-compute-rg"
  
  # Data from other layers
  security_rg_outputs   = data.terraform_remote_state.security.outputs
  networking_rg_outputs = data.terraform_remote_state.networking.outputs
  data_rg_outputs      = data.terraform_remote_state.data.outputs
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Security layer outputs
data "terraform_remote_state" "security" {
  backend = "azurerm"
  config = {
    resource_group_name  = "${var.project_name}-terraform-state-${var.environment}"
    storage_account_name = "${var.project_name}tfstate${var.environment}"
    container_name       = "tfstate"
    key                 = "security/${var.environment}/terraform.tfstate"
  }
}

# Networking layer outputs
data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = "${var.project_name}-terraform-state-${var.environment}"
    storage_account_name = "${var.project_name}tfstate${var.environment}"
    container_name       = "tfstate"
    key                 = "networking/${var.environment}/terraform.tfstate"
  }
}

# Data layer outputs
data "terraform_remote_state" "data" {
  backend = "azurerm"
  config = {
    resource_group_name  = "${var.project_name}-terraform-state-${var.environment}"
    storage_account_name = "${var.project_name}tfstate${var.environment}"
    container_name       = "tfstate"
    key                 = "data/${var.environment}/terraform.tfstate"
  }
}

# =============================================================================
# RESOURCE GROUP
# =============================================================================

module "resource_group" {
  source = "../../modules/resource-group"

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# AZURE KUBERNETES SERVICE (AKS)
# =============================================================================

module "aks_cluster" {
  for_each = var.aks_clusters

  source = "../../modules/aks"

  # Basic Configuration
  cluster_name        = "${var.project_name}-${var.environment}-${each.key}-aks"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Kubernetes Configuration
  kubernetes_version    = each.value.kubernetes_version
  sku_tier             = each.value.sku_tier
  private_cluster      = each.value.private_cluster
  local_account_disabled = each.value.local_account_disabled

  # Node Pool Configuration
  node_pools = each.value.node_pools

  # Network Configuration
  network_profile = {
    network_plugin      = each.value.network_plugin
    network_policy      = each.value.network_policy
    dns_service_ip      = each.value.dns_service_ip
    service_cidr        = each.value.service_cidr
    pod_cidr           = each.value.pod_cidr
  }

  vnet_subnet_id = local.networking_rg_outputs.aks_subnet_id

  # Identity Configuration
  identity_type = "UserAssigned"
  identity_ids  = [local.security_rg_outputs.managed_identity_ids["aks"]]

  # Azure AD Integration
  enable_azure_rbac                = true
  azure_rbac_admin_group_object_ids = each.value.azure_rbac_admin_group_object_ids

  # Add-ons Configuration
  ingress_application_gateway = each.value.enable_application_gateway ? {
    enabled    = true
    gateway_id = local.networking_rg_outputs.application_gateway_id
  } : null

  oms_agent = var.enable_monitoring ? {
    enabled                    = true
    log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id
  } : null

  azure_policy = {
    enabled = each.value.enable_azure_policy
  }

  key_vault_secrets_provider = {
    enabled                  = true
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Security Configuration
  enable_pod_security_policy = each.value.enable_pod_security_policy
  enable_workload_identity   = each.value.enable_workload_identity

  # Auto Scaler Configuration
  auto_scaler_profile = each.value.auto_scaler_profile

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE FUNCTION APPS
# =============================================================================

module "function_app" {
  for_each = var.function_apps

  source = "../../modules/function-app"

  # Basic Configuration
  function_app_name        = "${var.project_name}-${var.environment}-${each.key}-func"
  resource_group_name      = module.resource_group.name
  location                = var.location

  # App Service Plan
  app_service_plan_name = "${var.project_name}-${var.environment}-${each.key}-plan"
  os_type              = each.value.os_type
  sku_name             = each.value.sku_name
  worker_count         = each.value.worker_count

  # Storage Configuration
  storage_account_name = "${var.project_name}${var.environment}${each.key}funcst"

  # Network Configuration
  subnet_id                   = local.networking_rg_outputs.function_apps_subnet_id
  enable_private_endpoint     = var.enable_private_endpoints
  private_endpoint_subnet_id  = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id        = local.networking_rg_outputs.private_dns_zone_ids["privatelink.azurewebsites.net"]

  # Identity Configuration
  identity_type = "UserAssigned"
  identity_ids  = [local.security_rg_outputs.managed_identity_ids["function-app"]]

  # Application Configuration
  application_stack = each.value.application_stack
  app_settings     = merge(each.value.app_settings, {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.enable_monitoring ? local.security_rg_outputs.application_insights_connection_string : ""
    "FUNCTIONS_WORKER_RUNTIME"             = each.value.runtime
    "WEBSITE_RUN_FROM_PACKAGE"             = "1"
  })

  # Security Configuration
  https_only                     = true
  client_certificate_enabled    = each.value.client_certificate_enabled
  key_vault_reference_identity_id = local.security_rg_outputs.managed_identity_ids["function-app"]

  # Monitoring Configuration
  enable_application_insights    = var.enable_monitoring
  application_insights_name      = "${var.project_name}-${var.environment}-${each.key}-ai"
  log_analytics_workspace_id     = local.security_rg_outputs.log_analytics_workspace_id

  # Deployment Slot
  enable_staging_slot = each.value.enable_staging_slot

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE APP SERVICES
# =============================================================================

module "app_service" {
  for_each = var.app_services

  source = "../../modules/app-service"

  # Basic Configuration
  app_service_name         = "${var.project_name}-${var.environment}-${each.key}-app"
  resource_group_name      = module.resource_group.name
  location                = var.location

  # App Service Plan
  app_service_plan_name = "${var.project_name}-${var.environment}-${each.key}-plan"
  os_type              = each.value.os_type
  sku_name             = each.value.sku_name
  worker_count         = each.value.worker_count

  # Network Configuration
  subnet_id                   = local.networking_rg_outputs.app_services_subnet_id
  enable_private_endpoint     = var.enable_private_endpoints
  private_endpoint_subnet_id  = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id        = local.networking_rg_outputs.private_dns_zone_ids["privatelink.azurewebsites.net"]

  # Identity Configuration
  identity_type = "UserAssigned"
  identity_ids  = [local.security_rg_outputs.managed_identity_ids["app-service"]]

  # Application Configuration
  application_stack = each.value.application_stack
  app_settings     = merge(each.value.app_settings, {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.enable_monitoring ? local.security_rg_outputs.application_insights_connection_string : ""
  })

  # Connection Strings
  connection_strings = each.value.connection_strings

  # Security Configuration
  https_only                     = true
  client_certificate_enabled    = each.value.client_certificate_enabled
  key_vault_reference_identity_id = local.security_rg_outputs.managed_identity_ids["app-service"]

  # Site Configuration
  always_on              = each.value.always_on
  health_check_path      = each.value.health_check_path
  auto_heal_enabled      = each.value.auto_heal_enabled
  auto_heal_setting      = each.value.auto_heal_setting

  # Deployment Slot
  enable_staging_slot = each.value.enable_staging_slot

  # Diagnostic Settings
  enable_diagnostic_settings  = var.enable_diagnostic_settings
  log_analytics_workspace_id  = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE CONTAINER INSTANCES
# =============================================================================

module "container_instance" {
  for_each = var.container_instances

  source = "../../modules/container-instance"

  # Basic Configuration
  container_group_name = "${var.project_name}-${var.environment}-${each.key}-ci"
  resource_group_name  = module.resource_group.name
  location            = var.location

  # Container Configuration
  containers = each.value.containers

  # Network Configuration
  subnet_ids = [local.networking_rg_outputs.container_instances_subnet_id]

  # Identity Configuration
  identity_type = "UserAssigned"
  identity_ids  = [local.security_rg_outputs.managed_identity_ids["container-instance"]]

  # Security Configuration
  os_type = each.value.os_type
  
  # Volume Configuration
  volumes = each.value.volumes

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE VIRTUAL MACHINES (if required)
# =============================================================================

module "virtual_machine" {
  for_each = var.virtual_machines

  source = "../../modules/virtual-machine"

  # Basic Configuration
  vm_name             = "${var.project_name}-${var.environment}-${each.key}-vm"
  resource_group_name = module.resource_group.name
  location           = var.location

  # VM Configuration
  vm_size                = each.value.vm_size
  admin_username         = each.value.admin_username
  disable_password_authentication = each.value.disable_password_authentication
  admin_ssh_key         = each.value.admin_ssh_key

  # OS Configuration
  os_disk_caching      = each.value.os_disk_caching
  os_disk_storage_account_type = each.value.os_disk_storage_account_type
  
  source_image_reference = each.value.source_image_reference

  # Network Configuration
  subnet_id             = local.networking_rg_outputs.vm_subnet_id
  public_ip_enabled     = each.value.public_ip_enabled
  enable_accelerated_networking = each.value.enable_accelerated_networking

  # Security Configuration
  identity_type = "UserAssigned"
  identity_ids  = [local.security_rg_outputs.managed_identity_ids["virtual-machine"]]

  # Disk Configuration
  data_disks = each.value.data_disks

  # Availability Configuration
  availability_zone = each.value.availability_zone
  
  # Extensions
  extensions = each.value.extensions

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE BATCH ACCOUNT
# =============================================================================

module "batch_account" {
  for_each = var.batch_accounts

  source = "../../modules/batch-account"

  # Basic Configuration
  batch_account_name  = "${var.project_name}${var.environment}${each.key}batch"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Pool Allocation Mode
  pool_allocation_mode = each.value.pool_allocation_mode

  # Storage Configuration
  storage_account_id            = each.value.storage_account_id
  storage_account_authentication_mode = each.value.storage_account_authentication_mode

  # Identity Configuration
  identity_type = "UserAssigned"
  identity_ids  = [local.security_rg_outputs.managed_identity_ids["batch"]]

  # Network Configuration
  public_network_access_enabled = !var.enable_private_endpoints

  # Key Vault Configuration
  key_vault_reference = {
    id  = local.security_rg_outputs.key_vault_id
    url = local.security_rg_outputs.key_vault_uri
  }

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# LOAD BALANCER (if required)
# =============================================================================

module "load_balancer" {
  for_each = var.load_balancers

  source = "../../modules/load-balancer"

  # Basic Configuration
  load_balancer_name  = "${var.project_name}-${var.environment}-${each.key}-lb"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Load Balancer Configuration
  type = each.value.type
  sku  = each.value.sku

  # Frontend Configuration
  frontend_ip_configurations = each.value.frontend_ip_configurations

  # Backend Configuration
  backend_address_pools = each.value.backend_address_pools

  # Probe Configuration
  health_probes = each.value.health_probes

  # Load Balancing Rules
  load_balancing_rules = each.value.load_balancing_rules

  # NAT Rules
  nat_rules = each.value.nat_rules

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# ROLE ASSIGNMENTS FOR COMPUTE RESOURCES
# =============================================================================

# AKS Cluster Role Assignments
resource "azurerm_role_assignment" "aks_network_contributor" {
  for_each = var.aks_clusters

  scope                = local.networking_rg_outputs.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = local.security_rg_outputs.managed_identity_principal_ids["aks"]
}

# Function App Role Assignments
resource "azurerm_role_assignment" "function_app_key_vault_secrets_user" {
  for_each = var.function_apps

  scope                = local.security_rg_outputs.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.security_rg_outputs.managed_identity_principal_ids["function-app"]
}

# App Service Role Assignments
resource "azurerm_role_assignment" "app_service_key_vault_secrets_user" {
  for_each = var.app_services

  scope                = local.security_rg_outputs.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.security_rg_outputs.managed_identity_principal_ids["app-service"]
}