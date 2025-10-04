# 🌐 Networking Layer - VPC, Subnets & Connectivity

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider~4.0-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

**Author**: Diego A. Zarate

The **Networking Layer** establishes the foundation of your Azure infrastructure by creating Virtual Networks (VNets), subnets, security groups, and connectivity components. This layer provides secure, scalable, and well-architected network infrastructure for all other layers.

## 🎯 **Layer Overview**

> **Purpose**: Establish network foundation with VNets, subnets, NSGs, and connectivity  
> **Dependencies**: **Networking Layer** → Security Layer → Data Layer → Compute Layer  
> **Deployment Time**: ~3-5 minutes  
> **Resources**: Virtual Networks, Subnets, NSGs, Route Tables, VPN Gateway, Private DNS Zones

## 🏗️ **Architecture Components**

### **🔗 Virtual Network (VNet)**
- **Address Space**: RFC 1918 compliant CIDR blocks for secure private networking
- **Multi-Region**: Primary and secondary regions for disaster recovery
- **Peering**: Hub-and-spoke topology for scalable network architecture
- **Segmentation**: Environment and workload isolation through subnet design

### **🛡️ Network Security Groups (NSGs)**
- **Traffic Filtering**: Stateful packet filtering with allow/deny rules
- **Micro-segmentation**: Granular security controls at subnet and NIC levels
- **Application Security Groups**: Logical grouping of resources for simplified rule management
- **DDoS Protection**: Azure DDoS Protection Standard integration

### **📍 Subnets & Routing**
- **Tier Separation**: Web, application, and data tier isolation
- **Private Endpoints**: Dedicated subnets for Azure service private connectivity
- **Gateway Subnet**: VPN and ExpressRoute gateway connectivity
- **User-Defined Routes**: Custom routing for traffic steering and inspection

### **🔒 Private DNS Zones**
- **Service Discovery**: Internal DNS resolution for private endpoints
- **Hybrid Connectivity**: On-premises DNS integration
- **Auto-Registration**: Automatic DNS record management for Azure resources
- **Zone Linking**: Multi-VNet DNS resolution

### **🌉 Connectivity Services**
- **VPN Gateway**: Site-to-site and point-to-site VPN connectivity
- **ExpressRoute**: Dedicated private network connection to Azure
- **Azure Firewall**: Centralized network security and traffic filtering
- **Load Balancers**: Traffic distribution and high availability

## 📋 **Network Services Overview**

| Service | Purpose | High Availability | Private Access | Traffic Filtering | Monitoring |
|---------|---------|------------------|----------------|------------------|------------|
| 🔗 **Virtual Network** | Network foundation | ✅ | ✅ | ✅ | ✅ |
| 🛡️ **Network Security Group** | Traffic filtering | ✅ | ✅ | ✅ | ✅ |
| 📍 **Subnet** | Network segmentation | ✅ | ✅ | ✅ | ✅ |
| 🔒 **Private DNS Zone** | Internal DNS | ✅ | ✅ | N/A | ✅ |
| 🌉 **VPN Gateway** | Hybrid connectivity | ✅ | ✅ | ✅ | ✅ |
| 🏢 **ExpressRoute** | Dedicated connection | ✅ | ✅ | ✅ | ✅ |
| 🔥 **Azure Firewall** | Network security | ✅ | ✅ | ✅ | ✅ |
| ⚖️ **Load Balancer** | Traffic distribution | ✅ | ✅ | ✅ | ✅ |

## 🚀 **Quick Start**

### **1. Deploy Complete Networking Layer**

```bash
# Deploy all networking components
cd layers/networking/environments/dev
terraform init -backend-config=backend.conf
terraform plan -var-file=terraform.auto.tfvars
terraform apply -var-file=terraform.auto.tfvars

# Or use the management script
./terraform-manager.sh deploy-networking dev
```

### **2. Deploy Specific Components**

