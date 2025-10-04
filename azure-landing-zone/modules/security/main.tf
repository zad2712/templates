variable "location" { type = string }
variable "base_name" { type = string }
variable "tags" { type = map(string) }
variable "key_vault_sku" { type = string }
variable "enable_private_endpoints" { type = bool default = false }
variable "log_analytics_workspace_id" { type = string }

resource "azurerm_resource_group" "security" {
  name     = "rg-${var.base_name}-sec"
  location = var.location
  tags     = var.tags
}

resource "azurerm_key_vault" "this" {
  name                       = replace("kv-${var.base_name}", "_", "-")
  location                   = var.location
  resource_group_name        = azurerm_resource_group.security.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = upper(var.key_vault_sku) == "PREMIUM" ? "premium" : "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  enable_rbac_authorization  = true
  public_network_access_enabled = true
  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

data "azurerm_client_config" "current" {}

# Future: private endpoint support (storage, key vault) - placeholder conditional logic
# Will require passing in virtual network/subnet IDs.

output "key_vault_id" { value = azurerm_key_vault.this.id }
output "key_vault_name" { value = azurerm_key_vault.this.name }
