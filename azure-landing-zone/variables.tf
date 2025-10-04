variable "org_code" { type = string description = "Short organization code (e.g. acme)" }
variable "environment" { type = string description = "Environment name (e.g. dev, prod)" }
variable "location" { type = string description = "Primary Azure region." default = "eastus" }
variable "secondary_location" { type = string description = "Secondary region (optional)." default = null }
variable "workload_name" { type = string description = "High-level workload or platform name." default = "platform" }
variable "tags" { type = map(string) description = "Common tags applied to all resources." default = {} }

variable "enable_firewall" { type = bool default = false description = "Deploy Azure Firewall in hub." }
variable "enable_bastion" { type = bool default = false description = "Deploy Azure Bastion in hub." }
variable "enable_private_endpoints" { type = bool default = false description = "Enable creation of private endpoints (future)." }

variable "log_retention_days" { type = number default = 30 description = "Log Analytics retention period." }
variable "key_vault_sku" { type = string default = "standard" validation { condition = contains(["standard","premium"], lower(var.key_vault_sku)) error_message = "key_vault_sku must be standard or premium" } }

variable "mgmt_groups_enabled" { type = bool default = false }
variable "policy_enabled" { type = bool default = true }

variable "identities" { description = "Map of identity name => object with optional roles (list of { scope, role_definition_name })" type = map(object({ roles = optional(list(object({ scope = string, role_definition_name = string })), []) })) default = {} }
