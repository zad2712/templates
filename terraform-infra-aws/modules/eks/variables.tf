# EKS Module - Variables
# Author: Diego A. Zarate

# General Configuration
variable "name_prefix" {
  description = "Name prefix for EKS resources"
  type        = string
  default     = "app"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "Name prefix must be between 1 and 32 characters."
  }
}

variable "tags" {
  description = "A map of tags to assign to EKS resources"
  type        = map(string)
  default     = {}
}

# Logging Configuration
variable "log_retention_in_days" {
  description = "Number of days to retain EKS cluster logs"
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch log retention period."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch logs"
  type        = string
  default     = null
}

# EKS Clusters Configuration
variable "eks_clusters" {
  description = "Map of EKS clusters to create"
  type = map(object({
    # Basic Configuration
    version = optional(string, null)

    # VPC Configuration
    subnet_ids              = list(string)
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, false)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])
    security_group_ids      = optional(list(string), [])

    # Encryption Configuration
    encryption_config = optional(object({
      provider = object({
        key_arn = string
      })
      resources = list(string)
    }), null)

    # Logging Configuration
    enabled_cluster_log_types = optional(list(string), [])

    # Access Configuration
    access_config = optional(object({
      authentication_mode                         = optional(string, "API_AND_CONFIG_MAP")
      bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    }), null)

    # Node Groups
    node_groups = optional(map(object({
      subnet_ids     = list(string)
      capacity_type  = optional(string, "ON_DEMAND")
      ami_type      = optional(string, "AL2_x86_64")
      instance_types = optional(list(string), ["t3.medium"])
      disk_size     = optional(number, 20)

      # Scaling Configuration
      scaling_config = object({
        desired_size = number
        max_size     = number
        min_size     = number
      })

      # Update Configuration
      update_config = optional(object({
        max_unavailable_percentage = optional(number, null)
        max_unavailable           = optional(number, null)
      }), null)

      # Remote Access Configuration
      remote_access = optional(object({
        ec2_ssh_key               = optional(string, null)
        source_security_group_ids = optional(list(string), [])
      }), null)

      # Launch Template
      launch_template = optional(object({
        id      = optional(string, null)
        name    = optional(string, null)
        version = optional(string, null)
      }), null)

      # Labels and Taints
      labels = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])

      tags = optional(map(string), {})
    })), {})

    # Fargate Profiles
    fargate_profiles = optional(map(object({
      subnet_ids = list(string)
      selectors = list(object({
        namespace = string
        labels    = optional(map(string), {})
      }))
      tags = optional(map(string), {})
    })), {})

    # Add-ons
    addons = optional(map(object({
      addon_version                = optional(string, null)
      resolve_conflicts_on_create  = optional(string, "OVERWRITE")
      resolve_conflicts_on_update  = optional(string, "OVERWRITE")
      service_account_role_arn     = optional(string, null)
      configuration_values         = optional(string, null)
      tags                        = optional(map(string), {})
    })), {})

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      length(cluster_config.subnet_ids) >= 2
    ])
    error_message = "EKS clusters must have at least 2 subnets for high availability."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for ng_name, ng_config in cluster_config.node_groups :
        contains(["ON_DEMAND", "SPOT"], ng_config.capacity_type)
      ])
    ])
    error_message = "Node group capacity type must be either 'ON_DEMAND' or 'SPOT'."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for ng_name, ng_config in cluster_config.node_groups :
        contains([
          "AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", 
          "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64",
          "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA",
          "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64",
          "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64"
        ], ng_config.ami_type)
      ])
    ])
    error_message = "Invalid AMI type specified for node group."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for ng_name, ng_config in cluster_config.node_groups :
        ng_config.scaling_config.min_size <= ng_config.scaling_config.desired_size &&
        ng_config.scaling_config.desired_size <= ng_config.scaling_config.max_size &&
        ng_config.scaling_config.min_size >= 0 &&
        ng_config.scaling_config.max_size <= 1000
      ])
    ])
    error_message = "Invalid scaling configuration: min_size <= desired_size <= max_size, and max_size <= 1000."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for ng_name, ng_config in cluster_config.node_groups :
        ng_config.disk_size >= 1 && ng_config.disk_size <= 100
      ])
    ])
    error_message = "Node group disk size must be between 1 and 100 GB."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for ng_name, ng_config in cluster_config.node_groups :
        ng_config.update_config == null || (
          (ng_config.update_config.max_unavailable_percentage == null) != 
          (ng_config.update_config.max_unavailable == null)
        )
      ])
    ])
    error_message = "Update config must specify either max_unavailable_percentage or max_unavailable, not both."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for ng_name, ng_config in cluster_config.node_groups :
        alltrue([
          for taint in ng_config.taints :
          contains(["NoSchedule", "NoExecute", "PreferNoSchedule"], taint.effect)
        ])
      ])
    ])
    error_message = "Taint effect must be one of: NoSchedule, NoExecute, PreferNoSchedule."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      cluster_config.access_config == null || contains([
        "API", "API_AND_CONFIG_MAP", "CONFIG_MAP"
      ], cluster_config.access_config.authentication_mode)
    ])
    error_message = "Authentication mode must be one of: API, API_AND_CONFIG_MAP, CONFIG_MAP."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for addon_name, addon_config in cluster_config.addons :
        addon_config.resolve_conflicts_on_create == null || contains([
          "OVERWRITE", "NONE"
        ], addon_config.resolve_conflicts_on_create)
      ])
    ])
    error_message = "Resolve conflicts on create must be either 'OVERWRITE' or 'NONE'."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for addon_name, addon_config in cluster_config.addons :
        addon_config.resolve_conflicts_on_update == null || contains([
          "OVERWRITE", "NONE", "PRESERVE"
        ], addon_config.resolve_conflicts_on_update)
      ])
    ])
    error_message = "Resolve conflicts on update must be one of: OVERWRITE, NONE, PRESERVE."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for fp_name, fp_config in cluster_config.fargate_profiles :
        length(fp_config.subnet_ids) >= 1
      ])
    ])
    error_message = "Fargate profiles must have at least 1 subnet."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.eks_clusters :
      alltrue([
        for log_type in cluster_config.enabled_cluster_log_types :
        contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
      ])
    ])
    error_message = "Invalid cluster log type. Valid types are: api, audit, authenticator, controllerManager, scheduler."
  }
}