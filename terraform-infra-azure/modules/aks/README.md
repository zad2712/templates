# AKS (Azure Kubernetes Service) Module

This module creates and manages an Azure Kubernetes Service (AKS) cluster with enterprise-grade security, networking, and operational features.

## Features

- **Enterprise Security**: Azure AD integration, RBAC, Pod Security Policy, Workload Identity
- **Advanced Networking**: Custom VNet integration, Network Policy, Service Mesh ready
- **High Availability**: Multiple node pools, availability zones, auto-scaling
- **Monitoring & Diagnostics**: Azure Monitor integration, Log Analytics, diagnostic settings
- **Add-ons**: Application Gateway Ingress Controller, Azure Policy, Key Vault CSI driver
- **Identity Management**: Managed identities with proper RBAC assignments

## Usage

### Basic Example

```hcl
module "aks_cluster" {
  source = "../../modules/aks"

  cluster_name        = "my-aks-cluster"
  resource_group_name = "my-rg"
  location           = "East US"

  # Network Configuration
  vnet_subnet_id = "/subscriptions/.../subnets/aks-subnet"
  network_profile = {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.100.0.0/16"
    dns_service_ip = "10.100.0.10"
  }

  # Node Pools
  node_pools = {
    system = {
      name                = "system"
      vm_size            = "Standard_D2s_v3"
      node_count         = 3
      availability_zones = ["1", "2", "3"]
      node_taints        = ["CriticalAddonsOnly=true:NoSchedule"]
      node_labels = {
        "role" = "system"
      }
    }
    
    user = {
      name                = "user"
      vm_size            = "Standard_D4s_v3"
      node_count         = 2
      min_count          = 1
      max_count          = 10
      enable_auto_scaling = true
      availability_zones = ["1", "2", "3"]
      node_labels = {
        "role" = "user"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "myapp"
  }
}
```

### Advanced Example with All Features

```hcl
module "aks_cluster" {
  source = "../../modules/aks"

  # Basic Configuration
  cluster_name         = "production-aks"
  resource_group_name  = "production-rg"
  location            = "East US"
  kubernetes_version   = "1.28.3"
  sku_tier            = "Standard"
  
  # Security Configuration
  private_cluster              = true
  local_account_disabled       = true
  enable_azure_rbac           = true
  enable_workload_identity    = true
  enable_pod_security_policy  = true
  
  # Network Configuration
  vnet_subnet_id = "/subscriptions/.../subnets/aks-subnet"
  network_profile = {
    network_plugin      = "azure"
    network_policy      = "calico"
    service_cidr        = "10.100.0.0/16"
    dns_service_ip      = "10.100.0.10"
    docker_bridge_cidr  = "172.17.0.1/16"
    load_balancer_sku   = "standard"
    outbound_type      = "loadBalancer"
  }

  # Node Pools
  node_pools = {
    system = {
      name                = "system"
      vm_size            = "Standard_D4s_v3"
      node_count         = 3
      availability_zones = ["1", "2", "3"]
      enable_auto_scaling = true
      min_count          = 3
      max_count          = 6
      max_pods           = 30
      os_disk_size_gb    = 128
      os_disk_type       = "Managed"
      node_taints        = ["CriticalAddonsOnly=true:NoSchedule"]
      node_labels = {
        "role"                           = "system"
        "kubernetes.azure.com/scalesetpriority" = "Regular"
      }
    }
    
    user = {
      name                = "user"
      vm_size            = "Standard_D8s_v3"
      node_count         = 3
      availability_zones = ["1", "2", "3"]
      enable_auto_scaling = true
      min_count          = 2
      max_count          = 20
      max_pods           = 50
      os_disk_size_gb    = 256
      os_disk_type       = "Managed"
      node_labels = {
        "role" = "user"
      }
    }

    memory_optimized = {
      name                = "memory"
      vm_size            = "Standard_E8s_v3"
      node_count         = 0
      availability_zones = ["1", "2", "3"]
      enable_auto_scaling = true
      min_count          = 0
      max_count          = 5
      max_pods           = 30
      os_disk_size_gb    = 128
      node_taints        = ["workload=memory-intensive:NoSchedule"]
      node_labels = {
        "role"     = "memory-optimized"
        "workload" = "memory-intensive"
      }
    }
  }

  # Identity Configuration
  identity_type = "UserAssigned"
  identity_ids  = ["/subscriptions/.../managedIdentities/aks-identity"]

  # Azure AD Integration
  azure_rbac_admin_group_object_ids = [
    "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  ]

  # Add-ons Configuration
  ingress_application_gateway = {
    enabled    = true
    gateway_id = "/subscriptions/.../applicationGateways/my-appgw"
  }

  oms_agent = {
    enabled                    = true
    log_analytics_workspace_id = "/subscriptions/.../workspaces/my-law"
  }

  azure_policy = {
    enabled = true
  }

  key_vault_secrets_provider = {
    enabled                  = true
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Auto Scaler Profile
  auto_scaler_profile = {
    balance_similar_node_groups      = false
    expander                        = "random"
    max_graceful_termination_sec    = 600
    max_node_provisioning_time      = "15m"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "10s"
    scale_down_delay_after_add     = "10m"
    scale_down_delay_after_delete  = "10s"
    scale_down_delay_after_failure = "3m"
    scale_down_unneeded            = "10m"
    scale_down_unready             = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max          = 10
    skip_nodes_with_local_storage  = true
    skip_nodes_with_system_pods    = true
  }

  # Diagnostic Settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = "/subscriptions/.../workspaces/my-law"

  tags = {
    Environment    = "production"
    Project       = "myapp"
    Owner         = "platform-team"
    CostCenter    = "engineering"
    BusinessUnit  = "product"
  }
}
```

