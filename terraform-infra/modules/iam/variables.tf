# =============================================================================
# IAM MODULE VARIABLES
# =============================================================================

variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    assume_role_policy     = string
    description           = optional(string)
    force_detach_policies = optional(bool, false)
    max_session_duration  = optional(number, 3600)
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
    policy_arns          = optional(list(string), [])
    inline_policies      = optional(map(string), {})
    tags                 = optional(map(string), {})
  }))
  default = {}
}

variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    policy_document = string
    description     = optional(string)
    path           = optional(string, "/")
    tags           = optional(map(string), {})
  }))
  default = {}
}

variable "groups" {
  description = "Map of IAM groups to create"
  type = map(object({
    path        = optional(string, "/")
    policy_arns = optional(list(string), [])
  }))
  default = {}
}

variable "users" {
  description = "Map of IAM users to create"
  type = map(object({
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
    force_destroy       = optional(bool, false)
    policy_arns         = optional(list(string), [])
    groups             = optional(list(string), [])
    tags               = optional(map(string), {})
  }))
  default = {}
}

variable "instance_profiles" {
  description = "Map of IAM instance profiles to create"
  type = map(object({
    role = string
    path = optional(string, "/")
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
