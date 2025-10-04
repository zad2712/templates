# 🌐 Azure VPC (Virtual Network) Module

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider~4.0-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

**Author**: Diego A. Zarate

This module creates a comprehensive Azure Virtual Network (VNet) with subnets, route tables, and network security groups, providing the foundational network infrastructure for your Azure environment.

## 🎯 **Features**

- ✅ **Azure Virtual Network** with custom address spaces
- ✅ **Multiple Subnets** with service endpoints and delegations
- ✅ **Network Security Groups** with comprehensive security rules
- ✅ **Route Tables** with custom routes and associations
- ✅ **DDoS Protection** integration
- ✅ **Network Watcher** integration
- ✅ **Flow Logs** and traffic analytics
- ✅ **Private DNS Zones** integration
- ✅ **VNet Peering** support

## 📋 **Requirements**

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | ~> 4.0 |
| random | ~> 3.6 |

## 🚀 **Usage Examples**

### **Basic VNet with Subnets**

```hcl
module "vpc" {
  source = "../../modules/vpc"
  
  # Basic VNet configuration
  vnet_name           = "myapp-dev-vnet"
  resource_group_name = "myapp-dev-rg"
  location           = "East US"
  address_space      = ["10.0.0.0/16"]
  
  # DNS configuration
  dns_servers = ["168.63.129.16"]  # Azure-provided DNS
  
  # Basic subnets
  subnets = {
    "web" = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    
    "app" = {
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    
    "data" = {
      address_prefixes = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
  }
  
  tags = {
    Environment = "development"
    Project     = "myapp"
    Owner       = "dev-team@company.com"
  }
}
```

### **Production VNet with Advanced Features**

