# =============================================================================
# KEY VAULT OUTPUTS
# =============================================================================

output "id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "tenant_id" {
  description = "The tenant ID of the Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "access_policies" {
  description = "The access policies of the Key Vault"
  value = [
    for policy in azurerm_key_vault_access_policy.main : {
      tenant_id               = policy.tenant_id
      object_id               = policy.object_id
      application_id          = policy.application_id
      certificate_permissions = policy.certificate_permissions
      key_permissions         = policy.key_permissions
      secret_permissions      = policy.secret_permissions
      storage_permissions     = policy.storage_permissions
    }
  ]
}

output "secrets" {
  description = "Map of secrets created in the Key Vault"
  value = {
    for k, secret in azurerm_key_vault_secret.main : k => {
      id           = secret.id
      name         = secret.name
      version      = secret.version
      versionless_id = secret.versionless_id
    }
  }
}

output "keys" {
  description = "Map of keys created in the Key Vault"
  value = {
    for k, key in azurerm_key_vault_key.main : k => {
      id           = key.id
      name         = key.name
      version      = key.version
      versionless_id = key.versionless_id
      public_key_pem = key.public_key_pem
      public_key_openssh = key.public_key_openssh
    }
  }
}

output "certificates" {
  description = "Map of certificates created in the Key Vault"
  value = {
    for k, cert in azurerm_key_vault_certificate.main : k => {
      id                    = cert.id
      name                  = cert.name
      version               = cert.version
      versionless_id        = cert.versionless_id
      certificate_data      = cert.certificate_data
      certificate_data_base64 = cert.certificate_data_base64
      thumbprint            = cert.thumbprint
      secret_id             = cert.secret_id
    }
  }
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = length(azurerm_private_endpoint.main) > 0 ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint"
  value       = length(azurerm_private_endpoint.main) > 0 ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

output "network_acls" {
  description = "The network ACLs of the Key Vault"
  value = azurerm_key_vault.main.network_acls != null ? {
    bypass                     = azurerm_key_vault.main.network_acls[0].bypass
    default_action            = azurerm_key_vault.main.network_acls[0].default_action
    ip_rules                  = azurerm_key_vault.main.network_acls[0].ip_rules
    virtual_network_subnet_ids = azurerm_key_vault.main.network_acls[0].virtual_network_subnet_ids
  } : null
}