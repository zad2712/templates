variable "location" { type = string }
variable "base_name" { type = string }
variable "tags" { type = map(string) }
variable "workspace_id" { type = string }

# Built-in policy references (examples)
# Tag enforcement for 'environment' and 'workload'
# Allowed locations (restrict to provided list)
# Deploy diagnostic settings to Log Analytics (example placeholder)

locals {
  allowed_locations = ["eastus", "westus2"]
}

data "azurerm_subscription" "current" {}

# Policy assignment for allowed locations (built-in definition ID)
resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "pa-${var.base_name}-locations"
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c" # Allowed locations
  display_name         = "Allowed Locations (${var.base_name})"
  parameters = jsonencode({
    listOfAllowedLocations = { value = local.allowed_locations }
  })
  enforcement_mode = "Default"
}

# Tag enforcement (inherit if missing) - environment
resource "azurerm_policy_assignment" "tag_environment" {
  name                 = "pa-${var.base_name}-tag-env"
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/4f9cf6d5-10c7-40c2-9e9e-ecb6b448fe84" # Append tag and its default value
  display_name         = "Enforce environment tag"
  parameters = jsonencode({
    tagName  = { value = "environment" }
    tagValue = { value = "${var.base_name}" }
  })
}

# Diagnostic settings auto-deploy placeholder (Would typically use an initiative)
# For brevity, just demonstrating tag & location; initiative authoring can be added later.
