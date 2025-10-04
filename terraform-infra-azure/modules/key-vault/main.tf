# =============================================================================
# AZURE KEY VAULT MODULE
# =============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  
  sku_name                      = var.sku_name
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  enabled_for_deployment        = var.enabled_for_deployment
  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization     = var.enable_rbac_authorization
  public_network_access_enabled = var.public_network_access_enabled

  # Network ACLs
  dynamic "network_acls" {
    for_each = var.enable_network_acls ? [1] : []
    content {
      default_action             = var.network_acls.default_action
      bypass                     = var.network_acls.bypass
      ip_rules                   = var.network_acls.ip_rules
      virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

# Access Policies (if not using RBAC)
resource "azurerm_key_vault_access_policy" "main" {
  for_each = var.enable_rbac_authorization ? {} : {
    for idx, policy in var.access_policies : idx => policy
  }

  key_vault_id   = azurerm_key_vault.main.id
  tenant_id      = each.value.tenant_id != null ? each.value.tenant_id : data.azurerm_client_config.current.tenant_id
  object_id      = each.value.object_id
  application_id = each.value.application_id

  certificate_permissions = each.value.certificate_permissions
  key_permissions        = each.value.key_permissions
  secret_permissions     = each.value.secret_permissions
  storage_permissions    = each.value.storage_permissions
}

# Secrets
resource "azurerm_key_vault_secret" "main" {
  for_each = var.secrets

  name            = each.key
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = each.value.content_type
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date
  tags           = each.value.tags

  depends_on = [azurerm_key_vault_access_policy.main]
}

# Keys
resource "azurerm_key_vault_key" "main" {
  for_each = var.keys

  name            = each.key
  key_vault_id    = azurerm_key_vault.main.id
  key_type        = each.value.key_type
  key_size        = each.value.key_size
  curve          = each.value.curve
  key_opts       = each.value.key_opts
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date
  tags           = each.value.tags

  depends_on = [azurerm_key_vault_access_policy.main]
}

# Certificates
resource "azurerm_key_vault_certificate" "main" {
  for_each = var.certificates

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id
  tags        = each.value.tags

  certificate_policy {
    issuer_parameters {
      name = each.value.certificate_policy.issuer_parameters.name
    }

    key_properties {
      exportable = each.value.certificate_policy.key_properties.exportable
      key_size   = each.value.certificate_policy.key_properties.key_size
      key_type   = each.value.certificate_policy.key_properties.key_type
      reuse_key  = each.value.certificate_policy.key_properties.reuse_key
    }

    dynamic "lifetime_action" {
      for_each = coalesce(each.value.certificate_policy.lifetime_actions, [])
      content {
        action {
          action_type = lifetime_action.value.action.action_type
        }
        trigger {
          days_before_expiry  = lifetime_action.value.trigger.days_before_expiry
          lifetime_percentage = lifetime_action.value.trigger.lifetime_percentage
        }
      }
    }

    secret_properties {
      content_type = each.value.certificate_policy.secret_properties.content_type
    }

    dynamic "x509_certificate_properties" {
      for_each = each.value.certificate_policy.x509_certificate_properties != null ? [each.value.certificate_policy.x509_certificate_properties] : []
      content {
        extended_key_usage = x509_certificate_properties.value.extended_key_usage
        key_usage          = x509_certificate_properties.value.key_usage
        subject           = x509_certificate_properties.value.subject
        validity_in_months = x509_certificate_properties.value.validity_in_months

        dynamic "subject_alternative_names" {
          for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []
          content {
            dns_names = subject_alternative_names.value.dns_names
            emails    = subject_alternative_names.value.emails
            upns      = subject_alternative_names.value.upns
          }
        }
      }
    }
  }

  depends_on = [azurerm_key_vault_access_policy.main]
}

# Contact information
resource "azurerm_key_vault_certificate_contacts" "main" {
  count = length(var.contact) > 0 ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id

  dynamic "contact" {
    for_each = var.contact
    content {
      email = contact.value.email
      name  = contact.value.name
      phone = contact.value.phone
    }
  }
}

# Private Endpoint
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id          = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.tags
}

# Private DNS Zone Group
resource "azurerm_private_dns_zone_group" "main" {
  count = var.enable_private_endpoint && var.private_dns_zone_id != null ? 1 : 0

  name                = "${var.name}-dns-zone-group"
  resource_group_name = var.resource_group_name
  private_endpoint_id = azurerm_private_endpoint.main[0].id

  private_dns_zone_config {
    name                 = "keyvault"
    private_dns_zone_id  = var.private_dns_zone_id
  }
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}

# Keys
resource "azurerm_key_vault_key" "main" {
  for_each = var.keys

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  curve        = each.value.curve
  key_opts     = each.value.key_opts

  expiration_date = each.value.expiration_date
  not_before_date = each.value.not_before_date

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.main]
}

# Secrets
resource "azurerm_key_vault_secret" "main" {
  for_each = var.secrets

  name            = each.key
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = each.value.content_type
  expiration_date = each.value.expiration_date
  not_before_date = each.value.not_before_date

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.main]
}

# Certificates
resource "azurerm_key_vault_certificate" "main" {
  for_each = var.certificates

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id

  dynamic "certificate_policy" {
    for_each = [each.value.certificate_policy]
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_parameters.name
      }

      key_properties {
        exportable = certificate_policy.value.key_properties.exportable
        key_size   = certificate_policy.value.key_properties.key_size
        key_type   = certificate_policy.value.key_properties.key_type
        reuse_key  = certificate_policy.value.key_properties.reuse_key
      }

      lifetime_action {
        action {
          action_type = certificate_policy.value.lifetime_action.action.action_type
        }

        trigger {
          days_before_expiry  = certificate_policy.value.lifetime_action.trigger.days_before_expiry
          lifetime_percentage = certificate_policy.value.lifetime_action.trigger.lifetime_percentage
        }
      }

      secret_properties {
        content_type = certificate_policy.value.secret_properties.content_type
      }

      dynamic "x509_certificate_properties" {
        for_each = certificate_policy.value.x509_certificate_properties != null ? [certificate_policy.value.x509_certificate_properties] : []
        content {
          extended_key_usage = x509_certificate_properties.value.extended_key_usage
          key_usage          = x509_certificate_properties.value.key_usage
          subject            = x509_certificate_properties.value.subject
          validity_in_months = x509_certificate_properties.value.validity_in_months

          dynamic "subject_alternative_names" {
            for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []
            content {
              dns_names = subject_alternative_names.value.dns_names
              emails    = subject_alternative_names.value.emails
              upns      = subject_alternative_names.value.upns
            }
          }
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.main]
}

# Private Endpoint (if enabled)
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names             = ["vault"]
    is_manual_connection          = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.diagnostic_storage_account_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.enabled_logs
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}