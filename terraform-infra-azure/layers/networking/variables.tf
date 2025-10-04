# =============================================================================
# NETWORKING LAYER VARIABLES
# =============================================================================

# Project Configuration
variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "myproject"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric and max 20 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "At least one address space must be specified."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers for the virtual network"
  type        = list(string)
  default     = []
}

variable "subnet_service_endpoints" {
  description = "Service endpoints for each subnet"
  type        = map(list(string))
  default = {
    web               = ["Microsoft.Storage", "Microsoft.KeyVault"]
    app               = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
    data              = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
    aks               = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
    gateway           = []
    private_endpoints = []
  }
}

# Network Security Group Rules
variable "nsg_rules" {
  description = "Network security group rules for each subnet"
  type        = map(list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  })))
  default = {
    web = [
      {
        name                       = "AllowHTTP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "AllowHTTPS"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
    app = [
      {
        name                       = "AllowAppPort"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "10.0.1.0/24"  # web subnet
        destination_address_prefix = "*"
      }
    ]
    data = [
      {
        name                       = "AllowSQL"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.0.2.0/24"  # app subnet
        destination_address_prefix = "*"
      }
    ]
    aks = [
      {
        name                       = "AllowAKS"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
    ]
    gateway = [
      {
        name                       = "AllowHTTP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "AllowHTTPS"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "AllowGatewayManager"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "65200-65535"
        source_address_prefix      = "GatewayManager"
        destination_address_prefix = "*"
      }
    ]
    private_endpoints = []
  }
}

# Application Gateway Configuration
variable "enable_application_gateway" {
  description = "Enable Application Gateway"
  type        = bool
  default     = true
}

variable "app_gateway_sku_name" {
  description = "SKU name for Application Gateway"
  type        = string
  default     = "WAF_v2"

  validation {
    condition     = contains(["Standard_Small", "Standard_Medium", "Standard_Large", "WAF_Medium", "WAF_Large", "Standard_v2", "WAF_v2"], var.app_gateway_sku_name)
    error_message = "SKU name must be a valid Application Gateway SKU."
  }
}

variable "app_gateway_sku_tier" {
  description = "SKU tier for Application Gateway"
  type        = string
  default     = "WAF_v2"

  validation {
    condition     = contains(["Standard", "WAF", "Standard_v2", "WAF_v2"], var.app_gateway_sku_tier)
    error_message = "SKU tier must be a valid Application Gateway tier."
  }
}

variable "app_gateway_sku_capacity" {
  description = "SKU capacity for Application Gateway"
  type        = number
  default     = 2

  validation {
    condition     = var.app_gateway_sku_capacity >= 1 && var.app_gateway_sku_capacity <= 125
    error_message = "SKU capacity must be between 1 and 125."
  }
}

variable "app_gateway_waf_enabled" {
  description = "Enable WAF for Application Gateway"
  type        = bool
  default     = true
}

variable "app_gateway_waf_mode" {
  description = "WAF mode for Application Gateway"
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.app_gateway_waf_mode)
    error_message = "WAF mode must be either Detection or Prevention."
  }
}

# Network Monitoring
variable "enable_network_watcher" {
  description = "Enable Network Watcher"
  type        = bool
  default     = true
}

# Private DNS Zones
variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type        = list(string)
  default = [
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurecr.io",
    "privatelink.redis.cache.windows.net"
  ]
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "infrastructure"
  }
}