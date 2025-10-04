# =============================================================================
# AKS MODULE VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be either Free or Standard."
  }
}

variable "automatic_channel_upgrade" {
  description = "Automatic channel upgrade"
  type        = string
  default     = "patch"

  validation {
    condition     = contains(["patch", "rapid", "node-image", "stable", "none"], var.automatic_channel_upgrade)
    error_message = "Automatic channel upgrade must be one of: patch, rapid, node-image, stable, none."
  }
}

variable "node_os_channel_upgrade" {
  description = "Node OS channel upgrade"
  type        = string
  default     = "NodeImage"

  validation {
    condition     = contains(["NodeImage", "None", "Unmanaged"], var.node_os_channel_upgrade)
    error_message = "Node OS channel upgrade must be one of: NodeImage, None, Unmanaged."
  }
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private cluster"
  type        = string
  default     = "System"
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

# Default Node Pool Configuration
variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name                = string
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    availability_zones  = list(string)
    os_disk_size_gb     = number
    os_disk_type        = string
    max_surge           = string
    node_labels         = map(string)
    node_taints         = list(string)
  })
  default = {
    name                = "default"
    vm_size             = "Standard_D2s_v3"
    node_count          = 2
    min_count           = 1
    max_count           = 5
    enable_auto_scaling = true
    availability_zones  = ["1", "2", "3"]
    os_disk_size_gb     = 100
    os_disk_type        = "Managed"
    max_surge           = "10%"
    node_labels         = {}
    node_taints         = []
  }
}

# Additional Node Pools
variable "additional_node_pools" {
  description = "Additional node pools"
  type = map(object({
    name                = string
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    availability_zones  = list(string)
    os_disk_size_gb     = number
    os_disk_type        = string
    os_type             = string
    max_surge           = string
    node_labels         = map(string)
    node_taints         = list(string)
    tags                = map(string)
  }))
  default = {}
}

# Identity Configuration
variable "identity_type" {
  description = "Type of identity for AKS cluster"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "ServicePrincipal"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or ServicePrincipal."
  }
}

variable "user_assigned_identity_ids" {
  description = "List of user assigned identity IDs"
  type        = list(string)
  default     = []
}

variable "service_principal" {
  description = "Service principal configuration"
  type = object({
    client_id     = string
    client_secret = string
  })
  default = {
    client_id     = ""
    client_secret = ""
  }
}

# Network Configuration
variable "network_plugin" {
  description = "Network plugin for AKS"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "Network plugin must be azure, kubenet, or none."
  }
}

variable "network_plugin_mode" {
  description = "Network plugin mode"
  type        = string
  default     = null
}

variable "network_policy" {
  description = "Network policy for AKS"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "Network policy must be azure, calico, or cilium."
  }
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.250.0.10"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.250.0.0/16"
}

variable "outbound_type" {
  description = "Outbound type for AKS"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.outbound_type)
    error_message = "Outbound type must be loadBalancer, userDefinedRouting, managedNATGateway, or userAssignedNATGateway."
  }
}

# Azure AD RBAC Configuration
variable "enable_azure_ad_rbac" {
  description = "Enable Azure AD RBAC"
  type        = bool
  default     = true
}

variable "azure_ad_admin_group_object_ids" {
  description = "Azure AD admin group object IDs"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC"
  type        = bool
  default     = true
}

variable "enable_rbac" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

# Add-ons Configuration
variable "http_application_routing_enabled" {
  description = "Enable HTTP application routing"
  type        = bool
  default     = false
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = true
}

variable "enable_open_service_mesh" {
  description = "Enable Open Service Mesh add-on"
  type        = bool
  default     = false
}

variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault secrets provider"
  type        = bool
  default     = true
}

variable "key_vault_secrets_provider" {
  description = "Key Vault secrets provider configuration"
  type = object({
    secret_rotation_enabled  = bool
    secret_rotation_interval = string
  })
  default = {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
}

# Monitoring Configuration
variable "enable_log_analytics" {
  description = "Enable Log Analytics integration"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

# Ingress Application Gateway
variable "enable_ingress_application_gateway" {
  description = "Enable Ingress Application Gateway"
  type        = bool
  default     = false
}

variable "application_gateway_id" {
  description = "Application Gateway ID"
  type        = string
  default     = null
}

variable "application_gateway_name" {
  description = "Application Gateway name"
  type        = string
  default     = null
}

variable "application_gateway_subnet_cidr" {
  description = "Application Gateway subnet CIDR"
  type        = string
  default     = null
}

variable "application_gateway_subnet_id" {
  description = "Application Gateway subnet ID"
  type        = string
  default     = null
}

# Auto Scaler Profile
variable "enable_auto_scaler_profile" {
  description = "Enable auto scaler profile"
  type        = bool
  default     = true
}

variable "auto_scaler_profile" {
  description = "Auto scaler profile configuration"
  type = object({
    balance_similar_node_groups      = bool
    expander                        = string
    max_graceful_termination_sec    = string
    max_node_provisioning_time      = string
    max_unready_nodes              = number
    max_unready_percentage         = number
    new_pod_scale_up_delay         = string
    scale_down_delay_after_add     = string
    scale_down_delay_after_delete  = string
    scale_down_delay_after_failure = string
    scan_interval                  = string
    scale_down_unneeded            = string
    scale_down_unready             = string
    scale_down_utilization_threshold = number
    empty_bulk_delete_max          = number
    skip_nodes_with_local_storage  = bool
    skip_nodes_with_system_pods    = bool
  })
  default = {
    balance_similar_node_groups      = false
    expander                        = "random"
    max_graceful_termination_sec    = "600"
    max_node_provisioning_time      = "15m"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "10s"
    scale_down_delay_after_add     = "10m"
    scale_down_delay_after_delete  = "10s"
    scale_down_delay_after_failure = "3m"
    scan_interval                  = "10s"
    scale_down_unneeded            = "10m"
    scale_down_unready             = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max          = 10
    skip_nodes_with_local_storage  = true
    skip_nodes_with_system_pods    = true
  }
}

# Maintenance Window
variable "enable_maintenance_window" {
  description = "Enable maintenance window"
  type        = bool
  default     = false
}

variable "maintenance_window_allowed" {
  description = "Maintenance window allowed times"
  type = list(object({
    day   = string
    hours = list(number)
  }))
  default = []
}

variable "maintenance_window_not_allowed" {
  description = "Maintenance window not allowed times"
  type = list(object({
    end   = string
    start = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to AKS cluster"
  type        = map(string)
  default     = {}
}