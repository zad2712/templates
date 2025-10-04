# DynamoDB Module Outputs

# Table Information
output "tables" {
  description = "Complete information about created DynamoDB tables"
  value = {
    for table_key, table in aws_dynamodb_table.tables : table_key => {
      # Basic table information
      id                = table.id
      name              = table.name
      arn               = table.arn
      billing_mode      = table.billing_mode
      hash_key          = table.hash_key
      range_key         = table.range_key
      table_class       = table.table_class
      
      # Capacity information
      read_capacity     = table.read_capacity
      write_capacity    = table.write_capacity
      
      # Stream information
      stream_enabled    = table.stream_enabled
      stream_arn        = table.stream_arn
      stream_label      = table.stream_label
      stream_view_type  = table.stream_view_type
      
      # Backup and recovery
      point_in_time_recovery_enabled = table.point_in_time_recovery[0].enabled
      deletion_protection_enabled    = table.deletion_protection_enabled
      
      # Encryption
      server_side_encryption = {
        enabled    = length(table.server_side_encryption) > 0 ? table.server_side_encryption[0].enabled : false
        kms_key_id = length(table.server_side_encryption) > 0 ? table.server_side_encryption[0].kms_key_id : null
      }
      
      # TTL configuration
      ttl = length(table.ttl) > 0 ? {
        attribute_name = table.ttl[0].attribute_name
        enabled        = table.ttl[0].enabled
      } : null
      
      # Indexes
      global_secondary_indexes = [
        for gsi in table.global_secondary_index : {
          name               = gsi.name
          hash_key           = gsi.hash_key
          range_key          = gsi.range_key
          projection_type    = gsi.projection_type
          non_key_attributes = gsi.non_key_attributes
          read_capacity      = gsi.read_capacity
          write_capacity     = gsi.write_capacity
          arn                = gsi.arn
        }
      ]
      
      local_secondary_indexes = [
        for lsi in table.local_secondary_index : {
          name               = lsi.name
          range_key          = lsi.range_key
          projection_type    = lsi.projection_type
          non_key_attributes = lsi.non_key_attributes
        }
      ]
      
      # Attributes
      attributes = [
        for attr in table.attribute : {
          name = attr.name
          type = attr.type
        }
      ]
      
      # Tags
      tags = table.tags
    }
  }
}

output "table_names" {
  description = "Map of table keys to table names"
  value = {
    for table_key, table in aws_dynamodb_table.tables : table_key => table.name
  }
}

output "table_arns" {
  description = "Map of table keys to table ARNs"
  value = {
    for table_key, table in aws_dynamodb_table.tables : table_key => table.arn
  }
}

output "table_stream_arns" {
  description = "Map of table keys to stream ARNs (only for tables with streams enabled)"
  value = {
    for table_key, table in aws_dynamodb_table.tables : table_key => table.stream_arn
    if table.stream_enabled
  }
}

# Global Tables Information
output "global_tables" {
  description = "Complete information about created DynamoDB Global Tables"
  value = {
    for gt_key, gt in aws_dynamodb_table.global_tables : gt_key => {
      # Basic table information
      id                = gt.id
      name              = gt.name
      arn               = gt.arn
      hash_key          = gt.hash_key
      range_key         = gt.range_key
      
      # Stream information (required for global tables)
      stream_arn        = gt.stream_arn
      stream_label      = gt.stream_label
      
      # Replicas
      replicas = [
        for replica in gt.replica : {
          region_name                   = replica.region_name
          arn                          = replica.arn
          stream_arn                   = replica.stream_arn
          stream_label                 = replica.stream_label
          point_in_time_recovery       = replica.point_in_time_recovery
          table_class                  = replica.table_class
          kms_key_id                   = replica.kms_key_id
          global_secondary_indexes     = replica.global_secondary_index
        }
      ]
      
      # Encryption
      server_side_encryption = {
        enabled    = gt.server_side_encryption[0].enabled
        kms_key_id = gt.server_side_encryption[0].kms_key_id
      }
      
      # TTL configuration
      ttl = length(gt.ttl) > 0 ? {
        attribute_name = gt.ttl[0].attribute_name
        enabled        = gt.ttl[0].enabled
      } : null
      
      # Global secondary indexes
      global_secondary_indexes = [
        for gsi in gt.global_secondary_index : {
          name               = gsi.name
          hash_key           = gsi.hash_key
          range_key          = gsi.range_key
          projection_type    = gsi.projection_type
          non_key_attributes = gsi.non_key_attributes
        }
      ]
      
      # Attributes
      attributes = [
        for attr in gt.attribute : {
          name = attr.name
          type = attr.type
        }
      ]
      
      # Tags
      tags = gt.tags
    }
  }
}

