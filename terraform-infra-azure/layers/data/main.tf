# =============================================================================
# DATA LAYER - SQL Database, Cosmos DB, Storage, and Data Services
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
    Layer       = "data"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Naming convention
  resource_group_name = "${var.project_name}-${var.environment}-data-rg"
  
  # Data from other layers
  security_rg_outputs   = data.terraform_remote_state.security.outputs
  networking_rg_outputs = data.terraform_remote_state.networking.outputs
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
# AZURE SQL DATABASE
# =============================================================================

module "sql_database" {
  for_each = var.sql_databases

  source = "../../modules/sql-database"

  # Basic Configuration
  server_name         = "${var.project_name}-${var.environment}-${each.key}-sqlsrv"
  database_name       = each.value.database_name
  resource_group_name = module.resource_group.name
  location           = var.location

  # Server Configuration
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  server_version              = each.value.server_version

  # Database Configuration
  sku_name                     = each.value.sku_name
  max_size_gb                 = each.value.max_size_gb
  zone_redundant              = each.value.zone_redundant
  read_scale                  = each.value.read_scale
  read_replica_count          = each.value.read_replica_count

  # Security Configuration
  enable_azure_ad_authentication = true
  azure_ad_admin_login           = each.value.azure_ad_admin_login
  azure_ad_admin_object_id       = each.value.azure_ad_admin_object_id
  enable_tde                     = true
  tde_key_vault_key_id          = local.security_rg_outputs.key_vault_key_ids["database-encryption"]

  # Network Configuration
  enable_private_endpoint      = var.enable_private_endpoints
  subnet_id                   = local.networking_rg_outputs.database_subnet_id
  private_endpoint_subnet_id  = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id         = local.networking_rg_outputs.private_dns_zone_ids["privatelink.database.windows.net"]

  # Firewall Rules
  firewall_rules = each.value.firewall_rules

  # Backup Configuration
  backup_retention_days        = each.value.backup_retention_days
  geo_backup_enabled          = each.value.geo_backup_enabled
  backup_interval_in_hours    = each.value.backup_interval_in_hours

  # Diagnostic Settings
  enable_diagnostic_settings  = var.enable_diagnostic_settings
  log_analytics_workspace_id  = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# COSMOS DB
# =============================================================================

module "cosmos_db" {
  for_each = var.cosmos_db_accounts

  source = "../../modules/cosmos-db"

  # Basic Configuration
  account_name        = "${var.project_name}-${var.environment}-${each.key}-cosmos"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Account Configuration
  offer_type                    = each.value.offer_type
  kind                         = each.value.kind
  consistency_level            = each.value.consistency_level
  max_interval_in_seconds      = each.value.max_interval_in_seconds
  max_staleness_prefix         = each.value.max_staleness_prefix

  # Geo Replication
  geo_locations = each.value.geo_locations

  # Security Configuration
  enable_automatic_failover         = each.value.enable_automatic_failover
  enable_multiple_write_locations   = each.value.enable_multiple_write_locations
  is_virtual_network_filter_enabled = true
  public_network_access_enabled     = !var.enable_private_endpoints

  # Network Configuration
  virtual_network_rules = [
    {
      id                                   = local.networking_rg_outputs.database_subnet_id
      ignore_missing_vnet_service_endpoint = false
    }
  ]

  # Private Endpoint
  enable_private_endpoint     = var.enable_private_endpoints
  private_endpoint_subnet_id  = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id        = local.networking_rg_outputs.private_dns_zone_ids["privatelink.documents.azure.com"]

  # Backup Configuration
  backup_type               = each.value.backup_type
  backup_interval_in_minutes = each.value.backup_interval_in_minutes
  backup_retention_in_hours  = each.value.backup_retention_in_hours
  backup_redundancy         = each.value.backup_redundancy

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# STORAGE ACCOUNTS
# =============================================================================

module "storage_account" {
  for_each = var.storage_accounts

  source = "../../modules/storage-account"

  # Basic Configuration
  storage_account_name = "${var.project_name}${var.environment}${each.key}st"
  resource_group_name  = module.resource_group.name
  location            = var.location

  # Storage Configuration
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  account_kind            = each.value.account_kind
  access_tier             = each.value.access_tier

  # Security Configuration
  enable_https_traffic_only      = true
  min_tls_version               = "TLS1_2"
  shared_access_key_enabled     = each.value.shared_access_key_enabled
  allow_nested_items_to_be_public = false

  # Network Configuration
  enable_network_rules          = true
  default_action               = var.enable_private_endpoints ? "Deny" : "Allow"
  ip_rules                     = each.value.ip_rules
  virtual_network_subnet_ids   = [local.networking_rg_outputs.database_subnet_id]

  # Private Endpoint Configuration
  enable_private_endpoint     = var.enable_private_endpoints
  private_endpoint_subnet_id  = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_ids = {
    blob  = local.networking_rg_outputs.private_dns_zone_ids["privatelink.blob.core.windows.net"]
    file  = local.networking_rg_outputs.private_dns_zone_ids["privatelink.file.core.windows.net"]
    table = local.networking_rg_outputs.private_dns_zone_ids["privatelink.table.core.windows.net"]
    queue = local.networking_rg_outputs.private_dns_zone_ids["privatelink.queue.core.windows.net"]
  }

  # Blob Configuration
  blob_containers              = each.value.blob_containers
  enable_versioning           = each.value.enable_versioning
  enable_change_feed          = each.value.enable_change_feed
  versioning_enabled          = each.value.versioning_enabled
  last_access_time_enabled    = each.value.last_access_time_enabled

  # Lifecycle Management
  lifecycle_rules = each.value.lifecycle_rules

