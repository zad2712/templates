# =============================================================================
# EKS MODULE VARIABLES
# =============================================================================

variable "create_cluster" {
  description = "Whether to create the EKS cluster"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "default-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

# =============================================================================
# NODE GROUPS CONFIGURATION
# =============================================================================

variable "node_groups" {
  description = "Map of EKS managed node group definitions"
  type = map(object({
    subnet_ids                 = list(string)
    instance_types             = list(string)
    ami_type                   = optional(string, "AL2_x86_64")
    capacity_type              = optional(string, "SPOT") # Use SPOT for cost optimization
    disk_size                  = optional(number, 20)
    desired_size               = optional(number, 1)
    max_size                   = optional(number, 3)
    min_size                   = optional(number, 1)
    max_unavailable_percentage = optional(number, 25)
    launch_template_id         = optional(string)
    launch_template_version    = optional(string, "$Latest")
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    labels = optional(map(string), {})
    tags   = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# FARGATE PROFILES CONFIGURATION
# =============================================================================

variable "fargate_profiles" {
  description = "Map of EKS Fargate Profile definitions"
  type = map(object({
    subnet_ids = list(string)
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# EKS ADDONS CONFIGURATION
# =============================================================================

variable "cluster_addons" {
  description = "Map of cluster addon configurations"
  type = map(object({
    addon_version            = optional(string)
    resolve_conflicts        = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string)
  }))
  default = {
    # AWS VPC CNI
    vpc-cni = {
      addon_version = null # Use cluster default
    }
    # CoreDNS
    coredns = {
      addon_version = null # Use cluster default
    }
    # kube-proxy
    kube-proxy = {
      addon_version = null # Use cluster default
    }
    # AWS EBS CSI Driver
    aws-ebs-csi-driver = {
      addon_version = null # Use cluster default
    }
  }
}

# =============================================================================
# MARKETPLACE ADDONS CONFIGURATION
# =============================================================================

variable "enable_marketplace_addons" {
  description = "Enable installation of common marketplace addons"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller" {
  description = "Configuration for AWS Load Balancer Controller"
  type = object({
    enabled              = optional(bool, true)
    version              = optional(string, "v2.6.0")
    service_account_name = optional(string, "aws-load-balancer-controller")
    namespace            = optional(string, "kube-system")
  })
  default = {}
}

variable "cluster_autoscaler" {
  description = "Configuration for Cluster Autoscaler"
  type = object({
    enabled              = optional(bool, true)
    version              = optional(string, "1.27.0")
    service_account_name = optional(string, "cluster-autoscaler")
    namespace            = optional(string, "kube-system")
  })
  default = {}
}

variable "metrics_server" {
  description = "Configuration for Metrics Server"
  type = object({
    enabled   = optional(bool, true)
    version   = optional(string, "v0.6.4")
    namespace = optional(string, "kube-system")
  })
  default = {}
}

variable "ingress_nginx" {
  description = "Configuration for NGINX Ingress Controller"
  type = object({
    enabled   = optional(bool, false)
    version   = optional(string, "4.8.0")
    namespace = optional(string, "ingress-nginx")
  })
  default = {}
}

variable "external_dns" {
  description = "Configuration for External DNS"
  type = object({
    enabled              = optional(bool, false)
    version              = optional(string, "1.13.0")
    service_account_name = optional(string, "external-dns")
    namespace            = optional(string, "kube-system")
    domain_filters       = optional(list(string), [])
  })
  default = {}
}

# =============================================================================
# COMMON VARIABLES
# =============================================================================

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