output "global_table_names" {
  description = "Map of global table keys to table names"
  value = {
    for gt_key, gt in aws_dynamodb_table.global_tables : gt_key => gt.name
  }
}

output "global_table_arns" {
  description = "Map of global table keys to table ARNs"
  value = {
    for gt_key, gt in aws_dynamodb_table.global_tables : gt_key => gt.arn
  }
}

# Auto Scaling Information
output "autoscaling_targets" {
  description = "Auto scaling target information"
  value = {
    read_capacity = {
      for table_key, target in aws_appautoscaling_target.read_capacity : table_key => {
        arn                = target.arn
        max_capacity       = target.max_capacity
        min_capacity       = target.min_capacity
        resource_id        = target.resource_id
        scalable_dimension = target.scalable_dimension
        service_namespace  = target.service_namespace
      }
    }
    write_capacity = {
      for table_key, target in aws_appautoscaling_target.write_capacity : table_key => {
        arn                = target.arn
        max_capacity       = target.max_capacity
        min_capacity       = target.min_capacity
        resource_id        = target.resource_id
        scalable_dimension = target.scalable_dimension
        service_namespace  = target.service_namespace
      }
    }
  }
}

output "autoscaling_policies" {
  description = "Auto scaling policy information"
  value = {
    read_capacity = {
      for table_key, policy in aws_appautoscaling_policy.read_capacity_policy : table_key => {
        arn         = policy.arn
        name        = policy.name
        policy_type = policy.policy_type
        resource_id = policy.resource_id
        target_tracking_scaling_policy_configuration = policy.target_tracking_scaling_policy_configuration
      }
    }
    write_capacity = {
      for table_key, policy in aws_appautoscaling_policy.write_capacity_policy : table_key => {
        arn         = policy.arn
        name        = policy.name
        policy_type = policy.policy_type
        resource_id = policy.resource_id
        target_tracking_scaling_policy_configuration = policy.target_tracking_scaling_policy_configuration
      }
    }
  }
}

# Backup Information
output "backup_vault" {
  description = "DynamoDB backup vault information"
  value = length(aws_dynamodb_backup_vault.backup_vault) > 0 ? {
    arn         = aws_dynamodb_backup_vault.backup_vault[0].arn
    name        = aws_dynamodb_backup_vault.backup_vault[0].name
    kms_key_arn = aws_dynamodb_backup_vault.backup_vault[0].kms_key_arn
    tags        = aws_dynamodb_backup_vault.backup_vault[0].tags
  } : null
}

output "backup_plan" {
  description = "DynamoDB backup plan information"
  value = length(aws_backup_plan.dynamodb_backup) > 0 ? {
    arn     = aws_backup_plan.dynamodb_backup[0].arn
    id      = aws_backup_plan.dynamodb_backup[0].id
    name    = aws_backup_plan.dynamodb_backup[0].name
    version = aws_backup_plan.dynamodb_backup[0].version
    rules   = aws_backup_plan.dynamodb_backup[0].rule
    tags    = aws_backup_plan.dynamodb_backup[0].tags
  } : null
}

output "backup_selection" {
  description = "DynamoDB backup selection information"
  value = length(aws_backup_selection.dynamodb_backup_selection) > 0 ? {
    id           = aws_backup_selection.dynamodb_backup_selection[0].id
    iam_role_arn = aws_backup_selection.dynamodb_backup_selection[0].iam_role_arn
    name         = aws_backup_selection.dynamodb_backup_selection[0].name
    plan_id      = aws_backup_selection.dynamodb_backup_selection[0].plan_id
    resources    = aws_backup_selection.dynamodb_backup_selection[0].resources
  } : null
}