```bash
# Deploy only VNet and subnets
terraform apply -target=module.vpc -target=module.subnets -var-file=terraform.auto.tfvars

# Deploy security components
terraform apply -target=module.network_security_groups -target=module.route_tables -var-file=terraform.auto.tfvars
```

## 🔧 **Configuration Examples**

### **🔗 Production Virtual Network**

```hcl
# terraform.auto.tfvars - Production VNet Configuration

# Primary VNet configuration
vnet_address_space = ["10.0.0.0/16"]               # 65,536 IP addresses
vnet_location     = "East US"                       # Primary region

# DNS settings
vnet_dns_servers = [
  "168.63.129.16",                                  # Azure-provided DNS
  "10.100.0.4",                                     # Custom DNS server 1
  "10.100.0.5"                                      # Custom DNS server 2
]

# DDoS Protection
enable_ddos_protection = true
ddos_protection_plan_id = "/subscriptions/{subscription-id}/resourceGroups/shared-rg/providers/Microsoft.Network/ddosProtectionPlans/mycompany-ddos-plan"

# Network security features
enable_vm_protection = true                         # VM protection against malicious traffic
enable_network_watcher = true                       # Network monitoring and diagnostics

# Subnets configuration with security and routing
subnets = {
  # Web tier - Public-facing components
  "web" = {
    address_prefixes = ["10.0.1.0/24"]             # 254 usable IPs
    
    # Service endpoints for direct Azure service access
    service_endpoints = [
      "Microsoft.Storage",                          # Direct storage access
      "Microsoft.KeyVault",                         # Direct Key Vault access
      "Microsoft.Sql"                               # Direct SQL Database access
    ]
    
    # Delegate subnet for specific services
    delegation = []                                 # No delegation for web tier
    
    # Private endpoint support
    private_endpoint_network_policies_enabled = false  # Allow private endpoints
    private_link_service_network_policies_enabled = false
  }
  
  # Application tier - Private application components
  "app" = {
    address_prefixes = ["10.0.2.0/24"]             # 254 usable IPs
    
    service_endpoints = [
      "Microsoft.Storage",
      "Microsoft.KeyVault",
      "Microsoft.Sql",
      "Microsoft.ServiceBus",                       # Service Bus integration
      "Microsoft.EventHub"                          # Event Hub integration
    ]
    
    delegation = []
    
    private_endpoint_network_policies_enabled = false
    private_link_service_network_policies_enabled = false
  }
  
  # Data tier - Database and storage components
  "data" = {
    address_prefixes = ["10.0.3.0/24"]             # 254 usable IPs
    
    service_endpoints = [
      "Microsoft.Storage",
      "Microsoft.KeyVault",
      "Microsoft.Sql"
    ]
    
    delegation = []
    
    private_endpoint_network_policies_enabled = false
    private_link_service_network_policies_enabled = false
  }
  
  # Private endpoints subnet - Dedicated for private endpoint NICs
  "private-endpoints" = {
    address_prefixes = ["10.0.10.0/24"]            # 254 usable IPs
    
    service_endpoints = []                          # No service endpoints needed
    delegation = []
    
    private_endpoint_network_policies_enabled = false  # Required for private endpoints
    private_link_service_network_policies_enabled = false
  }
  
  # AKS subnet - Azure Kubernetes Service nodes
  "aks" = {
    address_prefixes = ["10.0.20.0/22"]            # 1,022 usable IPs (for node scaling)
    
    service_endpoints = [
      "Microsoft.Storage",
      "Microsoft.KeyVault",
      "Microsoft.ContainerRegistry"                 # Container registry access
    ]
    
    # Delegate to AKS service
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
  
  # Azure Functions subnet - Dedicated for Function App VNet integration
  "functions" = {
    address_prefixes = ["10.0.24.0/26"]            # 62 usable IPs
    
    service_endpoints = [
      "Microsoft.Storage",
      "Microsoft.KeyVault",
      "Microsoft.Sql"
    ]
    
    # Delegate to App Service (Functions)
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
  
  # Gateway subnet - VPN and ExpressRoute gateways (fixed name required)
  "GatewaySubnet" = {
    address_prefixes = ["10.0.255.0/27"]           # 30 usable IPs (minimum /27 required)
    
    service_endpoints = []                          # No service endpoints for gateway subnet
    delegation = []                                 # No delegation allowed
    
    private_endpoint_network_policies_enabled = true   # Default for gateway subnet
    private_link_service_network_policies_enabled = true
  }
  
  # Azure Firewall subnet (fixed name required if using Azure Firewall)
  "AzureFirewallSubnet" = {
    address_prefixes = ["10.0.254.0/26"]           # 62 usable IPs (minimum /26 required)
    
    service_endpoints = []
    delegation = []
    
    private_endpoint_network_policies_enabled = true
    private_link_service_network_policies_enabled = true
  }
}
```

