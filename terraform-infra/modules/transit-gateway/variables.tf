# =============================================================================
# TRANSIT GATEWAY MODULE VARIABLES
# =============================================================================

variable "transit_gateway_name" {
  description = "Name for the Transit Gateway"
  type        = string
  default     = "default-tgw"
}

variable "amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Amazon side of a BGP session"
  type        = number
  default     = 64512
}

variable "auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted"
  type        = string
  default     = "disable"
  validation {
    condition     = contains(["disable", "enable"], var.auto_accept_shared_attachments)
    error_message = "auto_accept_shared_attachments must be either 'disable' or 'enable'."
  }
}

variable "default_route_table_association" {
  description = "Whether resource attachments are automatically associated with the default association route table"
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["disable", "enable"], var.default_route_table_association)
    error_message = "default_route_table_association must be either 'disable' or 'enable'."
  }
}

variable "default_route_table_propagation" {
  description = "Whether resource attachments automatically propagate routes to the default propagation route table"
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["disable", "enable"], var.default_route_table_propagation)
    error_message = "default_route_table_propagation must be either 'disable' or 'enable'."
  }
}

variable "dns_support" {
  description = "Whether DNS support is enabled"
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["disable", "enable"], var.dns_support)
    error_message = "dns_support must be either 'disable' or 'enable'."
  }
}

variable "vpn_ecmp_support" {
  description = "Whether VPN Equal Cost Multipath Protocol support is enabled"
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["disable", "enable"], var.vpn_ecmp_support)
    error_message = "vpn_ecmp_support must be either 'disable' or 'enable'."
  }
}

variable "vpc_attachments" {
  description = "Map of VPC attachments to create"
  type = map(object({
    vpc_id                                          = string
    subnet_ids                                      = list(string)
    dns_support                                     = optional(bool, true)
    ipv6_support                                   = optional(bool, false)
    appliance_mode_support                         = optional(string, "disable")
    transit_gateway_default_route_table_association = optional(bool, true)
    transit_gateway_default_route_table_propagation = optional(bool, true)
  }))
  default = {}
}

variable "create_transit_gateway_route_table" {
  description = "Whether to create a custom route table for the transit gateway"
  type        = bool
  default     = false
}

variable "transit_gateway_route_table_id" {
  description = "ID of an existing transit gateway route table to use"
  type        = string
  default     = ""
}

variable "transit_gateway_routes" {
  description = "Map of transit gateway routes to create"
  type = map(object({
    destination_cidr_block        = string
    transit_gateway_attachment_id = optional(string)
    blackhole                    = optional(bool, false)
  }))
  default = {}
}

variable "route_table_associations" {
  description = "Map of route table associations"
  type        = map(object({}))
  default     = {}
}

variable "route_table_propagations" {
  description = "Map of route table propagations"
  type        = map(object({}))
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
