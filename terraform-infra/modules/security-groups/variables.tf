# =============================================================================
# SECURITY GROUPS MODULE VARIABLES
# =============================================================================

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
  default     = ""
}

variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    name                   = optional(string)
    name_prefix            = optional(string)
    description            = optional(string, "Managed by Terraform")
    revoke_rules_on_delete = optional(bool, false)
    tags                   = optional(map(string), {})

    ingress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      description              = optional(string)
      cidr_blocks              = optional(list(string))
      ipv6_cidr_blocks         = optional(list(string))
      prefix_list_ids          = optional(list(string))
      source_security_group_id = optional(string)
      self                     = optional(bool)
    })), [])

    egress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      description              = optional(string)
      cidr_blocks              = optional(list(string))
      ipv6_cidr_blocks         = optional(list(string))
      prefix_list_ids          = optional(list(string))
      source_security_group_id = optional(string)
      self                     = optional(bool)
    })), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
