# =============================================================================
# AZURE KUBERNETES SERVICE (AKS) MODULE
# =============================================================================

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  
  sku_tier                      = var.sku_tier
  automatic_channel_upgrade     = var.automatic_channel_upgrade
  node_os_channel_upgrade      = var.node_os_channel_upgrade
  private_cluster_enabled      = var.private_cluster_enabled
  private_dns_zone_id         = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled

  # Default node pool
  default_node_pool {
    name                = var.default_node_pool.name
    vm_size             = var.default_node_pool.vm_size
    node_count          = var.default_node_pool.node_count
    min_count           = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count           = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    enable_auto_scaling = var.default_node_pool.enable_auto_scaling
    availability_zones  = var.default_node_pool.availability_zones
    
    vnet_subnet_id         = var.subnet_id
    orchestrator_version   = var.kubernetes_version
    os_disk_size_gb       = var.default_node_pool.os_disk_size_gb
    os_disk_type          = var.default_node_pool.os_disk_type
    enable_node_public_ip = false
    
    upgrade_settings {
      max_surge = var.default_node_pool.max_surge
    }

    node_labels = var.default_node_pool.node_labels
    node_taints = var.default_node_pool.node_taints
  }

  # Service Principal or Managed Identity
  dynamic "service_principal" {
    for_each = var.identity_type == "ServicePrincipal" ? [1] : []
    content {
      client_id     = var.service_principal.client_id
      client_secret = var.service_principal.client_secret
    }
  }

  dynamic "identity" {
    for_each = var.identity_type == "SystemAssigned" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "identity" {
    for_each = var.identity_type == "UserAssigned" ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }

  # Network Configuration
  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    load_balancer_sku   = "standard"
    outbound_type       = var.outbound_type
  }

  # Azure AD Integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_rbac ? [1] : []
    content {
      managed                = true
      admin_group_object_ids = var.azure_ad_admin_group_object_ids
      azure_rbac_enabled     = var.azure_rbac_enabled
    }
  }

  # Role Based Access Control
  dynamic "role_based_access_control_enabled" {
    for_each = var.enable_rbac && !var.enable_azure_ad_rbac ? [1] : []
    content {
      enabled = true
    }
  }

  # HTTP Application Routing (not recommended for production)
  http_application_routing_enabled = var.http_application_routing_enabled

  # Azure Policy
  dynamic "azure_policy_enabled" {
    for_each = var.enable_azure_policy ? [1] : []
    content {
      enabled = true
    }
  }

  # Open Service Mesh
  dynamic "open_service_mesh_enabled" {
    for_each = var.enable_open_service_mesh ? [1] : []
    content {
      enabled = true
    }
  }

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled  = var.key_vault_secrets_provider.secret_rotation_enabled
      secret_rotation_interval = var.key_vault_secrets_provider.secret_rotation_interval
    }
  }

  # OMS Agent (Azure Monitor for Containers)
  dynamic "oms_agent" {
    for_each = var.enable_log_analytics ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Ingress Application Gateway
  dynamic "ingress_application_gateway" {
    for_each = var.enable_ingress_application_gateway ? [1] : []
    content {
      gateway_id   = var.application_gateway_id
      gateway_name = var.application_gateway_name
      subnet_cidr  = var.application_gateway_subnet_cidr
      subnet_id    = var.application_gateway_subnet_id
    }
  }

  # Auto Scaler Profile
  dynamic "auto_scaler_profile" {
    for_each = var.enable_auto_scaler_profile ? [1] : []
    content {
      balance_similar_node_groups      = var.auto_scaler_profile.balance_similar_node_groups
      expander                        = var.auto_scaler_profile.expander
      max_graceful_termination_sec    = var.auto_scaler_profile.max_graceful_termination_sec
      max_node_provisioning_time      = var.auto_scaler_profile.max_node_provisioning_time
      max_unready_nodes              = var.auto_scaler_profile.max_unready_nodes
      max_unready_percentage         = var.auto_scaler_profile.max_unready_percentage
      new_pod_scale_up_delay         = var.auto_scaler_profile.new_pod_scale_up_delay
      scale_down_delay_after_add     = var.auto_scaler_profile.scale_down_delay_after_add
      scale_down_delay_after_delete  = var.auto_scaler_profile.scale_down_delay_after_delete
      scale_down_delay_after_failure = var.auto_scaler_profile.scale_down_delay_after_failure
      scan_interval                  = var.auto_scaler_profile.scan_interval
      scale_down_unneeded            = var.auto_scaler_profile.scale_down_unneeded
      scale_down_unready             = var.auto_scaler_profile.scale_down_unready
      scale_down_utilization_threshold = var.auto_scaler_profile.scale_down_utilization_threshold
      empty_bulk_delete_max          = var.auto_scaler_profile.empty_bulk_delete_max
      skip_nodes_with_local_storage  = var.auto_scaler_profile.skip_nodes_with_local_storage
      skip_nodes_with_system_pods    = var.auto_scaler_profile.skip_nodes_with_system_pods
    }
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.enable_maintenance_window ? [1] : []
    content {
      dynamic "allowed" {
        for_each = var.maintenance_window_allowed
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
      dynamic "not_allowed" {
        for_each = var.maintenance_window_not_allowed
        content {
          end   = not_allowed.value.end
          start = not_allowed.value.start
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = each.value.vm_size
  node_count           = each.value.node_count
  min_count            = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count            = each.value.enable_auto_scaling ? each.value.max_count : null
  enable_auto_scaling  = each.value.enable_auto_scaling
  availability_zones   = each.value.availability_zones
  
  vnet_subnet_id         = var.subnet_id
  orchestrator_version   = var.kubernetes_version
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_type               = each.value.os_type
  enable_node_public_ip = false
  
  upgrade_settings {
    max_surge = each.value.max_surge
  }

  node_labels = each.value.node_labels
  node_taints = each.value.node_taints

  tags = merge(var.tags, each.value.tags)
}