### **🛡️ Production Network Security Groups**

```hcl
# Network Security Groups with comprehensive rules
network_security_groups = {
  # Web tier NSG - Internet-facing components
  "web-nsg" = {
    subnet_associations = ["web"]                   # Associate with web subnet
    
    security_rules = [
      # Inbound rules
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
        description                = "Allow HTTPS traffic from internet"
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
        description                = "Allow HTTP traffic from internet (redirect to HTTPS)"
      },
      {
        name                       = "AllowLoadBalancerHealth"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
        description                = "Allow Azure Load Balancer health probes"
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
  
  # Application tier NSG - Internal application components
  "app-nsg" = {
    subnet_associations = ["app"]
    
    security_rules = [
      # Allow traffic from web tier
      {
        name                       = "AllowWebTier"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"         # Application port
        source_address_prefix      = "10.0.1.0/24"  # Web subnet
        destination_address_prefix = "10.0.2.0/24"  # App subnet
        description                = "Allow web tier to app tier communication"
      },
      {
        name                       = "AllowAKSTier"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080-8090"    # Application port range
        source_address_prefix      = "10.0.20.0/22" # AKS subnet
        destination_address_prefix = "10.0.2.0/24"  # App subnet
        description                = "Allow AKS to app tier communication"
      },
      # Allow outbound to data tier
      {
        name                       = "AllowDataTier"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"         # SQL Server port
        source_address_prefix      = "10.0.2.0/24"  # App subnet
        destination_address_prefix = "10.0.3.0/24"  # Data subnet
        description                = "Allow app tier to data tier communication"
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
  
  # Data tier NSG - Database and storage components
  "data-nsg" = {
    subnet_associations = ["data"]
    
    security_rules = [
      # Allow traffic from application tier only
      {
        name                       = "AllowAppTier"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"         # SQL Server
        source_address_prefix      = "10.0.2.0/24"  # App subnet
        destination_address_prefix = "10.0.3.0/24"  # Data subnet
        description                = "Allow app tier to SQL Server"
      },
      {
        name                       = "AllowAKSToData"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.0.20.0/22" # AKS subnet
        destination_address_prefix = "10.0.3.0/24"  # Data subnet
        description                = "Allow AKS to SQL Server"
      },
      {
        name                       = "AllowRedis"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "6380"         # Redis SSL port
        source_address_prefix      = "10.0.2.0/24"  # App subnet
        destination_address_prefix = "10.0.3.0/24"  # Data subnet
        description                = "Allow Redis cache access"
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
  
  # AKS NSG - Kubernetes cluster security
  "aks-nsg" = {
    subnet_associations = ["aks"]
    
    security_rules = [
      # Allow Kubernetes API server
      {
        name                       = "AllowKubernetesAPI"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "10.0.0.0/16"   # Allow from entire VNet
        destination_address_prefix = "10.0.20.0/22"  # AKS subnet
        description                = "Allow Kubernetes API server access"
      },
      {
        name                       = "AllowNodeCommunication"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "10.0.20.0/22"  # AKS subnet
        destination_address_prefix = "10.0.20.0/22"  # AKS subnet
        description                = "Allow node-to-node communication"
      },
      # Allow outbound to Azure services
      {
        name                       = "AllowAzureServices"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "10.0.20.0/22"
        destination_address_prefix = "AzureCloud"
        description                = "Allow access to Azure services"
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
  
  # Private endpoints NSG - Minimal rules for private connectivity
  "private-endpoints-nsg" = {
    subnet_associations = ["private-endpoints"]
    
    security_rules = [
      {
        name                       = "AllowVNetInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
        description                = "Allow VNet traffic to private endpoints"
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
```

