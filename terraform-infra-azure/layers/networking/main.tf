# =============================================================================
# NETWORKING LAYER - Virtual Network, Subnets, and Network Infrastructure
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
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Layer       = "networking"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Naming convention
  resource_group_name = "${var.project_name}-${var.environment}-networking-rg"
  
  # Network configuration
  vnet_name = "${var.project_name}-${var.environment}-vnet"
  
  # Subnet configurations
  subnets = {
    web = {
      name             = "web-subnet"
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 1)]
    }
    app = {
      name             = "app-subnet"
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 2)]
    }
    data = {
      name             = "data-subnet"
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 3)]
    }
    aks = {
      name             = "aks-subnet"
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 4, 1)]
    }
    gateway = {
      name             = "gateway-subnet"
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 4)]
    }
    private_endpoints = {
      name             = "private-endpoints-subnet"
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 5)]
    }
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

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
# VIRTUAL NETWORK
# =============================================================================

module "virtual_network" {
  source = "../../modules/virtual-network"

  name                = local.vnet_name
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers

  subnets = {
    for key, subnet in local.subnets : key => {
      name                                      = subnet.name
      address_prefixes                         = subnet.address_prefixes
      private_endpoint_network_policies        = key == "private_endpoints" ? "Disabled" : "Enabled"
      private_link_service_network_policies    = "Enabled"
      service_endpoints                        = var.subnet_service_endpoints[key]
      service_endpoint_policy_ids              = []
      delegation = key == "aks" ? [
        {
          name = "aks-delegation"
          service_delegation = {
            name    = "Microsoft.ContainerService/managedClusters"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          }
        }
      ] : []
    }
  }

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# =============================================================================
# NETWORK SECURITY GROUPS
# =============================================================================

module "network_security_groups" {
  source = "../../modules/network-security-group"

  for_each = local.subnets

  name                = "${each.value.name}-nsg"
  resource_group_name = module.resource_group.name
  location            = var.location

  security_rules = var.nsg_rules[each.key]
  tags          = local.common_tags

  depends_on = [module.resource_group]
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = local.subnets

  subnet_id                 = module.virtual_network.subnet_ids[each.key]
  network_security_group_id = module.network_security_groups[each.key].id
}

# =============================================================================
# ROUTE TABLE
# =============================================================================

resource "azurerm_route_table" "main" {
  name                = "${local.vnet_name}-rt"
  location            = var.location
  resource_group_name = module.resource_group.name

  route {
    name                   = "internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type         = "Internet"
  }

  tags = local.common_tags
}

# Associate route table with subnets (except AKS subnet)
resource "azurerm_subnet_route_table_association" "main" {
  for_each = { for k, v in local.subnets : k => v if k != "aks" }

  subnet_id      = module.virtual_network.subnet_ids[each.key]
  route_table_id = azurerm_route_table.main.id
}

# =============================================================================
# NETWORK WATCHER
# =============================================================================

resource "azurerm_network_watcher" "main" {
  count = var.enable_network_watcher ? 1 : 0

  name                = "${var.project_name}-${var.environment}-nw"
  location            = var.location
  resource_group_name = module.resource_group.name

  tags = local.common_tags
}

# =============================================================================
# PUBLIC IP FOR APPLICATION GATEWAY
# =============================================================================

resource "azurerm_public_ip" "app_gateway" {
  count = var.enable_application_gateway ? 1 : 0

  name                = "${var.project_name}-${var.environment}-appgw-pip"
  resource_group_name = module.resource_group.name
  location            = var.location
  allocation_method   = "Static"
  sku                = "Standard"
  zones              = ["1", "2", "3"]

  tags = local.common_tags
}

# =============================================================================
# APPLICATION GATEWAY
# =============================================================================

module "application_gateway" {
  source = "../../modules/application-gateway"
  count  = var.enable_application_gateway ? 1 : 0

  name                = "${var.project_name}-${var.environment}-appgw"
  resource_group_name = module.resource_group.name
  location            = var.location

  subnet_id         = module.virtual_network.subnet_ids["gateway"]
  public_ip_id      = azurerm_public_ip.app_gateway[0].id
  
  sku_name          = var.app_gateway_sku_name
  sku_tier          = var.app_gateway_sku_tier
  sku_capacity      = var.app_gateway_sku_capacity

  waf_enabled       = var.app_gateway_waf_enabled
  waf_mode          = var.app_gateway_waf_mode

  tags = local.common_tags

  depends_on = [module.virtual_network]
}

# =============================================================================
# PRIVATE DNS ZONES
# =============================================================================

resource "azurerm_private_dns_zone" "main" {
  for_each = toset(var.private_dns_zones)

  name                = each.value
  resource_group_name = module.resource_group.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each = toset(var.private_dns_zones)

  name                  = "${local.vnet_name}-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.main[each.key].name
  virtual_network_id    = module.virtual_network.id
  registration_enabled  = each.value == "privatelink.vaultcore.azure.net" ? false : true

  tags = local.common_tags
}