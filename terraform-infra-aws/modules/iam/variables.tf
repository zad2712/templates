# IAM Module - Variables
# Author: Diego A. Zarate

# General Configuration
variable "name_prefix" {
  description = "Name prefix for IAM resources"
  type        = string
  default     = "app"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "Name prefix must be between 1 and 32 characters."
  }
}

variable "tags" {
  description = "A map of tags to assign to IAM resources"
  type        = map(string)
  default     = {}
}

# Feature Flags
variable "create_users" {
  description = "Whether to create IAM users"
  type        = bool
  default     = false
}

variable "create_access_keys" {
  description = "Whether to create access keys for users"
  type        = bool
  default     = false
}

variable "create_account_password_policy" {
  description = "Whether to create account password policy"
  type        = bool
  default     = true
}

# Account Configuration
variable "account_alias" {
  description = "The account alias for the AWS account"
  type        = string
  default     = null

  validation {
    condition = var.account_alias == null || (
      length(var.account_alias) >= 3 && 
      length(var.account_alias) <= 63 &&
      can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.account_alias))
    )
    error_message = "Account alias must be 3-63 characters, lowercase letters, numbers, and hyphens only."
  }
}

# IAM Roles Configuration
variable "iam_roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    description              = string
    principal_type          = string
    principal_identifiers   = list(string)
    aws_managed_policies    = optional(list(string), [])
    custom_managed_policies = optional(list(string), [])
    inline_policies = optional(list(object({
      name   = string
      policy = string
    })), [])
    assume_role_conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
    max_session_duration  = optional(number, 3600)
    path                 = optional(string, "/")
    permissions_boundary = optional(string, null)
    force_detach_policies = optional(bool, true)
    tags                 = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for role_name, role_config in var.iam_roles : 
      contains(["Service", "AWS", "Federated"], role_config.principal_type)
    ])
    error_message = "Principal type must be one of: Service, AWS, Federated."
  }

  validation {
    condition = alltrue([
      for role_name, role_config in var.iam_roles : 
      role_config.max_session_duration >= 3600 && role_config.max_session_duration <= 43200
    ])
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours)."
  }
}

# IAM Policies Configuration
variable "iam_policies" {
  description = "Map of custom IAM policies to create"
  type = map(object({
    description     = string
    policy_document = string
    path           = optional(string, "/")
    tags           = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy_name, policy_config in var.iam_policies : 
      can(jsondecode(policy_config.policy_document))
    ])
    error_message = "Policy document must be valid JSON."
  }
}

# IAM Groups Configuration
variable "iam_groups" {
  description = "Map of IAM groups to create"
  type = map(object({
    aws_managed_policies    = optional(list(string), [])
    custom_managed_policies = optional(list(string), [])
    users                  = optional(list(string), [])
    path                   = optional(string, "/")
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# IAM Users Configuration
variable "iam_users" {
  description = "Map of IAM users to create"
  type = map(object({
    path                 = optional(string, "/")
    permissions_boundary = optional(string, null)
    force_destroy        = optional(bool, false)
    tags                 = optional(map(string), {})
  }))
  default = {}
}

# Access Keys Configuration
variable "user_access_keys" {
  description = "Map of users to create access keys for"
  type = map(object({
    status = optional(string, "Active")
  }))
  default = {}

  validation {
    condition = alltrue([
      for user, config in var.user_access_keys :
      contains(["Active", "Inactive"], config.status)
    ])
    error_message = "Access key status must be either 'Active' or 'Inactive'."
  }
}

# Service-Linked Roles Configuration
variable "service_linked_roles" {
  description = "Map of service-linked roles to create"
  type = map(object({
    aws_service_name = string
    description      = optional(string, null)
    custom_suffix    = optional(string, null)
    tags            = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for role_name, role_config in var.service_linked_roles :
      can(regex("^[a-zA-Z0-9\\.-]+$", role_config.aws_service_name))
    ])
    error_message = "AWS service name must be a valid service identifier."
  }
}

# OIDC Identity Providers Configuration
variable "oidc_providers" {
  description = "Map of OIDC identity providers to create"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
    tags           = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for provider_name, provider_config in var.oidc_providers :
      can(regex("^https://", provider_config.url))
    ])
    error_message = "OIDC provider URL must start with https://."
  }

  validation {
    condition = alltrue([
      for provider_name, provider_config in var.oidc_providers :
      length(provider_config.thumbprint_list) > 0 && length(provider_config.thumbprint_list) <= 5
    ])
    error_message = "OIDC provider must have 1-5 thumbprints."
  }
}

# SAML Identity Providers Configuration
variable "saml_providers" {
  description = "Map of SAML identity providers to create"
  type = map(object({
    saml_metadata_document = string
    tags                  = optional(map(string), {})
  }))
  default = {}
}

# Password Policy Configuration
variable "password_policy" {
  description = "Account password policy configuration"
  type = object({
    minimum_password_length        = optional(number, 14)
    require_lowercase_characters   = optional(bool, true)
    require_numbers               = optional(bool, true)
    require_uppercase_characters   = optional(bool, true)
    require_symbols               = optional(bool, true)
    allow_users_to_change_password = optional(bool, true)
    hard_expiry                   = optional(bool, false)
    max_password_age              = optional(number, 90)
    password_reuse_prevention     = optional(number, 24)
  })
  default = {
    minimum_password_length        = 14
    require_lowercase_characters   = true
    require_numbers               = true
    require_uppercase_characters   = true
    require_symbols               = true
    allow_users_to_change_password = true
    hard_expiry                   = false
    max_password_age              = 90
    password_reuse_prevention     = 24
  }

  validation {
    condition = (
      var.password_policy.minimum_password_length >= 6 && 
      var.password_policy.minimum_password_length <= 128
    )
    error_message = "Minimum password length must be between 6 and 128."
  }

  validation {
    condition = (
      var.password_policy.max_password_age >= 1 && 
      var.password_policy.max_password_age <= 1095
    )
    error_message = "Max password age must be between 1 and 1095 days."
  }

  validation {
    condition = (
      var.password_policy.password_reuse_prevention >= 1 && 
      var.password_policy.password_reuse_prevention <= 24
    )
    error_message = "Password reuse prevention must be between 1 and 24."
  }
}