# Monitoring Information
output "cloudwatch_alarms" {
  description = "CloudWatch alarms for DynamoDB monitoring"
  value = {
    read_throttled_requests = {
      for table_key, alarm in aws_cloudwatch_metric_alarm.read_throttled_requests : table_key => {
        arn                 = alarm.arn
        alarm_name          = alarm.alarm_name
        comparison_operator = alarm.comparison_operator
        metric_name         = alarm.metric_name
        namespace           = alarm.namespace
        threshold           = alarm.threshold
        dimensions          = alarm.dimensions
      }
    }
    
    write_throttled_requests = {
      for table_key, alarm in aws_cloudwatch_metric_alarm.write_throttled_requests : table_key => {
        arn                 = alarm.arn
        alarm_name          = alarm.alarm_name
        comparison_operator = alarm.comparison_operator
        metric_name         = alarm.metric_name
        namespace           = alarm.namespace
        threshold           = alarm.threshold
        dimensions          = alarm.dimensions
      }
    }
    
    system_errors = {
      for table_key, alarm in aws_cloudwatch_metric_alarm.system_errors : table_key => {
        arn                 = alarm.arn
        alarm_name          = alarm.alarm_name
        comparison_operator = alarm.comparison_operator
        metric_name         = alarm.metric_name
        namespace           = alarm.namespace
        threshold           = alarm.threshold
        dimensions          = alarm.dimensions
      }
    }
  }
}

output "contributor_insights" {
  description = "DynamoDB Contributor Insights status"
  value = {
    for table_key, insights in aws_dynamodb_contributor_insights.table_insights : table_key => {
      id         = insights.id
      table_name = insights.table_name
      tags       = insights.tags
    }
  }
}

# Stream Processing Information
output "stream_processor_role" {
  description = "IAM role for DynamoDB stream processing"
  value = length(aws_iam_role.stream_processor_role) > 0 ? {
    arn                   = aws_iam_role.stream_processor_role[0].arn
    name                  = aws_iam_role.stream_processor_role[0].name
    assume_role_policy    = aws_iam_role.stream_processor_role[0].assume_role_policy
    tags                  = aws_iam_role.stream_processor_role[0].tags
  } : null
}

output "stream_event_source_mappings" {
  description = "Lambda event source mappings for DynamoDB streams"
  value = {
    for func_key, mapping in aws_lambda_event_source_mapping.dynamodb_stream_mapping : func_key => {
      uuid                                   = mapping.uuid
      event_source_arn                      = mapping.event_source_arn
      function_name                         = mapping.function_name
      starting_position                     = mapping.starting_position
      batch_size                           = mapping.batch_size
      maximum_batching_window_in_seconds   = mapping.maximum_batching_window_in_seconds
      parallelization_factor               = mapping.parallelization_factor
      maximum_record_age_in_seconds        = mapping.maximum_record_age_in_seconds
      bisect_batch_on_function_error      = mapping.bisect_batch_on_function_error
      maximum_retry_attempts              = mapping.maximum_retry_attempts
      tumbling_window_in_seconds          = mapping.tumbling_window_in_seconds
      state                               = mapping.state
      state_transition_reason             = mapping.state_transition_reason
      last_modified                       = mapping.last_modified
      last_processing_result              = mapping.last_processing_result
    }
  }
}

# Security and Access Information
output "security_summary" {
  description = "Security configuration summary"
  value = {
    encryption = {
      tables_with_encryption = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if length(table.server_side_encryption) > 0 && table.server_side_encryption[0].enabled
      ])
      
      tables_with_kms_encryption = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if length(table.server_side_encryption) > 0 && table.server_side_encryption[0].enabled && 
           table.server_side_encryption[0].kms_key_id != null
      ])
      
      global_tables_encrypted = length([
        for gt_key, gt in aws_dynamodb_table.global_tables : gt_key
        if gt.server_side_encryption[0].enabled
      ])
    }
    
    backup_and_recovery = {
      tables_with_pitr = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.point_in_time_recovery[0].enabled
      ])
      
      tables_with_deletion_protection = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.deletion_protection_enabled
      ])
      
      backup_vault_enabled = length(aws_dynamodb_backup_vault.backup_vault) > 0
      backup_plan_configured = length(aws_backup_plan.dynamodb_backup) > 0
    }
    
    monitoring = {
      cloudwatch_alarms_enabled = var.enable_cloudwatch_alarms
      contributor_insights_enabled = var.enable_contributor_insights
      
      tables_with_streams = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.stream_enabled
      ])
      
      stream_processors_configured = length(var.stream_processor_functions)
    }
  }
}

