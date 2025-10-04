# ☸️ Azure Kubernetes Service (AKS) Module

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider~4.0-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-≥1.28-blue.svg)](https://kubernetes.io)

**Author**: Diego A. Zarate

This module provisions a production-ready Azure Kubernetes Service (AKS) cluster with advanced features including multiple node pools, auto-scaling, network policies, and comprehensive monitoring.

## 🎯 **Features**

- ✅ **AKS Cluster** with system and user node pools
- ✅ **Auto Scaling** with cluster and pod autoscaling
- ✅ **Network Security** with Azure CNI and network policies
- ✅ **Monitoring** with Azure Monitor for containers
- ✅ **Security** with managed identity, RBAC, and private cluster
- ✅ **Add-ons** support for ingress, CSI drivers, and service mesh
- ✅ **Multi-Zone** deployment for high availability
- ✅ **Workload Identity** for secure pod-to-Azure service authentication

## 📋 **Requirements**

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | ~> 4.0 |
| kubernetes | ~> 2.32 |
| helm | ~> 2.15 |

## 🚀 **Usage Examples**

### **Basic AKS Cluster**

```hcl
module "aks" {
  source = "../../modules/eks"  # Note: This is the AKS module despite the path name
  
  # Basic cluster configuration
  cluster_name        = "myapp-dev-aks"
  resource_group_name = "myapp-dev-rg"
  location           = "East US"
  
  # Network configuration
  vnet_subnet_id = module.vpc.subnet_ids["aks"]
  dns_prefix     = "myapp-dev"
  
  # Default node pool
  default_node_pool = {
    name       = "system"
    vm_size    = "Standard_D2s_v3"
    node_count = 2
    
    # Auto-scaling
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 5
    
    # Availability zones
    availability_zones = ["1", "2", "3"]
    
    # Node configuration
    os_disk_size_gb = 30
    os_disk_type    = "Managed"
    
    tags = {
      Environment = "development"
      NodePool    = "system"
    }
  }
  
  # Basic features
  kubernetes_version = "1.28"
  
  tags = {
    Environment = "development"
    Project     = "myapp"
    Owner       = "dev-team@company.com"
  }
}
```

### **Production AKS Cluster with Advanced Features**

```hcl
module "aks" {
  source = "../../modules/eks"
  
  # Production cluster configuration
  cluster_name        = "myapp-prod-aks"
  resource_group_name = "myapp-prod-compute-rg"
  location           = "East US"
  
  # Kubernetes version
  kubernetes_version          = "1.28.5"
  automatic_channel_upgrade   = "patch"     # Automatic patch updates
  node_os_channel_upgrade    = "NodeImage" # Automatic node image updates
  
  # Network configuration
  vnet_subnet_id = module.vpc.subnet_ids["aks"]
  dns_prefix     = "myapp-prod"
  
  # Advanced networking
  network_plugin    = "azure"              # Azure CNI
  network_policy    = "calico"             # Calico network policies
  service_cidr     = "172.16.0.0/16"      # Kubernetes service CIDR
  dns_service_ip   = "172.16.0.10"        # Kubernetes DNS service IP
  
  # Security features
  private_cluster_enabled             = true  # Private API server
  private_dns_zone_id                = "System" # System-managed private DNS
  api_server_authorized_ip_ranges    = [
    "203.0.113.0/24",                        # Corporate network
    "198.51.100.0/24"                       # Management network
  ]
  
  # RBAC and identity
  role_based_access_control_enabled = true
  azure_rbac_enabled                = true   # Azure RBAC integration
  
  # Managed identity
  identity = {
    type = "SystemAssigned"
  }
  
  # System node pool (required)
  default_node_pool = {
    name       = "system"
    vm_size    = "Standard_D4s_v3"           # 4 vCPUs, 16GB RAM
    node_count = 3                           # Fixed count for system workloads
    
    # System pool specific settings
    only_critical_addons_enabled = true      # Only system pods
    
    # Availability and reliability
    availability_zones = ["1", "2", "3"]     # Multi-zone deployment
    
    # Storage configuration
    os_disk_size_gb = 100                    # Larger OS disk for system pods
    os_disk_type    = "Premium_LRS"         # Premium SSD for better performance
    
    # Node configuration
    max_pods        = 30                     # Standard max pods per node
    node_taints     = ["CriticalAddonsOnly=true:NoSchedule"]  # System workloads only
    
    # Upgrade settings
    upgrade_settings = {
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 10
      max_surge                     = "33%"
    }
    
    tags = {
      Environment = "production"
      NodePool    = "system"
      Purpose     = "system-workloads"
    }
  }
  
  # Additional node pools
  node_pools = {
    # General purpose worker nodes
    "workers" = {
      vm_size    = "Standard_D4s_v3"
      node_count = 5
      
      # Auto-scaling configuration
      enable_auto_scaling = true
      min_count          = 3
      max_count          = 20
      
      # Availability
      availability_zones = ["1", "2", "3"]
      
      # Storage
      os_disk_size_gb = 100
      os_disk_type    = "Premium_LRS"
      
      # Node configuration
      max_pods = 110                         # Maximum pods per node
      
      # Labels and taints
      node_labels = {
        "workload-type" = "general"
        "environment"   = "production"
      }
      
      # Upgrade settings
      upgrade_settings = {
        drain_timeout_in_minutes      = 30
        node_soak_duration_in_minutes = 10
        max_surge                     = "33%"
      }
      
      tags = {
        Environment = "production"
        NodePool    = "workers"
        Purpose     = "general-workloads"
      }
    }
    
    # Compute-intensive workloads
    "compute" = {
      vm_size    = "Standard_F8s_v2"         # 8 vCPUs, 16GB RAM, high CPU performance
      node_count = 0                         # Start with 0 nodes
      
      # Auto-scaling for burst workloads
      enable_auto_scaling = true
      min_count          = 0
      max_count          = 10
      
      # Single zone for cost optimization
      availability_zones = ["1"]
      
      # Storage optimized for compute workloads
      os_disk_size_gb = 64
      os_disk_type    = "Premium_LRS"
      
      # Higher pod density for smaller workloads
      max_pods = 30
      
      # Workload-specific taints
      node_taints = ["workload=compute:NoSchedule"]
      
      node_labels = {
        "workload-type" = "compute-intensive"
        "scaling-group" = "burst"
      }
      
      tags = {
        Environment = "production"
        NodePool    = "compute"
        Purpose     = "cpu-intensive-workloads"
      }
    }
    
    # Memory-intensive workloads
    "memory" = {
      vm_size    = "Standard_E4s_v3"         # 4 vCPUs, 32GB RAM, memory optimized
      node_count = 0
      
      enable_auto_scaling = true
      min_count          = 0
      max_count          = 5
      
      availability_zones = ["1", "2"]
      
      os_disk_size_gb = 128                  # Larger disk for memory-intensive apps
      os_disk_type    = "Premium_LRS"
      
      max_pods = 50
      
      node_taints = ["workload=memory:NoSchedule"]
      
      node_labels = {
        "workload-type" = "memory-intensive"
        "scaling-group" = "memory"
      }
      
      tags = {
        Environment = "production"
        NodePool    = "memory"
        Purpose     = "memory-intensive-workloads"
      }
    }
  }
  
  # Monitoring and logging
  oms_agent_enabled                 = true
  log_analytics_workspace_id       = var.log_analytics_workspace_id
  
  # Container insights
  microsoft_defender_enabled        = true  # Microsoft Defender for containers
  
  # Auto-scaling
  auto_scaler_profile = {
    balance_similar_node_groups      = true
    expander                        = "random"
    max_graceful_termination_sec    = 600
    max_node_provisioning_time      = "15m"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "10s"
    scale_down_delay_after_add     = "10m"
    scale_down_delay_after_delete  = "10s"
    scale_down_delay_after_failure = "3m"
    scan_interval                  = "10s"
    scale_down_unneeded           = "10m"
    scale_down_unready            = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max         = 10
    skip_nodes_with_local_storage = true
    skip_nodes_with_system_pods   = true
  }
  
  # Add-ons and integrations
  addons = {
    # Ingress controller
    ingress_nginx = {
      enabled = true
      
      values = {
        controller = {
          replicaCount = 3                   # High availability
          
          service = {
            type = "LoadBalancer"
            annotations = {
              "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            }
          }
          
          metrics = {
            enabled = true
            serviceMonitor = {
              enabled = true
            }
          }
        }
      }
    }
    
    # Certificate management
    cert_manager = {
      enabled = true
      
      values = {
        installCRDs = true
        
        prometheus = {
          servicemonitor = {
            enabled = true
          }
        }
      }
    }
    
    # External DNS for automatic DNS management
    external_dns = {
      enabled = true
      
      values = {
        provider = "azure"
        azure = {
          resourceGroup = var.dns_resource_group
          tenantId     = var.tenant_id
          subscriptionId = var.subscription_id
        }
        
        domainFilters = ["mycompany.com"]
        
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
      }
    }
    
    # Prometheus monitoring stack
    kube_prometheus_stack = {
      enabled = true
      
      values = {
        prometheus = {
          prometheusSpec = {
            retention = "30d"
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = "managed-csi"
                  accessModes = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = "50Gi"
                    }
                  }
                }
              }
            }
          }
        }
        
        grafana = {
          adminPassword = "changeme"  # Use Azure Key Vault in production
          
          persistence = {
            enabled = true
            size = "10Gi"
            storageClassName = "managed-csi"
          }
          
          ingress = {
            enabled = true
            annotations = {
              "kubernetes.io/ingress.class" = "nginx"
              "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
            }
            hosts = ["grafana.mycompany.com"]
            tls = [
              {
                secretName = "grafana-tls"
                hosts = ["grafana.mycompany.com"]
              }
            ]
          }
        }
      }
    }
  }
  
  # Workload Identity (AAD Pod Identity v2)
  workload_identity_enabled = true
  oidc_issuer_enabled      = true
  
  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team@company.com"
    CostCenter  = "infrastructure"
    Backup      = "required"
  }
}
```

## 📊 **Input Variables**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Name of the AKS cluster | `string` | n/a | yes |
| `resource_group_name` | Name of the resource group | `string` | n/a | yes |
| `location` | Azure region for the cluster | `string` | n/a | yes |
| `kubernetes_version` | Kubernetes version | `string` | `"1.28"` | no |
| `vnet_subnet_id` | Subnet ID for the cluster | `string` | n/a | yes |
| `dns_prefix` | DNS prefix for the cluster | `string` | n/a | yes |
| `default_node_pool` | Default node pool configuration | `object` | see below | yes |
| `node_pools` | Additional node pools | `map(object)` | `{}` | no |
| `network_plugin` | Network plugin (azure or kubenet) | `string` | `"azure"` | no |
| `network_policy` | Network policy (calico, azure, or cilium) | `string` | `"calico"` | no |
| `private_cluster_enabled` | Enable private cluster | `bool` | `false` | no |
| `role_based_access_control_enabled` | Enable RBAC | `bool` | `true` | no |
| `azure_rbac_enabled` | Enable Azure RBAC | `bool` | `false` | no |
| `oms_agent_enabled` | Enable Azure Monitor for containers | `bool` | `true` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID | `string` | `null` | no |
| `microsoft_defender_enabled` | Enable Microsoft Defender | `bool` | `false` | no |
| `workload_identity_enabled` | Enable workload identity | `bool` | `false` | no |
| `oidc_issuer_enabled` | Enable OIDC issuer | `bool` | `false` | no |
| `addons` | Kubernetes add-ons configuration | `map(object)` | `{}` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## 📤 **Outputs**

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the AKS cluster |
| `cluster_name` | Name of the AKS cluster |
| `cluster_fqdn` | FQDN of the AKS cluster |
| `cluster_endpoint` | Endpoint of the AKS cluster |
| `cluster_ca_certificate` | Base64 encoded CA certificate |
| `kube_config_raw` | Raw kubeconfig for the cluster |
| `kubelet_identity` | Kubelet managed identity |
| `cluster_identity` | Cluster managed identity |
| `oidc_issuer_url` | OIDC issuer URL (if enabled) |
| `node_resource_group` | Resource group for AKS nodes |
| `effective_outbound_ips` | Effective outbound IPs |

---

**🔗 Related Modules**: [VPC](../vpc/README.md) | [IAM](../iam/README.md) | [Security Groups](../security-groups/README.md)