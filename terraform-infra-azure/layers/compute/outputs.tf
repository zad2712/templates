# =============================================================================
# COMPUTE LAYER - OUTPUTS
# =============================================================================

# =============================================================================
# RESOURCE GROUP OUTPUTS
# =============================================================================

output "resource_group_id" {
  description = "ID of the compute resource group"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Name of the compute resource group"
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "Location of the compute resource group"
  value       = module.resource_group.location
}

# =============================================================================
# AKS CLUSTER OUTPUTS
# =============================================================================

output "aks_clusters" {
  description = "Map of AKS cluster information"
  value = var.enable_aks ? {
    for name, cluster in module.aks_cluster : name => {
      id                = cluster.aks_cluster_id
      name              = cluster.aks_cluster_name
      fqdn              = cluster.aks_cluster_fqdn
      kube_config       = cluster.aks_cluster_kube_config
      cluster_identity  = cluster.aks_cluster_identity
      node_pools        = cluster.aks_node_pools
      oms_agent_identity = cluster.oms_agent_identity
      kubelet_identity  = cluster.kubelet_identity
    }
  } : {}
  sensitive = true
}

output "aks_cluster_ids" {
  description = "Map of AKS cluster IDs"
  value = var.enable_aks ? {
    for name, cluster in module.aks_cluster : name => cluster.aks_cluster_id
  } : {}
}

output "aks_cluster_names" {
  description = "Map of AKS cluster names"
  value = var.enable_aks ? {
    for name, cluster in module.aks_cluster : name => cluster.aks_cluster_name
  } : {}
}

# =============================================================================
# FUNCTION APP OUTPUTS
# =============================================================================

output "function_apps" {
  description = "Map of Function App information"
  value = var.enable_function_apps ? {
    for name, app in module.function_app : name => {
      id                    = app.function_app_id
      name                  = app.function_app_name
      default_hostname      = app.function_app_default_hostname
      outbound_ip_addresses = app.function_app_outbound_ip_addresses
      identity              = app.function_app_identity
      app_service_plan_id   = app.app_service_plan_id
      storage_account_id    = app.storage_account_id
      application_insights_id = app.application_insights_id
    }
  } : {}
}

output "function_app_ids" {
  description = "Map of Function App IDs"
  value = var.enable_function_apps ? {
    for name, app in module.function_app : name => app.function_app_id
  } : {}
}

output "function_app_hostnames" {
  description = "Map of Function App hostnames"
  value = var.enable_function_apps ? {
    for name, app in module.function_app : name => app.function_app_default_hostname
  } : {}
}

# =============================================================================
# WEB APP OUTPUTS
# =============================================================================

output "web_apps" {
  description = "Map of Web App information"
  value = var.enable_web_apps ? {
    for name, app in module.web_app : name => {
      id                               = app.web_app_id
      name                             = app.web_app_name
      url                              = app.web_app_url
      default_hostname                 = app.web_app_default_hostname
      outbound_ip_addresses           = app.web_app_outbound_ip_addresses
      possible_outbound_ip_addresses  = app.web_app_possible_outbound_ip_addresses
      identity                        = app.web_app_identity
      app_service_plan_id             = app.app_service_plan_id
      custom_domain_verification_id   = app.custom_domain_verification_id
      custom_domains                  = app.custom_domains
      application_insights_id         = app.application_insights_id
      private_endpoint_id             = app.private_endpoint_id
      private_endpoint_ip_address     = app.private_endpoint_ip_address
    }
  } : {}
}

output "web_app_ids" {
  description = "Map of Web App IDs"
  value = var.enable_web_apps ? {
    for name, app in module.web_app : name => app.web_app_id
  } : {}
}

output "web_app_urls" {
  description = "Map of Web App URLs"
  value = var.enable_web_apps ? {
    for name, app in module.web_app : name => app.web_app_url
  } : {}
}

output "web_app_identities" {
  description = "Map of Web App managed identities"
  value = var.enable_web_apps ? {
    for name, app in module.web_app : name => app.web_app_identity
  } : {}
}