### **🔒 Production Private DNS Zones**

```hcl
# Private DNS zones for internal service discovery
private_dns_zones = {
  # Storage Account private DNS
  "privatelink.blob.core.windows.net" = {
    virtual_network_links = {
      "myproject-prod-vnet" = {
        virtual_network_id   = module.vpc.virtual_network_id
        registration_enabled = false              # Manual DNS record management
        
        tags = {
          Service = "Storage"
          Purpose = "Private endpoint DNS resolution"
        }
      }
    }
    
    # A records for storage accounts
    a_records = {
      "myprojectprodstorage" = {
        ttl     = 300
        records = ["10.0.10.10"]               # Private endpoint IP
        
        tags = {
          Service = "Storage"
          Type    = "Blob"
        }
      }
    }
  }
  
  # SQL Database private DNS
  "privatelink.database.windows.net" = {
    virtual_network_links = {
      "myproject-prod-vnet" = {
        virtual_network_id   = module.vpc.virtual_network_id
        registration_enabled = false
      }
    }
    
    a_records = {
      "myproject-prod-sql" = {
        ttl     = 300
        records = ["10.0.10.11"]               # Private endpoint IP
        
        tags = {
          Service = "SQL"
          Type    = "Database"
        }
      }
    }
  }
  
  # Key Vault private DNS
  "privatelink.vaultcore.azure.net" = {
    virtual_network_links = {
      "myproject-prod-vnet" = {
        virtual_network_id   = module.vpc.virtual_network_id
        registration_enabled = false
      }
    }
    
    a_records = {
      "myproject-prod-kv" = {
        ttl     = 300
        records = ["10.0.10.12"]               # Private endpoint IP
        
        tags = {
          Service = "KeyVault"
          Type    = "Vault"
        }
      }
    }
  }
  
  # Service Bus private DNS
  "privatelink.servicebus.windows.net" = {
    virtual_network_links = {
      "myproject-prod-vnet" = {
        virtual_network_id   = module.vpc.virtual_network_id
        registration_enabled = false
      }
    }
  }
  
  # Container Registry private DNS
  "privatelink.azurecr.io" = {
    virtual_network_links = {
      "myproject-prod-vnet" = {
        virtual_network_id   = module.vpc.virtual_network_id
        registration_enabled = false
      }
    }
    
    a_records = {
      "myprojectprodacr" = {
        ttl     = 300
        records = ["10.0.10.13"]               # Private endpoint IP
        
        tags = {
          Service = "ContainerRegistry"
          Type    = "Registry"
        }
      }
    }
  }
  
  # Custom application DNS zone
  "internal.mycompany.com" = {
    virtual_network_links = {
      "myproject-prod-vnet" = {
        virtual_network_id   = module.vpc.virtual_network_id
        registration_enabled = true             # Auto-register VM DNS records
        
        tags = {
          Service = "Internal"
          Purpose = "Application service discovery"
        }
      }
    }
    
    # Custom application A records
    a_records = {
      "api" = {
        ttl     = 300
        records = ["10.0.2.10"]                # Internal API server
        
        tags = {
          Service = "API"
          Type    = "Application"
        }
      }
      
      "app" = {
        ttl     = 300
        records = ["10.0.2.11"]                # Internal app server
        
        tags = {
          Service = "Application"
          Type    = "Frontend"
        }
      }
    }
    
    # CNAME records for load balancers
    cname_records = {
      "lb" = {
        ttl    = 300
        record = "api.internal.mycompany.com"   # Point to API A record
        
        tags = {
          Service = "LoadBalancer"
          Type    = "Alias"
        }
      }
    }
  }
}
```

