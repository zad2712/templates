# =============================================================================
# NETWORK SECURITY GROUP MODULE VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the network security group"
  type        = string
}

variable "location" {
  description = "Azure region for the network security group"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "security_rules" {
  description = "List of security rules to create"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "All security rule priorities must be between 100 and 4096."
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "All security rule directions must be either Inbound or Outbound."
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "All security rule access must be either Allow or Deny."
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol)
    ])
    error_message = "All security rule protocols must be valid Azure NSG protocols."
  }
}

variable "tags" {
  description = "Tags to apply to the network security group"
  type        = map(string)
  default     = {}
}