```hcl
module "vpc" {
  source = "../../modules/vpc"
  
  # Production VNet configuration
  vnet_name           = "myapp-prod-vnet"
  resource_group_name = "myapp-prod-networking-rg"
  location           = "East US"
  address_space      = ["10.0.0.0/16"]
  
  # Enhanced DNS with custom servers
  dns_servers = [
    "168.63.129.16",      # Azure DNS
    "10.100.0.4",         # Primary custom DNS
    "10.100.0.5"          # Secondary custom DNS
  ]
  
  # DDoS Protection
  enable_ddos_protection = true
  ddos_protection_plan_id = var.ddos_protection_plan_id
  
  # Network Watcher integration
  enable_network_watcher = true
  enable_flow_logs      = true
  
  # Comprehensive subnets
  subnets = {
    # Web tier subnet
    "web" = {
      address_prefixes = ["10.0.1.0/24"]
      
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Web"
      ]
      
      delegation = []
      
      private_endpoint_network_policies_enabled = false
      private_link_service_network_policies_enabled = false
    }
    
    # Application tier subnet
    "app" = {
      address_prefixes = ["10.0.2.0/24"]
      
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Sql",
        "Microsoft.ServiceBus"
      ]
      
      delegation = []
      
      private_endpoint_network_policies_enabled = false
      private_link_service_network_policies_enabled = false
    }
    
    # Data tier subnet
    "data" = {
      address_prefixes = ["10.0.3.0/24"]
      
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Sql"
      ]
      
      delegation = []
      
      private_endpoint_network_policies_enabled = false
      private_link_service_network_policies_enabled = false
    }
    
    # AKS subnet with delegation
    "aks" = {
      address_prefixes = ["10.0.20.0/22"]  # Larger subnet for node scaling
      
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.ContainerRegistry"
      ]
      
      delegation = [
        {
          name = "aks-delegation"
          service_delegation = {
            name = "Microsoft.ContainerService/managedClusters"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
            ]
          }
        }
      ]
      
      private_endpoint_network_policies_enabled = false
      private_link_service_network_policies_enabled = false
    }
    
    # Azure Functions subnet
    "functions" = {
      address_prefixes = ["10.0.24.0/26"]
      
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Sql"
      ]
      
      delegation = [
        {
          name = "functions-delegation"
          service_delegation = {
            name = "Microsoft.Web/serverFarms"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action"
            ]
          }
        }
      ]
      
      private_endpoint_network_policies_enabled = false
      private_link_service_network_policies_enabled = false
    }
    
    # Private endpoints subnet
    "private-endpoints" = {
      address_prefixes = ["10.0.10.0/24"]
      
      service_endpoints = []
      delegation = []
      
      private_endpoint_network_policies_enabled = false
      private_link_service_network_policies_enabled = false
    }
    
    # Gateway subnet (required name for VPN/ER gateway)
    "GatewaySubnet" = {
      address_prefixes = ["10.0.255.0/27"]  # Minimum /27 required
      
      service_endpoints = []
      delegation = []
      
      private_endpoint_network_policies_enabled = true
      private_link_service_network_policies_enabled = true
    }
    
    # Azure Firewall subnet (required name)
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.254.0/26"]  # Minimum /26 required
      
      service_endpoints = []
      delegation = []
      
      private_endpoint_network_policies_enabled = true
      private_link_service_network_policies_enabled = true
    }
  }
  
  # Network Security Groups
  network_security_groups = {
    "web-nsg" = {
      subnet_associations = ["web"]
      
      security_rules = [
        {
          name                       = "AllowHTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
          description                = "Allow HTTPS from internet"
        },
        {
          name                       = "AllowHTTP"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
          description                = "Allow HTTP from internet"
        },
        {
          name                       = "DenyAllInbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          description                = "Deny all other inbound traffic"
        }
      ]
    }
    
    "app-nsg" = {
      subnet_associations = ["app"]
      
      security_rules = [
        {
          name                       = "AllowWebTier"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "10.0.1.0/24"
          destination_address_prefix = "10.0.2.0/24"
          description                = "Allow web tier to app tier"
        },
        {
          name                       = "DenyAllInbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          description                = "Deny all other inbound traffic"
        }
      ]
    }
  }
  
  # Route tables
  route_tables = {
    "web-routes" = {
      subnet_associations = ["web"]
      
      routes = [
        {
          name           = "ToFirewall"
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.254.4"  # Azure Firewall IP
        }
      ]
    }
  }
  
  # Private DNS Zones
  private_dns_zones = {
    "privatelink.blob.core.windows.net" = {
      virtual_network_links = {
        "main" = {
          virtual_network_id   = "self"  # Reference to current VNet
          registration_enabled = false
        }
      }
    }
    
    "internal.company.com" = {
      virtual_network_links = {
        "main" = {
          virtual_network_id   = "self"
          registration_enabled = true
        }
      }
      
      a_records = {
        "api" = {
          ttl     = 300
          records = ["10.0.2.10"]
        }
      }
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team@company.com"
    CostCenter  = "infrastructure"
  }
}
```

### **Hub-Spoke Architecture**

```hcl
# Hub VNet
module "hub_vpc" {
  source = "../../modules/vpc"
  
  vnet_name           = "hub-vnet"
  resource_group_name = "networking-hub-rg"
  location           = "East US"
  address_space      = ["10.100.0.0/16"]
  
  subnets = {
    "GatewaySubnet" = {
      address_prefixes = ["10.100.255.0/27"]
    }
    
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.100.254.0/26"]
    }
    
    "shared-services" = {
      address_prefixes = ["10.100.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
  }
  
  # Hub services configuration
  enable_vpn_gateway    = true
  enable_azure_firewall = true
  
  tags = {
    Environment = "shared"
    Role        = "hub"
  }
}

# Spoke VNet 1
module "spoke1_vpc" {
  source = "../../modules/vpc"
  
  vnet_name           = "spoke1-vnet"
  resource_group_name = "app1-rg"
  location           = "East US"
  address_space      = ["10.1.0.0/16"]
  
  subnets = {
    "web"  = { address_prefixes = ["10.1.1.0/24"] }
    "app"  = { address_prefixes = ["10.1.2.0/24"] }
    "data" = { address_prefixes = ["10.1.3.0/24"] }
  }
  
  # Peering to hub
  vnet_peering = {
    "to-hub" = {
      remote_virtual_network_id = module.hub_vpc.virtual_network_id
      allow_virtual_network_access = true
      allow_forwarded_traffic     = true
      allow_gateway_transit       = false
      use_remote_gateways         = true
    }
  }
  
  tags = {
    Environment = "production"
    Role        = "spoke"
    Application = "app1"
  }
}
```

