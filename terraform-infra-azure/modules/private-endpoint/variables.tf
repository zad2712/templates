# =============================================================================
# PRIVATE ENDPOINT VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the private endpoint"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the private endpoint will be created"
  type        = string
}

variable "private_connection_resource_id" {
  description = "The ID of the Private Link Enabled Remote Resource"
  type        = string
}

variable "subresource_names" {
  description = "A list of subresource names which the Private Endpoint is able to connect to"
  type        = list(string)
}

variable "is_manual_connection" {
  description = "Does the Private Endpoint require Manual Approval from the remote resource owner?"
  type        = bool
  default     = false
}

variable "request_message" {
  description = "A message passed to the owner of the remote resource when manual connection is requested"
  type        = string
  default     = null
}

variable "private_dns_zone_group" {
  description = "Private DNS zone group configuration"
  type = object({
    name = string
    private_dns_zone_configs = list(object({
      name                 = string
      private_dns_zone_id  = string
    }))
  })
  default = null
}

variable "custom_network_interface_name" {
  description = "The custom name of the network interface attached to the private endpoint"
  type        = string
  default     = null
}

variable "ip_configuration" {
  description = "One or more ip_configuration blocks as defined below"
  type = list(object({
    name               = string
    private_ip_address = string
    subresource_name   = optional(string)
    member_name        = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the private endpoint"
  type        = map(string)
  default     = {}
}

# Application Security Group Association
variable "application_security_group_ids" {
  description = "A list of Application Security Group IDs which should be associated with this Private Endpoint"
  type        = list(string)
  default     = []
}

# Network Security Group Association
variable "network_security_group_id" {
  description = "The ID of the Network Security Group which should be associated with the Private Endpoint"
  type        = string
  default     = null
}

# Policy-based configuration
variable "policy_settings_enabled" {
  description = "Whether network policies are enabled on the subnet for the private endpoint"
  type        = bool
  default     = false
}

# Common service-specific subresource mappings
variable "service_type" {
  description = "The type of Azure service to create a private endpoint for (used for validation)"
  type        = string
  default     = "custom"
  validation {
    condition = contains([
      "storage_account", "sql_server", "cosmos_db", "key_vault", 
      "redis_cache", "app_service", "function_app", "synapse", 
      "data_factory", "event_hub", "service_bus", "cognitive_services",
      "container_registry", "kubernetes", "mysql", "postgresql", "custom"
    ], var.service_type)
    error_message = "Service type must be a supported Azure service or 'custom'."
  }
}

# Validation helper for common subresource names
locals {
  service_subresources = {
    storage_account     = ["blob", "file", "queue", "table", "web", "dfs"]
    sql_server         = ["sqlServer"]
    cosmos_db          = ["Sql", "MongoDB", "Cassandra", "Gremlin", "Table"]
    key_vault          = ["vault"]
    redis_cache        = ["redisCache"]
    app_service        = ["sites"]
    function_app       = ["sites"]
    synapse           = ["Sql", "SqlOnDemand", "Dev"]
    data_factory      = ["dataFactory"]
    event_hub         = ["namespace"]
    service_bus       = ["namespace"]
    cognitive_services = ["account"]
    container_registry = ["registry"]
    kubernetes        = ["management"]
    mysql            = ["mysqlServer"]
    postgresql       = ["postgresqlServer"]
    custom           = []
  }
}