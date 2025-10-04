# =============================================================================
# RESOURCE GROUP MODULE
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location

  tags = var.tags
}

# Resource Group Lock (optional)
resource "azurerm_management_lock" "resource_group_lock" {
  count = var.enable_lock ? 1 : 0

  name       = "${var.name}-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = var.lock_level
  notes      = "Terraform managed lock"
}