### **🌉 Production VPN Gateway**

```hcl
# VPN Gateway for hybrid connectivity
vpn_gateway = {
  enabled = true
  
  # Gateway configuration
  type     = "Vpn"                              # VPN Gateway type
  vpn_type = "RouteBased"                       # Route-based VPN
  sku      = "VpnGw2AZ"                        # Generation 2, Zone-redundant
  
  # High availability
  active_active   = true                        # Active-active for redundancy
  enable_bgp     = true                        # Border Gateway Protocol
  bgp_asn        = 65515                       # Azure default ASN
  
  # Public IP addresses (2 for active-active)
  public_ip_allocation_method = "Static"        # Static IP allocation
  public_ip_sku              = "Standard"      # Standard SKU for zone redundancy
  
  # Point-to-Site configuration
  vpn_client_configuration = {
    address_space = ["192.168.100.0/24"]        # Client address pool
    
    vpn_client_protocols = [
      "OpenVPN",                                # Modern OpenVPN protocol
      "IkeV2"                                   # IKEv2 for compatibility
    ]
    
    # Root certificates for authentication
    root_certificate = {
      name = "P2SRootCert"
      public_cert_data = "MIIC5jCCAc4CAQAw..."   # Certificate data (base64)
    }
    
    # Revoked certificates (if any)
    revoked_certificate = []
    
    # Azure AD authentication (alternative to certificates)
    aad_tenant   = "https://login.microsoftonline.com/{tenant-id}/"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"  # Azure VPN Client app ID
    aad_issuer   = "https://sts.windows.net/{tenant-id}/"
  }
  
  # Site-to-Site configuration
  local_network_gateway = {
    name               = "OnPremisesGateway"
    gateway_address    = "203.0.113.1"         # On-premises public IP
    address_space      = ["192.168.0.0/16"]    # On-premises address space
    
    bgp_settings = {
      asn                 = 65001               # On-premises ASN
      bgp_peering_address = "192.168.1.1"      # On-premises BGP peer IP
      peer_weight         = 0                   # Default weight
    }
  }
  
  # VPN connection
  vpn_connection = {
    name                = "OnPremisesConnection"
    connection_type     = "IPsec"
    shared_key          = "your-pre-shared-key-here"  # IPsec shared key
    
    # IKE/IPSec parameters
    ipsec_policy = {
      dh_group         = "DHGroup2"             # Diffie-Hellman group
      ike_encryption   = "AES256"               # IKE encryption
      ike_integrity    = "SHA256"               # IKE integrity
      ipsec_encryption = "AES256"               # IPSec encryption
      ipsec_integrity  = "SHA256"               # IPSec integrity
      pfs_group        = "PFS2"                 # Perfect Forward Secrecy
      sa_datasize      = 102400000              # Security Association data size
      sa_lifetime      = 27000                  # SA lifetime in seconds
    }
    
    # Traffic selectors (for policy-based VPN)
    traffic_selector_policy = []                # Empty for route-based
  }
  
  tags = {
    Environment = "production"
    Service     = "VPN"
    Owner       = "network-team@mycompany.com"
  }
}
```

### **🔥 Production Azure Firewall**

