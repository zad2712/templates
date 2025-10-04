# =============================================================================
# AZURE MONITOR MODULE
# =============================================================================

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb     = var.daily_quota_gb

  # Internet and query access
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  # Reservation capacity commitment
  reservation_capacity_in_gb_per_day = var.reservation_capacity_in_gb_per_day

  tags = var.tags
}

# Log Analytics Solutions
resource "azurerm_log_analytics_solution" "main" {
  for_each = var.solutions

  solution_name         = each.key
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.application_type

  # Retention
  retention_in_days = var.application_insights_retention_days

  # Sampling
  sampling_percentage = var.sampling_percentage

  # Daily data cap
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled

  # Disable IP masking
  disable_ip_masking = var.disable_ip_masking

  # Force customer storage for profiler
  force_customer_storage_for_profiler = var.force_customer_storage_for_profiler

  # Internet ingestion and query
  internet_ingestion_enabled = var.app_insights_internet_ingestion_enabled
  internet_query_enabled     = var.app_insights_internet_query_enabled

  # Local authentication
  local_authentication_disabled = var.local_authentication_disabled

  tags = var.tags
}

# Action Groups
resource "azurerm_monitor_action_group" "main" {
  for_each = var.action_groups

  name                = each.value.name
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled            = each.value.enabled

  # Email receivers
  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address          = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  # SMS receivers
  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  # Webhook receivers
  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri            = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
  }

  # Logic App receivers
  dynamic "logic_app_receiver" {
    for_each = each.value.logic_app_receivers
    content {
      name                    = logic_app_receiver.value.name
      resource_id            = logic_app_receiver.value.resource_id
      callback_url           = logic_app_receiver.value.callback_url
      use_common_alert_schema = logic_app_receiver.value.use_common_alert_schema
    }
  }

  # Azure Function receivers
  dynamic "azure_function_receiver" {
    for_each = each.value.azure_function_receivers
    content {
      name                     = azure_function_receiver.value.name
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name           = azure_function_receiver.value.function_name
      http_trigger_url        = azure_function_receiver.value.http_trigger_url
      use_common_alert_schema = azure_function_receiver.value.use_common_alert_schema
    }
  }

  tags = var.tags
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "main" {
  for_each = var.metric_alerts

  name                = each.value.name
  resource_group_name = var.resource_group_name
  scopes             = each.value.scopes
  description        = each.value.description
  severity           = each.value.severity
  frequency          = each.value.frequency
  window_size        = each.value.window_size
  enabled            = each.value.enabled

  criteria {
    metric_namespace = each.value.criteria.metric_namespace
    metric_name      = each.value.criteria.metric_name
    aggregation      = each.value.criteria.aggregation
    operator         = each.value.criteria.operator
    threshold        = each.value.criteria.threshold

    dynamic "dimension" {
      for_each = each.value.criteria.dimensions
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Activity Log Alerts
resource "azurerm_monitor_activity_log_alert" "main" {
  for_each = var.activity_log_alerts

  name                = each.value.name
  resource_group_name = var.resource_group_name
  scopes             = each.value.scopes
  description        = each.value.description
  enabled            = each.value.enabled

  criteria {
    category    = each.value.criteria.category
    operation_name = each.value.criteria.operation_name
    resource_group = each.value.criteria.resource_group
    resource_type  = each.value.criteria.resource_type
    resource_provider = each.value.criteria.resource_provider
    level          = each.value.criteria.level
    status         = each.value.criteria.status
    sub_status     = each.value.criteria.sub_status
    recommendation_type = each.value.criteria.recommendation_type
    recommendation_category = each.value.criteria.recommendation_category
    recommendation_impact = each.value.criteria.recommendation_impact

    dynamic "service_health" {
      for_each = each.value.criteria.service_health != null ? [each.value.criteria.service_health] : []
      content {
        events    = service_health.value.events
        locations = service_health.value.locations
        services  = service_health.value.services
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_group_id = action.value
      webhook_properties = each.value.webhook_properties
    }
  }

  tags = var.tags
}

# Scheduled Query Rules (Log Alerts)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "main" {
  for_each = var.log_alerts

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location           = var.location
  
  evaluation_frequency = each.value.evaluation_frequency
  window_duration     = each.value.window_duration
  scopes             = each.value.scopes
  severity           = each.value.severity
  enabled            = each.value.enabled
  description        = each.value.description
  
  criteria {
    query                   = each.value.criteria.query
    time_aggregation_method = each.value.criteria.time_aggregation_method
    threshold              = each.value.criteria.threshold
    operator               = each.value.criteria.operator

    dynamic "dimension" {
      for_each = each.value.criteria.dimensions
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = each.value.criteria.failing_periods.minimum_failing_periods_to_trigger_alert
      number_of_evaluation_periods             = each.value.criteria.failing_periods.number_of_evaluation_periods
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_groups = [action.value]
      custom_properties = each.value.custom_properties
    }
  }

  # Auto mitigation
  auto_mitigation_enabled = each.value.auto_mitigation_enabled

  tags = var.tags
}

# Data Collection Rules
resource "azurerm_monitor_data_collection_rule" "main" {
  for_each = var.data_collection_rules

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location           = var.location
  description        = each.value.description

  # Destinations
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                 = "destination-log"
    }

    dynamic "azure_monitor_metrics" {
      for_each = each.value.destinations.azure_monitor_metrics != null ? [each.value.destinations.azure_monitor_metrics] : []
      content {
        name = azure_monitor_metrics.value.name
      }
    }
  }

  # Data flows
  dynamic "data_flow" {
    for_each = each.value.data_flows
    content {
      streams      = data_flow.value.streams
      destinations = data_flow.value.destinations
      
      dynamic "built_in_transform" {
        for_each = data_flow.value.built_in_transform != null ? [data_flow.value.built_in_transform] : []
        content {
          query = built_in_transform.value.query
        }
      }
    }
  }

  # Data sources
  dynamic "data_sources" {
    for_each = each.value.data_sources != null ? [each.value.data_sources] : []
    content {
      # Performance counters
      dynamic "performance_counter" {
        for_each = data_sources.value.performance_counters
        content {
          streams                       = performance_counter.value.streams
          sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
          counter_specifiers           = performance_counter.value.counter_specifiers
          name                        = performance_counter.value.name
        }
      }

      # Windows event logs
      dynamic "windows_event_log" {
        for_each = data_sources.value.windows_event_logs
        content {
          streams        = windows_event_log.value.streams
          x_path_queries = windows_event_log.value.x_path_queries
          name          = windows_event_log.value.name
        }
      }

      # Syslog
      dynamic "syslog" {
        for_each = data_sources.value.syslogs
        content {
          streams       = syslog.value.streams
          facility_names = syslog.value.facility_names
          log_levels    = syslog.value.log_levels
          name         = syslog.value.name
        }
      }
    }
  }

  tags = var.tags
}

# Workbooks
resource "azurerm_application_insights_workbook" "main" {
  for_each = var.workbooks

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location           = var.location
  display_name       = each.value.display_name
  data_json          = each.value.data_json
  description        = each.value.description
  source_id          = each.value.source_id

  tags = var.tags
}