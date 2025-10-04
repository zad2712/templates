# =============================================================================
# SECURITY LAYER - RBAC, Key Vault, Managed Identity, and Security Services
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
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
    Layer       = "security"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Naming convention
  resource_group_name = "${var.project_name}-${var.environment}-security-rg"
  key_vault_name      = "${var.project_name}-${var.environment}-kv"
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

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
# LOG ANALYTICS WORKSPACE
# =============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-law"
  location            = var.location
  resource_group_name = module.resource_group.name
  sku                = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
  daily_quota_gb     = var.log_analytics_daily_quota_gb

  tags = local.common_tags
}

# =============================================================================
# KEY VAULT
# =============================================================================

module "key_vault" {
  source = "../../modules/key-vault"

  name                = local.key_vault_name
  resource_group_name = module.resource_group.name
  location            = var.location
  
  sku_name                     = var.key_vault_sku
  soft_delete_retention_days   = var.key_vault_soft_delete_retention_days
  purge_protection_enabled     = var.key_vault_purge_protection_enabled
  enable_rbac_authorization    = var.key_vault_enable_rbac_authorization
  public_network_access_enabled = var.key_vault_public_network_access_enabled

  # Network ACLs
  enable_network_acls = var.key_vault_enable_network_acls
  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.key_vault_allowed_ips
    virtual_network_subnet_ids = var.key_vault_allowed_subnets
  }

  # Private Endpoint
  enable_private_endpoint      = var.key_vault_enable_private_endpoint
  private_endpoint_subnet_id   = data.terraform_remote_state.networking.outputs.private_endpoints_subnet_id
  private_dns_zone_id         = data.terraform_remote_state.networking.outputs.private_dns_zone_ids["privatelink.vaultcore.azure.net"]

  # Diagnostic Settings
  enable_diagnostic_settings  = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.main.id
  diagnostic_settings = {
    enabled_logs = var.key_vault_diagnostic_logs
    metrics     = var.key_vault_diagnostic_metrics
  }

  # Secrets
  secrets = var.key_vault_secrets

  # Keys
  keys = var.key_vault_keys

  # Certificates
  certificates = var.key_vault_certificates

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# USER ASSIGNED MANAGED IDENTITIES
# =============================================================================

resource "azurerm_user_assigned_identity" "main" {
  for_each = var.managed_identities

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = merge(local.common_tags, each.value.tags)
}

# =============================================================================
# AZURE DEFENDER FOR CLOUD (SECURITY CENTER)
# =============================================================================

# Security Center Subscription Pricing
resource "azurerm_security_center_subscription_pricing" "main" {
  for_each = var.defender_for_cloud_plans

  tier          = each.value.tier
  resource_type = each.key
}

# Security Center Contact
resource "azurerm_security_center_contact" "main" {
  count = var.enable_security_center_contact ? 1 : 0

  email               = var.security_center_contact.email
  phone               = var.security_center_contact.phone
  alert_notifications = var.security_center_contact.alert_notifications
  alerts_to_admins    = var.security_center_contact.alerts_to_admins
}

# Security Center Auto Provisioning
resource "azurerm_security_center_auto_provisioning" "main" {
  auto_provision = var.security_center_auto_provisioning
}

# =============================================================================
# AZURE POLICY
# =============================================================================

# Policy Assignments
resource "azurerm_policy_assignment" "main" {
  for_each = var.policy_assignments

  name                 = each.value.name
  policy_definition_id = each.value.policy_definition_id
  scope               = each.value.scope
  description         = each.value.description
  display_name        = each.value.display_name
  location            = var.location

  # Identity for policies that require remediation
  dynamic "identity" {
    for_each = each.value.require_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Parameters
  parameters = each.value.parameters

  # Non-compliance messages
  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_messages
    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = non_compliance_message.value.policy_definition_reference_id
    }
  }
}

# =============================================================================
# CUSTOM RBAC ROLE DEFINITIONS
# =============================================================================

resource "azurerm_role_definition" "main" {
  for_each = var.custom_roles

  name  = each.value.name
  scope = each.value.scope

  description = each.value.description

  permissions {
    actions          = each.value.permissions.actions
    not_actions      = each.value.permissions.not_actions
    data_actions     = each.value.permissions.data_actions
    not_data_actions = each.value.permissions.not_data_actions
  }

  assignable_scopes = each.value.assignable_scopes
}

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

resource "azurerm_role_assignment" "main" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  description         = each.value.description

  # Skip authorization check for service principals
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}

# =============================================================================
# AZURE FIREWALL (if enabled)
# =============================================================================

resource "azurerm_public_ip" "firewall" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "${var.project_name}-${var.environment}-fw-pip"
  location            = var.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                = "Standard"
  zones              = ["1", "2", "3"]

  tags = local.common_tags
}

resource "azurerm_firewall" "main" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "${var.project_name}-${var.environment}-fw"
  location            = var.location
  resource_group_name = module.resource_group.name
  sku_name           = var.firewall_sku_name
  sku_tier           = var.firewall_sku_tier
  firewall_policy_id = var.firewall_policy_id
  threat_intel_mode  = var.firewall_threat_intel_mode

  ip_configuration {
    name                 = "configuration"
    subnet_id           = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  tags = local.common_tags
}

# =============================================================================
# NETWORK SECURITY GROUP RULES (Additional Security Rules)
# =============================================================================

# Additional security rules for enhanced protection
resource "azurerm_network_security_rule" "deny_all_inbound" {
  count = var.enable_additional_nsg_rules ? 1 : 0

  name                        = "DenyAllInbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.terraform_remote_state.networking.outputs.resource_group_name
  network_security_group_name = data.terraform_remote_state.networking.outputs.nsg_names["app"]
}

# =============================================================================
# DIAGNOSTIC SETTINGS FOR SECURITY RESOURCES
# =============================================================================

# Diagnostic settings for Key Vault are handled in the module
# Additional diagnostic settings can be added here for other security resources

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count = var.enable_azure_firewall && var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.project_name}-${var.environment}-fw-diagnostics"
  target_resource_id         = azurerm_firewall.main[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = var.firewall_diagnostic_logs
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.firewall_diagnostic_metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}