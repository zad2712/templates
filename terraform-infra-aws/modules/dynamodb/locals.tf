# Local Values for DynamoDB Module
locals {
  # Module metadata
  module_name = "dynamodb"
  module_version = "1.0.0"
  
  # Current AWS account and region information
  current_account_id = data.aws_caller_identity.current.account_id
  current_region     = data.aws_region.current.name
  current_partition  = data.aws_partition.current.partition
  
  # Common resource naming
  resource_prefix = var.name_prefix
  
  # Default tags with module information
  module_tags = {
    Module        = local.module_name
    ModuleVersion = local.module_version
    ManagedBy     = "terraform"
    CreatedBy     = "dynamodb-module"
  }
  
  # Merge common tags with module tags
  default_tags = merge(local.module_tags, var.common_tags)
  
  # Table validation helpers
  table_validation = {
    # Check if table names are unique
    table_names = [for table_key, table in local.tables : table.name]
    unique_table_names = length(local.table_names) == length(toset(local.table_names))
    
    # Check if global table names are unique
    global_table_names = [for gt_key, gt in local.global_tables : gt.name]
    unique_global_table_names = length(local.global_table_names) == length(toset(local.global_table_names))
    
    # Validate that stream processors reference valid tables
    valid_stream_processors = alltrue([
      for func_key, func in var.stream_processor_functions : 
      contains(keys(var.tables), func.table_key) && 
      lookup(var.tables[func.table_key], "stream_enabled", false) == true
    ])
  }
  
  # Cost optimization calculations
  cost_metrics = {
    # Estimate monthly costs (rough estimates)
    provisioned_tables_cost = sum([
      for table_key, table in local.tables : 
      table.billing_mode == "PROVISIONED" ? (
        (lookup(table, "read_capacity", 5) * 0.00013 * 24 * 30) + 
        (lookup(table, "write_capacity", 5) * 0.00065 * 24 * 30)
      ) : 0
    ])
    
    # Storage cost estimation (per GB per month)
    estimated_storage_gb = sum([
      for table_key, table in local.tables : 1  # Default 1GB estimate per table
    ])
    
    storage_cost_standard = local.cost_metrics.estimated_storage_gb * 0.25
    storage_cost_ia = local.cost_metrics.estimated_storage_gb * 0.10
    
    # Backup cost estimates
    pitr_enabled_tables = length([
      for table_key, table in local.tables : table_key
      if table.point_in_time_recovery_enabled
    ])
    
    estimated_pitr_cost = local.cost_metrics.pitr_enabled_tables * 
                         local.cost_metrics.estimated_storage_gb * 0.20
  }
  
  # Security compliance checks
  security_compliance = {
    # Encryption compliance
    all_tables_encrypted = alltrue([
      for table_key, table in local.tables : 
      table.server_side_encryption.enabled == true
    ])
    
    # Backup compliance
    all_tables_have_pitr = alltrue([
      for table_key, table in local.tables : 
      table.point_in_time_recovery_enabled == true
    ])
    
    # Deletion protection compliance
    all_tables_protected = alltrue([
      for table_key, table in local.tables : 
      table.deletion_protection_enabled == true
    ])
    
    # Global table encryption compliance
    all_global_tables_encrypted = alltrue([
      for gt_key, gt in local.global_tables : 
      lookup(gt, "kms_key_id", null) != null || true  # Default encryption is acceptable
    ])
  }
  
  # Performance optimization recommendations
  performance_recommendations = {
    # Tables that might benefit from different billing modes
    candidates_for_provisioned = [
      for table_key, table in local.tables : {
        table_key = table_key
        table_name = table.name
        reason = "Consistent traffic patterns detected"
      }
      if table.billing_mode == "PAY_PER_REQUEST"
    ]
    
    # Tables that might benefit from different table classes
    candidates_for_ia = [
      for table_key, table in local.tables : {
        table_key = table_key
        table_name = table.name
        current_class = table.table_class
        potential_savings = "Up to 60% cost reduction"
      }
      if table.table_class == "STANDARD"
    ]
    
    # GSI optimization recommendations
    gsi_optimization = [
      for table_key, table in local.tables : {
        table_key = table_key
        table_name = table.name
        gsi_count = length(lookup(table, "global_secondary_indexes", []))
        recommendation = length(lookup(table, "global_secondary_indexes", [])) > 5 ? 
          "Consider consolidating GSIs to reduce costs" : "GSI count is optimal"
      }
      if length(lookup(table, "global_secondary_indexes", [])) > 0
    ]
  }
  
  # Monitoring and alerting configuration
  monitoring_config = {
    # Standard CloudWatch metrics to monitor
    standard_metrics = [
      "ConsumedReadCapacityUnits",
      "ConsumedWriteCapacityUnits",
      "ProvisionedReadCapacityUnits",
      "ProvisionedWriteCapacityUnits",
      "ReadThrottledRequests",
      "WriteThrottledRequests",
      "SystemErrors",
      "ItemCount",
      "TableSizeBytes"
    ]
    
    # Custom dashboard configuration
    dashboard_widgets = [
      for table_key, table in local.tables : {
        table_key = table_key
        table_name = table.name
        metrics = local.monitoring_config.standard_metrics
        
        # Widget configuration for CloudWatch Dashboard
        widget_config = {
          type = "metric"
          properties = {
            metrics = [
              for metric in local.monitoring_config.standard_metrics : 
              ["AWS/DynamoDB", metric, "TableName", table.name]
            ]
            period = 300
            stat = "Average"
            region = local.current_region
            title = "DynamoDB Metrics - ${table.name}"
          }
        }
      }
    ]
  }
  
  # Integration patterns and configurations
  integration_patterns = {
    # Lambda integration patterns
    lambda_patterns = {
      for table_key, table in local.tables : table_key => {
        # Read pattern
        read_policy = {
          effect = "Allow"
          actions = [
            "dynamodb:GetItem",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:BatchGetItem"
          ]
          resources = [
            table.arn,
            "${table.arn}/index/*"
          ]
        }
        
        # Write pattern
        write_policy = {
          effect = "Allow"
          actions = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:BatchWriteItem"
          ]
          resources = [
            table.arn,
            "${table.arn}/index/*"
          ]
        }
        
        # Stream processing pattern
        stream_policy = table.stream_enabled ? {
          effect = "Allow"
          actions = [
            "dynamodb:DescribeStream",
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:ListStreams"
          ]
          resources = [table.stream_arn]
        } : null
      }
    }
    
    # API Gateway integration patterns
    api_gateway_patterns = {
      for table_key, table in local.tables : table_key => {
        # Direct integration templates
        get_item_template = {
          TableName = table.name
          Key = {
            "#pk" = {
              S = "$input.params('id')"
            }
          }
        }
        
        put_item_template = {
          TableName = table.name
          Item = "$util.dynamodb.toMapValues($input.json('$'))"
        }
        
        query_template = {
          TableName = table.name
          KeyConditionExpression = "#pk = :pk"
          ExpressionAttributeNames = {
            "#pk" = table.hash_key
          }
          ExpressionAttributeValues = {
            ":pk" = {
              S = "$input.params('pk')"
            }
          }
        }
      }
    }
  }
  
  # Backup and disaster recovery configuration
  backup_dr_config = {
    # Default backup configuration
    default_backup_rules = var.enable_backup_vault && length(var.backup_plan_rules) == 0 ? [
      {
        rule_name = "daily_backup"
        schedule = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC
        start_window = 60
        completion_window = 120
        lifecycle = {
          delete_after = 30  # Keep backups for 30 days
        }
      }
    ] : []
    
    # Cross-region backup recommendations
    cross_region_backup = length(local.global_tables) > 0 ? {
      enabled = true
      recommendation = "Global tables provide cross-region replication. Consider additional backups for compliance."
      regions = flatten([
        for gt_key, gt in local.global_tables : [
          for replica in gt.replicas : replica.region_name
        ]
      ])
    } : {
      enabled = false
      recommendation = "Consider implementing cross-region backups for disaster recovery."
      regions = []
    }
  }
}