## Configuration

### Network Profile Options

| Network Plugin | Network Policy | Use Case |
|---------------|---------------|----------|
| `kubenet` | `calico` | Basic networking, smaller clusters |
| `azure` | `azure` | Azure-native networking, enterprise features |
| `azure` | `calico` | Azure networking with advanced Calico policies |

### Node Pool Configuration

#### VM Sizes by Workload

| Workload Type | Recommended VM Size | vCPUs | Memory | Use Case |
|--------------|-------------------|--------|---------|----------|
| System | `Standard_D2s_v3` | 2 | 8 GB | System components |
| General Purpose | `Standard_D4s_v3` | 4 | 16 GB | Web apps, APIs |
| CPU Intensive | `Standard_F8s_v2` | 8 | 16 GB | Compute workloads |
| Memory Intensive | `Standard_E8s_v3` | 8 | 64 GB | In-memory databases |
| GPU Workloads | `Standard_NC6s_v3` | 6 | 112 GB | AI/ML training |

#### Node Taints and Labels

```hcl
# System node pool
node_taints = ["CriticalAddonsOnly=true:NoSchedule"]
node_labels = {
  "role" = "system"
}

# GPU node pool
node_taints = ["gpu=true:NoSchedule"]
node_labels = {
  "accelerator" = "nvidia-tesla-v100"
  "role"        = "gpu"
}

# Spot instance node pool
node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
node_labels = {
  "kubernetes.azure.com/scalesetpriority" = "spot"
  "role" = "batch"
}
```

## Security

### Azure AD Integration

The module automatically configures Azure AD integration with RBAC:

```hcl
# Grant cluster admin access to Azure AD groups
azure_rbac_admin_group_object_ids = [
  "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"  # Platform Team
]

# Enable Azure RBAC for Kubernetes authorization
enable_azure_rbac = true
```

### Workload Identity

Enable workload identity for secure pod-to-Azure service authentication:

```hcl
enable_workload_identity = true
```

Then configure workloads:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  namespace: default
  annotations:
    azure.workload.identity/client-id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: my-service-account
```

### Pod Security Policy

Enable Pod Security Policy for enhanced security:

```hcl
enable_pod_security_policy = true
```

## Monitoring

### Azure Monitor Integration

The module automatically configures Azure Monitor for containers:

```hcl
oms_agent = {
  enabled                    = true
  log_analytics_workspace_id = "/subscriptions/.../workspaces/my-law"
}
```

### Diagnostic Settings

Enable diagnostic logging for audit and troubleshooting:

```hcl
enable_diagnostic_settings = true
log_analytics_workspace_id = "/subscriptions/.../workspaces/my-law"
```

Available log categories:
- `kube-apiserver`
- `kube-audit`
- `kube-audit-admin`
- `kube-controller-manager`
- `kube-scheduler`
- `cluster-autoscaler`
- `guard`

## Add-ons

### Application Gateway Ingress Controller (AGIC)

```hcl
ingress_application_gateway = {
  enabled    = true
  gateway_id = "/subscriptions/.../applicationGateways/my-appgw"
}
```

### Azure Policy

```hcl
azure_policy = {
  enabled = true
}
```

### Key Vault CSI Driver

```hcl
key_vault_secrets_provider = {
  enabled                  = true
  secret_rotation_enabled  = true
  secret_rotation_interval = "2m"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_name` | Name of the AKS cluster | `string` | n/a | yes |
| `resource_group_name` | Name of the resource group | `string` | n/a | yes |
| `location` | Azure region for resources | `string` | n/a | yes |
| `kubernetes_version` | Kubernetes version | `string` | `null` | no |
| `sku_tier` | SKU tier for the cluster | `string` | `"Free"` | no |
| `private_cluster` | Enable private cluster | `bool` | `false` | no |
| `node_pools` | Node pool configurations | `map(object)` | n/a | yes |
| `vnet_subnet_id` | Subnet ID for AKS nodes | `string` | n/a | yes |
| `network_profile` | Network profile configuration | `object` | n/a | yes |
| `enable_azure_rbac` | Enable Azure RBAC | `bool` | `false` | no |
| `enable_workload_identity` | Enable workload identity | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the AKS cluster |
| `cluster_name` | Name of the AKS cluster |
| `kube_config` | Kubernetes configuration |
| `cluster_identity` | Cluster managed identity |
| `node_resource_group` | Node resource group name |
| `fqdn` | FQDN of the AKS cluster |
| `private_fqdn` | Private FQDN of the AKS cluster |

## Examples

See the [examples](../../examples/aks) directory for complete examples:

- [Basic AKS Cluster](../../examples/aks/basic)
- [Private AKS Cluster](../../examples/aks/private)
- [Multi-Node Pool Cluster](../../examples/aks/multi-node-pool)
- [GPU-Enabled Cluster](../../examples/aks/gpu)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.0 |

## License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for more information.