# =============================================================================
# VIRTUAL NETWORK MODULE
# =============================================================================

resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = var.tags
}

# Subnets
resource "azurerm_subnet" "main" {
  for_each = var.subnets

  name                                      = each.value.name
  resource_group_name                       = var.resource_group_name
  virtual_network_name                     = azurerm_virtual_network.main.name
  address_prefixes                         = each.value.address_prefixes
  private_endpoint_network_policies        = lookup(each.value, "private_endpoint_network_policies", "Enabled")
  private_link_service_network_policies    = lookup(each.value, "private_link_service_network_policies", "Enabled")
  service_endpoints                        = lookup(each.value, "service_endpoints", [])
  service_endpoint_policy_ids              = lookup(each.value, "service_endpoint_policy_ids", [])

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", [])
    
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# DDoS Protection Plan (optional)
resource "azurerm_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "${var.name}-ddos"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Associate DDoS protection plan if enabled
resource "azurerm_virtual_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0

  virtual_network_id         = azurerm_virtual_network.main.id
  ddos_protection_plan_id    = azurerm_network_ddos_protection_plan.main[0].id
}