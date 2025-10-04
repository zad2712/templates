# Security Groups Module - Variables
# Author: Diego A. Zarate

# General Configuration
variable "name_prefix" {
  description = "Name prefix for security group resources"
  type        = string
  default     = "app"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "Name prefix must be between 1 and 32 characters."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "VPC ID must be a valid vpc-* identifier."
  }
}

variable "tags" {
  description = "A map of tags to assign to security groups"
  type        = map(string)
  default     = {}
}

# Security Group Creation Flags
variable "create_web_sg" {
  description = "Whether to create web tier security group"
  type        = bool
  default     = true
}

variable "create_app_sg" {
  description = "Whether to create application tier security group"
  type        = bool
  default     = true
}

variable "create_db_sg" {
  description = "Whether to create database tier security group"
  type        = bool
  default     = true
}

variable "create_cache_sg" {
  description = "Whether to create cache tier security group"
  type        = bool
  default     = false
}

variable "create_management_sg" {
  description = "Whether to create management/bastion security group"
  type        = bool
  default     = false
}

variable "create_lambda_sg" {
  description = "Whether to create Lambda security group"
  type        = bool
  default     = false
}

variable "create_eks_cluster_sg" {
  description = "Whether to create EKS cluster security group"
  type        = bool
  default     = false
}

variable "create_eks_workers_sg" {
  description = "Whether to create EKS worker nodes security group"
  type        = bool
  default     = false
}

# Common Port Configuration
variable "app_port" {
  description = "Port used by application tier"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "database_port" {
  description = "Port used by database tier"
  type        = number
  default     = 5432

  validation {
    condition     = var.database_port > 0 && var.database_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

variable "cache_port" {
  description = "Port used by cache tier (ElastiCache Redis)"
  type        = number
  default     = 6379

  validation {
    condition     = var.cache_port > 0 && var.cache_port <= 65535
    error_message = "Cache port must be between 1 and 65535."
  }
}

# Global Settings
variable "enable_internet_egress" {
  description = "Whether to allow internet egress (0.0.0.0/0) for applicable security groups"
  type        = bool
  default     = true
}

# Web Tier Security Group Variables
variable "web_http_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed HTTP (port 80) access to web tier"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.web_http_ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "web_https_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed HTTPS (port 443) access to web tier"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.web_https_ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "web_custom_ingress_rules" {
  description = "List of custom ingress rules for web tier security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.web_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

# Application Tier Security Group Variables
variable "app_management_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed SSH (port 22) access to application tier"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.app_management_ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "app_custom_ingress_rules" {
  description = "List of custom ingress rules for application tier security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.app_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

# Database Tier Security Group Variables
variable "db_management_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed database access from management systems"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.db_management_ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "db_custom_ingress_rules" {
  description = "List of custom ingress rules for database tier security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.db_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

# Cache Tier Security Group Variables
variable "cache_custom_ingress_rules" {
  description = "List of custom ingress rules for cache tier security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.cache_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

# Management/Bastion Security Group Variables
variable "management_ssh_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed SSH (port 22) access to management hosts"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.management_ssh_ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "management_rdp_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed RDP (port 3389) access to management hosts"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.management_rdp_ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "management_custom_ingress_rules" {
  description = "List of custom ingress rules for management security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.management_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

# Lambda Security Group Variables
variable "lambda_custom_ingress_rules" {
  description = "List of custom ingress rules for Lambda security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.lambda_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

# EKS Security Group Variables
variable "eks_pod_cidr_blocks" {
  description = "List of CIDR blocks used by EKS pods for pod-to-pod communication"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.eks_pod_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "eks_cluster_custom_ingress_rules" {
  description = "List of custom ingress rules for EKS cluster security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.eks_cluster_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

variable "eks_workers_custom_ingress_rules" {
  description = "List of custom ingress rules for EKS worker nodes security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.eks_workers_custom_ingress_rules : 
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "All ingress rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}

# Custom Security Groups
variable "custom_security_groups" {
  description = "Map of custom security groups to create"
  type = map(object({
    description = string
    ingress_rules = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string))
      security_groups = optional(list(string))
      self            = optional(bool, false)
    }))
    egress_rules = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string))
      security_groups = optional(list(string))
      self            = optional(bool, false)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for sg_name, sg_config in var.custom_security_groups : alltrue([
        for rule in concat(sg_config.ingress_rules, sg_config.egress_rules) :
        rule.from_port >= 0 && rule.from_port <= 65535 &&
        rule.to_port >= 0 && rule.to_port <= 65535 &&
        contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
      ])
    ])
    error_message = "All security group rules must have valid ports (0-65535) and protocols (tcp, udp, icmp, -1)."
  }
}