# =============================================================================
# APP SERVICE OUTPUTS (Legacy)
# =============================================================================

output "app_services" {
  description = "Map of App Service information (legacy module)"
  value = var.enable_app_services ? {
    for name, app in module.app_service : name => {
      id                    = app.app_service_id
      name                  = app.app_service_name
      default_hostname      = app.app_service_default_hostname
      outbound_ip_addresses = app.app_service_outbound_ip_addresses
      identity              = app.app_service_identity
      app_service_plan_id   = app.app_service_plan_id
    }
  } : {}
}

output "app_service_ids" {
  description = "Map of App Service IDs (legacy module)"
  value = var.enable_app_services ? {
    for name, app in module.app_service : name => app.app_service_id
  } : {}
}

# =============================================================================
# CONTAINER INSTANCE OUTPUTS
# =============================================================================

output "container_instances" {
  description = "Map of Container Instance information"
  value = var.enable_container_instances ? {
    for name, instance in module.container_instance : name => {
      id         = instance.container_instance_id
      name       = instance.container_instance_name
      ip_address = instance.container_instance_ip_address
      fqdn       = instance.container_instance_fqdn
      identity   = instance.container_instance_identity
    }
  } : {}
}

output "container_instance_ids" {
  description = "Map of Container Instance IDs"
  value = var.enable_container_instances ? {
    for name, instance in module.container_instance : name => instance.container_instance_id
  } : {}
}

output "container_instance_ip_addresses" {
  description = "Map of Container Instance IP addresses"
  value = var.enable_container_instances ? {
    for name, instance in module.container_instance : name => instance.container_instance_ip_address
  } : {}
}

# =============================================================================
# VIRTUAL MACHINE OUTPUTS
# =============================================================================

output "virtual_machines" {
  description = "Map of Virtual Machine information"
  value = var.enable_virtual_machines ? {
    for name, vm in module.virtual_machine : name => {
      id                 = vm.virtual_machine_id
      name               = vm.virtual_machine_name
      private_ip_address = vm.private_ip_address
      public_ip_address  = vm.public_ip_address
      identity           = vm.virtual_machine_identity
      network_interface_id = vm.network_interface_id
    }
  } : {}
}

output "virtual_machine_ids" {
  description = "Map of Virtual Machine IDs"
  value = var.enable_virtual_machines ? {
    for name, vm in module.virtual_machine : name => vm.virtual_machine_id
  } : {}
}

output "virtual_machine_private_ips" {
  description = "Map of Virtual Machine private IP addresses"
  value = var.enable_virtual_machines ? {
    for name, vm in module.virtual_machine : name => vm.private_ip_address
  } : {}
}

# =============================================================================
# SUMMARY OUTPUTS
# =============================================================================

output "compute_summary" {
  description = "Summary of all compute resources"
  value = {
    resource_group = {
      id       = module.resource_group.id
      name     = module.resource_group.name
      location = module.resource_group.location
    }
    
    services_enabled = {
      aks_clusters         = var.enable_aks
      function_apps        = var.enable_function_apps
      web_apps            = var.enable_web_apps
      app_services        = var.enable_app_services
      container_instances = var.enable_container_instances
      virtual_machines    = var.enable_virtual_machines
    }
    
    resource_counts = {
      aks_clusters         = var.enable_aks ? length(var.aks_clusters) : 0
      function_apps        = var.enable_function_apps ? length(var.function_apps) : 0
      web_apps            = var.enable_web_apps ? length(var.web_apps) : 0
      app_services        = var.enable_app_services ? length(var.app_services) : 0
      container_instances = var.enable_container_instances ? length(var.container_instances) : 0
      virtual_machines    = var.enable_virtual_machines ? length(var.virtual_machines) : 0
    }
    
    networking = {
      private_endpoints_enabled = var.enable_private_endpoints
    }
    
    monitoring = {
      diagnostic_settings_enabled = var.enable_diagnostic_settings
      monitoring_enabled          = var.enable_monitoring
    }
  }
}