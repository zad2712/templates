variable "location" { type = string }
variable "base_name" { type = string }
variable "tags" { type = map(string) }
variable "identities" { type = map(object({ roles = optional(list(object({ scope = string, role_definition_name = string })), []) })) }

resource "azurerm_resource_group" "identity" {
  name     = "rg-${var.base_name}-id"
  location = var.location
  tags     = var.tags
}

resource "azurerm_user_assigned_identity" "this" {
  for_each            = var.identities
  name                = "id-${var.base_name}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.identity.name
  tags                = var.tags
}

# Role assignments (management plane) for each identity
resource "azurerm_role_assignment" "identity_roles" {
  for_each             = { for k, v in var.identities : k => v if length(try(v.roles, [])) > 0 }
  scope                = azurerm_resource_group.identity.id
  role_definition_name = "Reader" # baseline example (customize by identity roles list below)
  principal_id         = azurerm_user_assigned_identity.this[each.key].principal_id
}

# Additional explicit roles
resource "azurerm_role_assignment" "extra" {
  for_each = { for pair in flatten([
    for k, v in var.identities : [for r in try(v.roles, []) : merge(r, { identity_key = k })]
  ]) : "${pair.identity_key}-${pair.role_definition_name}-${substr(sha1(pair.scope),0,6)}" => pair }
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this[each.value.identity_key].principal_id
}

output "identity_ids" { value = { for k, v in azurerm_user_assigned_identity.this : k => v.id } }