# Performance Summary
output "performance_summary" {
  description = "Performance configuration summary"
  value = {
    billing_modes = {
      pay_per_request = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.billing_mode == "PAY_PER_REQUEST"
      ])
      
      provisioned = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.billing_mode == "PROVISIONED"
      ])
    }
    
    table_classes = {
      standard = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.table_class == "STANDARD"
      ])
      
      infrequent_access = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.table_class == "STANDARD_INFREQUENT_ACCESS"
      ])
    }
    
    autoscaling = {
      tables_with_autoscaling = length([
        for table_key, table in local.tables : table_key
        if table.billing_mode == "PROVISIONED" && lookup(table, "autoscaling", {}) != {}
      ])
      
      read_capacity_targets = length(aws_appautoscaling_target.read_capacity)
      write_capacity_targets = length(aws_appautoscaling_target.write_capacity)
    }
    
    indexes = {
      global_secondary_indexes = sum([
        for table_key, table in aws_dynamodb_table.tables : length(table.global_secondary_index)
      ])
      
      local_secondary_indexes = sum([
        for table_key, table in aws_dynamodb_table.tables : length(table.local_secondary_index)
      ])
    }
    
    global_tables = {
      total_global_tables = length(aws_dynamodb_table.global_tables)
      total_replicas = sum([
        for gt_key, gt in aws_dynamodb_table.global_tables : length(gt.replica)
      ])
    }
  }
}

# Cost Optimization Summary
output "cost_optimization_summary" {
  description = "Cost optimization insights and recommendations"
  value = {
    billing_recommendations = {
      pay_per_request_tables = [
        for table_key, table in aws_dynamodb_table.tables : {
          table_key = table_key
          table_name = table.name
          recommendation = "Consider PROVISIONED billing if consistent traffic patterns"
        }
        if table.billing_mode == "PAY_PER_REQUEST"
      ]
      
      provisioned_tables = [
        for table_key, table in aws_dynamodb_table.tables : {
          table_key = table_key
          table_name = table.name
          recommendation = "Monitor capacity utilization for optimization opportunities"
        }
        if table.billing_mode == "PROVISIONED"
      ]
    }
    
    table_class_recommendations = [
      for table_key, table in aws_dynamodb_table.tables : {
        table_key = table_key
        table_name = table.name
        current_class = table.table_class
        recommendation = table.table_class == "STANDARD" ? 
          "Consider STANDARD_INFREQUENT_ACCESS for infrequently accessed data (up to 60% cost savings)" :
          "Already using cost-optimized table class"
      }
    ]
    
    backup_optimization = {
      continuous_backups = length([
        for table_key, table in aws_dynamodb_table.tables : table_key
        if table.point_in_time_recovery[0].enabled
      ])
      
      recommendation = "Point-in-time recovery provides continuous backups. Consider on-demand backups for specific requirements."
    }
    
    global_tables_cost = length(aws_dynamodb_table.global_tables) > 0 ? {
      total_replicas = sum([
        for gt_key, gt in aws_dynamodb_table.global_tables : length(gt.replica)
      ])
      
      recommendation = "Global tables replicate data across regions. Ensure all replicas are necessary for your use case."
    } : null
    
    monitoring_costs = {
      contributor_insights_enabled = var.enable_contributor_insights
      cloudwatch_alarms_count = var.enable_cloudwatch_alarms ? length(local.tables) * 3 : 0
      
      recommendation = "Monitor CloudWatch costs. Disable detailed monitoring for non-critical tables."
    }
  }
}

# Integration Points
output "integration_endpoints" {
  description = "Integration endpoints for other AWS services"
  value = {
    # Table endpoints for Lambda integration
    table_endpoints = {
      for table_key, table in aws_dynamodb_table.tables : table_key => {
        table_name = table.name
        table_arn  = table.arn
        stream_arn = table.stream_enabled ? table.stream_arn : null
        
        # Example IAM policy for Lambda integration
        lambda_policy_document = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query",
                "dynamodb:Scan"
              ]
              Resource = [
                table.arn,
                "${table.arn}/index/*"
              ]
            }
          ] + (table.stream_enabled ? [{
            Effect = "Allow"
            Action = [
              "dynamodb:DescribeStream",
              "dynamodb:GetRecords",
              "dynamodb:GetShardIterator",
              "dynamodb:ListStreams"
            ]
            Resource = table.stream_arn
          }] : [])
        })
      }
    }
    
    # API Gateway integration parameters
    api_gateway_integration = {
      for table_key, table in aws_dynamodb_table.tables : table_key => {
        table_name = table.name
        region = data.aws_region.current.name
        
        # Example API Gateway integration URI
        integration_uri = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/GetItem"
        
        # Example request templates
        request_templates = {
          "application/json" = jsonencode({
            TableName = table.name
            Key = {
              id = {
                S = "$input.params('id')"
              }
            }
          })
        }
      }
    }
  }
}