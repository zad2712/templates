variable "location" { type = string }
variable "base_name" { type = string }
variable "tags" { type = map(string) }
variable "enable_firewall" { type = bool default = false }
variable "enable_bastion" { type = bool default = false }

# Hub VNet
resource "azurerm_resource_group" "network" {
  name     = "rg-${var.base_name}-hub"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.base_name}-hub"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

# Core subnets
locals {
  subnets = {
    "AzureFirewallSubnet" = "10.0.0.0/26"
    "AzureBastionSubnet"  = "10.0.0.64/26"
    "shared-services"     = "10.0.1.0/24"
  }
}

resource "azurerm_subnet" "hub" {
  for_each             = local.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

# Optional Bastion
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "pip-${var.base_name}-bastion"
  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  count               = var.enable_bastion ? 1 : 0
  name                = "bas-${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  sku                 = "Standard"
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
  tags = var.tags
}

# Optional Firewall placeholder (full ruleset can be added later)
resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "pip-${var.base_name}-fw"
  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  count               = var.enable_firewall ? 1 : 0
  name                = "fw-${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
  tags = var.tags
}

output "vnet_id" { value = azurerm_virtual_network.hub.id }
output "resource_group_name" { value = azurerm_resource_group.network.name }