```hcl
# Azure Firewall for advanced network security
azure_firewall = {
  enabled = true
  
  # Firewall configuration
  sku_name = "AZFW_VNet"                        # Standard firewall
  sku_tier = "Standard"                         # Standard tier
  
  # Threat intelligence
  threat_intel_mode = "Alert"                   # Alert on threats (Alert/Deny/Off)
  
  # DNS settings
  dns_servers = ["168.63.129.16"]               # Azure-provided DNS
  dns_proxy_enabled = true                      # Enable DNS proxy
  
  # Public IP configuration
  public_ip_count = 1                           # Number of public IPs
  
  # Application rules
  application_rule_collections = [
    {
      name     = "AllowWebTraffic"
      priority = 100
      action   = "Allow"
      
      rules = [
        {
          name = "AllowHTTPS"
          description = "Allow outbound HTTPS traffic"
          
          source_addresses = [
            "10.0.1.0/24",                      # Web subnet
            "10.0.2.0/24"                       # App subnet
          ]
          
          target_fqdns = [
            "*.microsoft.com",
            "*.windows.net",
            "*.azure.com"
          ]
          
          protocols = [
            {
              port = "443"
              type = "Https"
            }
          ]
        }
      ]
    },
    
    {
      name     = "AllowAzureServices"
      priority = 200
      action   = "Allow"
      
      rules = [
        {
          name = "AllowAzureCloud"
          description = "Allow access to Azure services"
          
          source_addresses = ["10.0.0.0/16"]    # Entire VNet
          
          fqdn_tags = [
            "AzureBackup",
            "AzureKubernetesService",
            "MicrosoftActiveProtectionService",
            "WindowsUpdate"
          ]
        }
      ]
    }
  ]
  
  # Network rules
  network_rule_collections = [
    {
      name     = "AllowInternalTraffic"
      priority = 100
      action   = "Allow"
      
      rules = [
        {
          name = "AllowDNS"
          description = "Allow DNS queries"
          
          protocols = ["UDP"]
          
          source_addresses = ["10.0.0.0/16"]
          
          destination_addresses = [
            "168.63.129.16",                    # Azure DNS
            "10.100.0.4",                       # Custom DNS 1
            "10.100.0.5"                        # Custom DNS 2
          ]
          
          destination_ports = ["53"]
        },
        
        {
          name = "AllowNTP"
          description = "Allow NTP time synchronization"
          
          protocols = ["UDP"]
          source_addresses = ["10.0.0.0/16"]
          destination_addresses = ["*"]
          destination_ports = ["123"]
        }
      ]
    }
  ]
  
  # NAT rules
  nat_rule_collections = [
    {
      name     = "InboundNAT"
      priority = 100
      action   = "Dnat"
      
      rules = [
        {
          name = "SSHAccess"
          description = "SSH access to management VM"
          
          protocols = ["TCP"]
          
          source_addresses = [
            "203.0.113.0/24"                   # Corporate network
          ]
          
          destination_addresses = [
            "firewall-public-ip"               # Firewall public IP
          ]
          
          destination_ports = ["2222"]        # Custom SSH port
          translated_address = "10.0.2.100"  # Management VM
          translated_port = "22"              # Standard SSH port
        }
      ]
    }
  ]
  
  tags = {
    Environment = "production"
    Service     = "Firewall"
    Owner       = "security-team@mycompany.com"
  }
}
```

## 🔄 **Network Monitoring & Diagnostics**

### **Network Watcher Configuration**

```hcl
# Network Watcher for monitoring and diagnostics
network_watcher = {
  enabled = true
  location = "East US"                          # Must match VNet location
  
  # Flow logs for NSG traffic analysis
  flow_logs = {
    enabled = true
    storage_account_id = "/subscriptions/{subscription-id}/resourceGroups/myproject-prod-data-rg/providers/Microsoft.Storage/storageAccounts/myprojectprodlogs"
    
    # Retention policy
    retention_policy = {
      enabled = true
      days    = 90                              # 90 days retention
    }
    
    # Traffic analytics
    traffic_analytics = {
      enabled = true
      workspace_id = "/subscriptions/{subscription-id}/resourceGroups/myproject-prod-security-rg/providers/Microsoft.OperationalInsights/workspaces/myproject-prod-law"
      workspace_region = "East US"
      workspace_resource_id = "/subscriptions/{subscription-id}/resourceGroups/myproject-prod-security-rg/providers/Microsoft.OperationalInsights/workspaces/myproject-prod-law"
      interval_in_minutes = 10                  # 10-minute aggregation
    }
  }
}
```

### **Network Security Monitoring**