## 📊 **Input Variables**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vnet_name` | Name of the virtual network | `string` | n/a | yes |
| `resource_group_name` | Name of the resource group | `string` | n/a | yes |
| `location` | Azure region for resources | `string` | n/a | yes |
| `address_space` | Address space for the VNet | `list(string)` | n/a | yes |
| `dns_servers` | List of DNS servers | `list(string)` | `[]` | no |
| `enable_ddos_protection` | Enable DDoS protection | `bool` | `false` | no |
| `ddos_protection_plan_id` | DDoS protection plan ID | `string` | `null` | no |
| `enable_network_watcher` | Enable Network Watcher | `bool` | `true` | no |
| `enable_flow_logs` | Enable NSG flow logs | `bool` | `false` | no |
| `flow_logs_storage_account_id` | Storage account for flow logs | `string` | `null` | no |
| `subnets` | Map of subnet configurations | `map(object)` | `{}` | no |
| `network_security_groups` | Map of NSG configurations | `map(object)` | `{}` | no |
| `route_tables` | Map of route table configurations | `map(object)` | `{}` | no |
| `private_dns_zones` | Map of private DNS zone configurations | `map(object)` | `{}` | no |
| `vnet_peering` | Map of VNet peering configurations | `map(object)` | `{}` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

### **Subnet Object Structure**

```hcl
subnets = {
  "subnet-name" = {
    address_prefixes = ["10.0.1.0/24"]     # Required: List of address prefixes
    
    service_endpoints = [                   # Optional: Service endpoints
      "Microsoft.Storage",
      "Microsoft.KeyVault",
      "Microsoft.Sql"
    ]
    
    delegation = [                          # Optional: Subnet delegation
      {
        name = "delegation-name"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    ]
    
    # Optional: Private endpoint policies (default: true)
    private_endpoint_network_policies_enabled = false
    private_link_service_network_policies_enabled = false
  }
}
```

### **Network Security Group Object Structure**

```hcl
network_security_groups = {
  "nsg-name" = {
    subnet_associations = ["subnet1", "subnet2"]  # Subnets to associate
    
    security_rules = [
      {
        name                       = "AllowHTTPS"
        priority                   = 100
        direction                  = "Inbound"        # Inbound | Outbound
        access                     = "Allow"          # Allow | Deny
        protocol                   = "Tcp"            # Tcp | Udp | * 
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Allow HTTPS traffic"
      }
    ]
  }
}
```

## 📤 **Outputs**

| Name | Description |
|------|-------------|
| `virtual_network_id` | ID of the virtual network |
| `virtual_network_name` | Name of the virtual network |
| `virtual_network_address_space` | Address space of the virtual network |
| `subnet_ids` | Map of subnet names to IDs |
| `subnet_address_prefixes` | Map of subnet names to address prefixes |
| `network_security_group_ids` | Map of NSG names to IDs |
| `route_table_ids` | Map of route table names to IDs |
| `private_dns_zone_ids` | Map of private DNS zone names to IDs |
| `network_watcher_id` | ID of the Network Watcher (if created) |

## 🔧 **Advanced Configuration**

### **Service Endpoints**

Enable direct access to Azure services without routing through the internet:

```hcl
subnets = {
  "app-subnet" = {
    address_prefixes = ["10.0.2.0/24"]
    
    service_endpoints = [
      "Microsoft.Storage",          # Azure Storage
      "Microsoft.Sql",              # Azure SQL Database
      "Microsoft.KeyVault",         # Azure Key Vault
      "Microsoft.ServiceBus",       # Azure Service Bus
      "Microsoft.EventHub",         # Azure Event Hubs
      "Microsoft.CosmosDB",         # Azure Cosmos DB
      "Microsoft.ContainerRegistry", # Azure Container Registry
      "Microsoft.Web"               # Azure App Service
    ]
  }
}
```

### **Subnet Delegation**

Delegate subnets to specific Azure services:

