#############################
# Root Landing Zone Compose #
#############################

module "logging" {
  source            = "./modules/logging"
  location          = var.location
  base_name         = local.base_name
  retention_in_days = var.log_retention_days
  tags              = local.default_tags
}

module "networking" {
  source          = "./modules/networking"
  location        = var.location
  base_name       = local.base_name
  tags            = local.default_tags
  enable_firewall = var.enable_firewall
  enable_bastion  = var.enable_bastion
}

module "security" {
  source            = "./modules/security"
  location          = var.location
  base_name         = local.base_name
  key_vault_sku     = var.key_vault_sku
  tags              = local.default_tags
  enable_private_endpoints = var.enable_private_endpoints
  log_analytics_workspace_id = module.logging.workspace_id
}

module "identity" {
  source     = "./modules/identity"
  location   = var.location
  base_name  = local.base_name
  identities = var.identities
  tags       = local.default_tags
}

module "policy" {
  count       = var.policy_enabled ? 1 : 0
  source      = "./modules/policy"
  location    = var.location
  base_name   = local.base_name
  workspace_id = module.logging.workspace_id
  tags        = local.default_tags
}

# management module optional (needs tenant permissions)
module "management" {
  count     = var.mgmt_groups_enabled ? 1 : 0
  source    = "./modules/management"
  org_code  = var.org_code
  root_name = upper(var.org_code)
}
