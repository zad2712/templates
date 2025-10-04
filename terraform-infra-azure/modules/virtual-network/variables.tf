# =============================================================================
# VIRTUAL NETWORK MODULE VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region for the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "dns_servers" {
  description = "Custom DNS servers for the virtual network"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    name                                      = string
    address_prefixes                         = list(string)
    private_endpoint_network_policies        = optional(string, "Enabled")
    private_link_service_network_policies    = optional(string, "Enabled")
    service_endpoints                        = optional(list(string), [])
    service_endpoint_policy_ids              = optional(list(string), [])
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
  }))
  default = {}
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection plan"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}