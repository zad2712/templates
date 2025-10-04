variable "location" { type = string }
variable "base_name" { type = string }
variable "tags" { type = map(string) }
variable "retention_in_days" { type = number default = 30 }

resource "azurerm_resource_group" "logging" {
  name     = "rg-${var.base_name}-logs"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# Helper: subscription diagnostic assignment placeholder (policy module will enforce broader diagnostics)

output "workspace_id" { value = azurerm_log_analytics_workspace.this.id }
output "workspace_name" { value = azurerm_log_analytics_workspace.this.name }