```hcl
# AKS subnet delegation
"aks-subnet" = {
  address_prefixes = ["10.0.20.0/22"]
  
  delegation = [
    {
      name = "aks-delegation"
      service_delegation = {
        name = "Microsoft.ContainerService/managedClusters"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
        ]
      }
    }
  ]
}

# Azure SQL Managed Instance subnet delegation
"sql-mi-subnet" = {
  address_prefixes = ["10.0.30.0/24"]
  
  delegation = [
    {
      name = "sql-mi-delegation"
      service_delegation = {
        name = "Microsoft.Sql/managedInstances"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
          "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
        ]
      }
    }
  ]
}
```

### **Custom Route Tables**

Implement custom routing for traffic steering:

```hcl
route_tables = {
  "firewall-routes" = {
    subnet_associations = ["web", "app"]
    
    routes = [
      {
        name           = "DefaultRoute"
        address_prefix = "0.0.0.0/0"
        next_hop_type  = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.254.4"  # Azure Firewall private IP
      },
      {
        name           = "ToOnPremises"
        address_prefix = "192.168.0.0/16"
        next_hop_type  = "VirtualNetworkGateway"
        next_hop_in_ip_address = null
      }
    ]
  }
}
```

## 🔒 **Security Best Practices**

### **Network Segmentation**

- **Tier Separation**: Use separate subnets for web, app, and data tiers
- **Least Privilege**: Implement restrictive NSG rules by default
- **Defense in Depth**: Use multiple security layers (NSG + Azure Firewall)

### **Private Connectivity**

- **Private Endpoints**: Use for Azure services instead of public endpoints
- **Service Endpoints**: Enable for secure Azure service access
- **Private DNS**: Implement for internal name resolution

### **Monitoring & Alerting**

```hcl
# Enable comprehensive monitoring
enable_network_watcher = true
enable_flow_logs      = true

# Flow logs configuration
flow_logs_storage_account_id = "/subscriptions/.../storageAccounts/logs"
flow_logs_workspace_id      = "/subscriptions/.../workspaces/analytics"
```

## 📊 **Monitoring & Troubleshooting**

### **Network Connectivity Tests**

```bash
# Test connectivity between resources
az network watcher test-connectivity \
  --source-resource "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm}" \
  --dest-address "10.0.2.10" \
  --dest-port 8080

# Check effective routes
az network nic show-effective-route-table \
  --resource-group "myapp-rg" \
  --name "vm-nic"

# View effective NSG rules
az network nic list-effective-nsg \
  --resource-group "myapp-rg" \
  --name "vm-nic"
```

### **Flow Logs Analysis**

```kusto
// Top traffic flows
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| summarize FlowCount = count() by SrcIP_s, DestIP_s, DestPort_d
| top 20 by FlowCount desc

// Blocked traffic analysis
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| where FlowStatus_s == "D"  // Denied
| summarize BlockedFlows = count() by NSGRule_s, SrcIP_s
| sort by BlockedFlows desc
```

## 🔄 **Migration & Upgrade**

### **From Basic to Advanced Configuration**

```bash
# 1. Add DDoS protection
terraform plan -target=azurerm_virtual_network.main

# 2. Enable Network Watcher
terraform plan -target=azurerm_network_watcher.main

# 3. Add flow logs
terraform plan -target=azurerm_network_watcher_flow_log.main

# 4. Update NSG rules
terraform plan -target=azurerm_network_security_group.main
```

## 🚀 **Performance Optimization**

### **Subnet Sizing Guidelines**

| Workload Type | Recommended Subnet Size | Max Resources |
|---------------|------------------------|---------------|
| Web Tier | /24 (254 IPs) | 200+ VMs/Instances |
| App Tier | /24 (254 IPs) | 200+ VMs/Instances |
| Data Tier | /25 (126 IPs) | 100+ VMs/Instances |
| AKS Cluster | /22 (1022 IPs) | 1000+ Pods |
| Functions | /26 (62 IPs) | 50+ Instances |
| Private Endpoints | /24 (254 IPs) | 200+ Endpoints |

### **Performance Monitoring**

- Monitor VNet capacity and IP address utilization
- Track NSG rule performance and hit rates
- Analyze flow logs for traffic patterns
- Monitor Azure Firewall performance metrics

---

**🔗 Related Modules**: [Security Groups](../security-groups/README.md) | [VPC Endpoints](../vpc-endpoints/README.md) | [Transit Gateway](../transit-gateway/README.md)