  # Diagnostic Settings
  enable_diagnostic_settings  = var.enable_diagnostic_settings
  log_analytics_workspace_id  = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE CACHE FOR REDIS
# =============================================================================

module "redis_cache" {
  for_each = var.redis_caches

  source = "../../modules/redis-cache"

  # Basic Configuration
  redis_cache_name    = "${var.project_name}-${var.environment}-${each.key}-redis"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Cache Configuration
  capacity                      = each.value.capacity
  family                       = each.value.family
  sku_name                     = each.value.sku_name
  enable_non_ssl_port          = false
  minimum_tls_version          = "1.2"
  public_network_access_enabled = !var.enable_private_endpoints

  # Redis Configuration
  redis_configuration = each.value.redis_configuration
  redis_version      = each.value.redis_version

  # Network Configuration
  subnet_id = each.value.sku_name == "Premium" ? local.networking_rg_outputs.database_subnet_id : null

  # Private Endpoint Configuration
  enable_private_endpoint    = var.enable_private_endpoints && each.value.sku_name == "Premium"
  private_endpoint_subnet_id = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id       = local.networking_rg_outputs.private_dns_zone_ids["privatelink.redis.cache.windows.net"]

  # Security Configuration
  patch_schedule = each.value.patch_schedule

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE DATABASE FOR MYSQL
# =============================================================================

module "mysql_database" {
  for_each = var.mysql_databases

  source = "../../modules/mysql-database"

  # Basic Configuration
  server_name         = "${var.project_name}-${var.environment}-${each.key}-mysql"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Server Configuration
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  mysql_version               = each.value.mysql_version
  sku_name                    = each.value.sku_name

  # Storage Configuration
  storage_gb                = each.value.storage_gb
  backup_retention_days     = each.value.backup_retention_days
  geo_redundant_backup     = each.value.geo_redundant_backup
  auto_grow_enabled        = each.value.auto_grow_enabled

  # Security Configuration
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
  public_network_access_enabled    = !var.enable_private_endpoints

  # Network Configuration
  enable_private_endpoint     = var.enable_private_endpoints
  subnet_id                  = local.networking_rg_outputs.database_subnet_id
  private_endpoint_subnet_id = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id        = local.networking_rg_outputs.private_dns_zone_ids["privatelink.mysql.database.azure.com"]

  # Firewall Rules
  firewall_rules = each.value.firewall_rules

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# AZURE DATABASE FOR POSTGRESQL
# =============================================================================

module "postgresql_database" {
  for_each = var.postgresql_databases

  source = "../../modules/postgresql-database"

  # Basic Configuration
  server_name         = "${var.project_name}-${var.environment}-${each.key}-psql"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Server Configuration
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  postgresql_version          = each.value.postgresql_version
  sku_name                    = each.value.sku_name

  # Storage Configuration
  storage_gb               = each.value.storage_gb
  backup_retention_days    = each.value.backup_retention_days
  geo_redundant_backup    = each.value.geo_redundant_backup
  auto_grow_enabled       = each.value.auto_grow_enabled

  # Security Configuration
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
  public_network_access_enabled    = !var.enable_private_endpoints

  # Network Configuration
  enable_private_endpoint     = var.enable_private_endpoints
  subnet_id                  = local.networking_rg_outputs.database_subnet_id
  private_endpoint_subnet_id = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id        = local.networking_rg_outputs.private_dns_zone_ids["privatelink.postgres.database.azure.com"]

  # Firewall Rules
  firewall_rules = each.value.firewall_rules

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# DATA FACTORY
# =============================================================================

module "data_factory" {
  for_each = var.data_factories

  source = "../../modules/data-factory"

  # Basic Configuration
  data_factory_name   = "${var.project_name}-${var.environment}-${each.key}-adf"
  resource_group_name = module.resource_group.name
  location           = var.location

  # Identity Configuration
  identity_type = "SystemAssigned"

  # Network Configuration
  public_network_enabled = !var.enable_private_endpoints

  # Private Endpoint Configuration
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_id       = local.networking_rg_outputs.private_dns_zone_ids["privatelink.datafactory.azure.net"]

  # Git Configuration
  github_configuration = each.value.github_configuration

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# SYNAPSE ANALYTICS WORKSPACE
# =============================================================================

module "synapse_workspace" {
  for_each = var.synapse_workspaces

  source = "../../modules/synapse-workspace"

  # Basic Configuration
  synapse_workspace_name = "${var.project_name}-${var.environment}-${each.key}-synapse"
  resource_group_name   = module.resource_group.name
  location             = var.location

  # Storage Configuration
  storage_data_lake_gen2_filesystem_id = module.storage_account[each.value.storage_account_key].primary_dfs_endpoint

  # Security Configuration
  sql_administrator_login          = each.value.sql_administrator_login
  sql_administrator_login_password = each.value.sql_administrator_login_password

  # Azure AD Integration
  aad_admin = each.value.aad_admin

  # Network Configuration
  public_network_access_enabled = !var.enable_private_endpoints

  # Private Endpoint Configuration
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = local.networking_rg_outputs.private_endpoints_subnet_id
  private_dns_zone_ids = {
    sql    = local.networking_rg_outputs.private_dns_zone_ids["privatelink.sql.azuresynapse.net"]
    dev    = local.networking_rg_outputs.private_dns_zone_ids["privatelink.dev.azuresynapse.net"]
    sql_od = local.networking_rg_outputs.private_dns_zone_ids["privatelink.azuresynapse.net"]
  }

  # Diagnostic Settings
  enable_diagnostic_settings = var.enable_diagnostic_settings
  log_analytics_workspace_id = local.security_rg_outputs.log_analytics_workspace_id

  tags = local.common_tags

  depends_on = [module.resource_group]
}