```kusto
// Top talkers analysis
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| where FlowType_s == "ExternalPublic"
| summarize TotalFlows = count(), TotalBytes = sum(FlowCount_d) by SrcIP_s, DestIP_s
| top 20 by TotalFlows desc

// Blocked traffic analysis
AzureDiagnostics
| where Category == "NetworkSecurityGroupFlowEvent"
| where TimeGenerated > ago(1h)
| extend FlowTuple = split(msg_s, ",")
| extend Decision = tostring(FlowTuple[4])
| where Decision == "D"  // Denied traffic
| summarize BlockedCount = count() by SourceIP = tostring(FlowTuple[1])
| sort by BlockedCount desc

// VPN connection monitoring
AzureDiagnostics
| where Category == "GatewayDiagnosticLog"
| where TimeGenerated > ago(1h)
| where Level == "Error"
| project TimeGenerated, Message, OperationName
| sort by TimeGenerated desc

// Private endpoint connectivity
AzureDiagnostics
| where Category == "PrivateEndpointNetworkInterface"
| where TimeGenerated > ago(1h)
| project TimeGenerated, ResourceId, Message
| sort by TimeGenerated desc
```

## 🚨 **Network Security Best Practices**

### **Zero Trust Network Architecture**

1. **Principle of Least Privilege**
   - Deny all traffic by default
   - Explicitly allow only required traffic
   - Regular review and cleanup of NSG rules

2. **Network Segmentation**
   - Separate subnets for different tiers
   - Use NSGs and Azure Firewall for micro-segmentation
   - Implement network access controls

3. **Private Connectivity**
   - Use private endpoints for Azure services
   - Implement VNet service endpoints where appropriate
   - Avoid public IP addresses when possible

4. **Monitoring and Alerting**
   - Enable NSG Flow Logs and Traffic Analytics
   - Monitor for unusual network patterns
   - Set up alerts for security events

### **Production Security Checklist**

- [ ] **NSG Rules**: Implement least privilege access rules
- [ ] **DDoS Protection**: Enable Azure DDoS Protection Standard
- [ ] **Private Endpoints**: Use for all supported Azure services
- [ ] **Azure Firewall**: Deploy for centralized security control
- [ ] **Network Watcher**: Enable for monitoring and diagnostics
- [ ] **Flow Logs**: Configure for traffic analysis
- [ ] **DNS Security**: Use private DNS zones for internal resolution
- [ ] **VPN Security**: Implement strong authentication and encryption
- [ ] **Regular Audits**: Review and update network configurations

## 🔧 **Troubleshooting Guide**

### **Common Network Issues**

#### **Connectivity Issues**
```bash
# Test network connectivity
az network watcher test-connectivity \
  --source-resource "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm}" \
  --dest-address "10.0.3.10" \
  --dest-port 1433

# Check NSG rules
az network nsg rule list \
  --resource-group "myproject-prod-networking-rg" \
  --nsg-name "app-nsg" \
  --output table

# Verify route table
az network route-table route list \
  --resource-group "myproject-prod-networking-rg" \
  --route-table-name "app-routes" \
  --output table
```

#### **DNS Resolution Issues**
```bash
# Test DNS resolution
nslookup myproject-prod-sql.database.windows.net 10.0.10.11

# Check private DNS zone
az network private-dns zone show \
  --resource-group "myproject-prod-networking-rg" \
  --name "privatelink.database.windows.net"

# Verify DNS records
az network private-dns record-set a list \
  --resource-group "myproject-prod-networking-rg" \
  --zone-name "privatelink.database.windows.net"
```

#### **VPN Connectivity Issues**
```bash
# Check VPN gateway status
az network vnet-gateway show \
  --resource-group "myproject-prod-networking-rg" \
  --name "myproject-prod-vpn-gw"

# View VPN connection status
az network vpn-connection show \
  --resource-group "myproject-prod-networking-rg" \
  --name "OnPremisesConnection"

# Check BGP peers
az network vnet-gateway list-bgp-peer-status \
  --resource-group "myproject-prod-networking-rg" \
  --name "myproject-prod-vpn-gw"
```

---

**📍 Navigation**: [🏠 Main README](../../README.md) | [➡️ Security Layer](../security/README.md)