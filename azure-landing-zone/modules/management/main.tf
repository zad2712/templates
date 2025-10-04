variable "org_code" { type = string }
variable "root_name" { type = string }

# NOTE: Management group creation requires tenant-level permissions. Wrap in guidance.
# Basic two-tier example (root + platform)

resource "azurerm_management_group" "root" {
  display_name = var.root_name
}

resource "azurerm_management_group" "platform" {
  display_name               = "${upper(var.org_code)}-PLATFORM"
  parent_management_group_id = azurerm_management_group.root.id
}

output "root_management_group_id" { value = azurerm_management_group.root.id }
