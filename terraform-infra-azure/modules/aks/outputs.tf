# =============================================================================
# AKS MODULE OUTPUTS
# =============================================================================

output "id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
  sensitive   = true
}

output "host" {
  description = "Host for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
  sensitive   = true
}

output "node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "kubelet_identity" {
  description = "Kubelet identity for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity
}

output "identity" {
  description = "Identity for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.identity
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "portal_fqdn" {
  description = "Portal FQDN for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "kubernetes_version" {
  description = "Kubernetes version of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "network_profile" {
  description = "Network profile of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.network_profile
}

output "additional_node_pools" {
  description = "Additional node pools for the AKS cluster"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => {
      id   = v.id
      name = v.name
    }
  }
}

# Cluster Summary
output "cluster_summary" {
  description = "Summary of AKS cluster configuration"
  value = {
    name                = azurerm_kubernetes_cluster.main.name
    kubernetes_version  = azurerm_kubernetes_cluster.main.kubernetes_version
    sku_tier           = azurerm_kubernetes_cluster.main.sku_tier
    private_cluster    = azurerm_kubernetes_cluster.main.private_cluster_enabled
    node_resource_group = azurerm_kubernetes_cluster.main.node_resource_group
    fqdn               = azurerm_kubernetes_cluster.main.fqdn
    additional_pools   = length(azurerm_kubernetes_cluster_node_pool.additional)
  }
}