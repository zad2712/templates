# Governance and Backup Configuration for AWS Landing Zone

# AWS Backup Vault
resource "aws_backup_vault" "main" {
  count = var.enable_backup_vault ? 1 : 0

  name        = "${var.organization_name}-${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.landing_zone.arn

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-backup-vault"
    Type = "Backup"
  })
}

# AWS Backup Plan
resource "aws_backup_plan" "main" {
  count = var.enable_backup_vault ? 1 : 0

  name = "${var.organization_name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily_backup_rule"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC

    lifecycle {
      cold_storage_after = 30
      delete_after       = var.backup_retention_days
    }

    recovery_point_tags = merge(local.common_tags, {
      BackupRule = "daily_backup_rule"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-backup-plan"
    Type = "Backup"
  })
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup" {
  count = var.enable_backup_vault ? 1 : 0

  name_prefix = "${var.organization_name}-${var.environment}-backup-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-backup-role"
    Type = "Security"
  })
}

# Attach AWS Backup service policy
resource "aws_iam_role_policy_attachment" "backup_policy" {
  count = var.enable_backup_vault ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore_policy" {
  count = var.enable_backup_vault ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Selection for EC2 instances
resource "aws_backup_selection" "ec2" {
  count = var.enable_backup_vault ? 1 : 0

  iam_role_arn = aws_iam_role.backup[0].arn
  name         = "${var.organization_name}-${var.environment}-ec2-backup-selection"
  plan_id      = aws_backup_plan.main[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = var.environment
  }

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Organization"
    value = var.organization_name
  }
}

# Cost Anomaly Detection
resource "aws_ce_anomaly_detector" "main" {
  name         = "${var.organization_name}-${var.environment}-cost-anomaly-detector"
  monitor_type = "DIMENSIONAL"

  specification = jsonencode({
    Dimension = "SERVICE"
    MatchOptions = ["EQUALS"]
    Values = ["EC2-Instance", "EBS", "RDS"]
  })

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-cost-anomaly-detector"
    Type = "Cost Management"
  })
}

# Cost Anomaly Subscription
resource "aws_ce_anomaly_subscription" "main" {
  name      = "${var.organization_name}-${var.environment}-cost-anomaly-subscription"
  frequency = "DAILY"
  
  monitor_arn_list = [
    aws_ce_anomaly_detector.main.arn
  ]
  
  subscriber {
    type    = "EMAIL"
    address = length(var.sns_email_endpoints) > 0 ? var.sns_email_endpoints[0] : "admin@example.com"
  }

  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = ["100"]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-cost-anomaly-subscription"
    Type = "Cost Management"
  })
}

# Resource Groups for better resource management
resource "aws_resourcegroups_group" "main" {
  name        = "${var.organization_name}-${var.environment}-resources"
  description = "Resource group for ${var.organization_name} ${var.environment} landing zone"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Environment"
          Values = [var.environment]
        },
        {
          Key    = "Organization"
          Values = [var.organization_name]
        }
      ]
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-resource-group"
    Type = "Management"
  })
}

# Systems Manager Parameter Store - Common configuration
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.organization_name}/${var.environment}/vpc/id"
  type  = "String"
  value = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-vpc-id-param"
    Type = "Configuration"
  })
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  name  = "/${var.organization_name}/${var.environment}/subnets/private/ids"
  type  = "StringList"
  value = join(",", aws_subnet.private[*].id)

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-private-subnet-ids-param"
    Type = "Configuration"
  })
}

resource "aws_ssm_parameter" "public_subnet_ids" {
  name  = "/${var.organization_name}/${var.environment}/subnets/public/ids"
  type  = "StringList"
  value = join(",", aws_subnet.public[*].id)

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-public-subnet-ids-param"
    Type = "Configuration"
  })
}

resource "aws_ssm_parameter" "database_subnet_ids" {
  name  = "/${var.organization_name}/${var.environment}/subnets/database/ids"
  type  = "StringList"
  value = join(",", aws_subnet.database[*].id)

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-database-subnet-ids-param"
    Type = "Configuration"
  })
}

# CloudFormation Stack Drift Detection
resource "aws_cloudformation_stack_drift_detection_config" "main" {
  stack_name = "${var.organization_name}-${var.environment}-drift-detection"
}

# Service Catalog Portfolio for standardized resources
resource "aws_servicecatalog_portfolio" "main" {
  name          = "${var.organization_name}-${var.environment}-portfolio"
  description   = "Service Catalog portfolio for ${var.organization_name} ${var.environment} standardized resources"
  provider_name = var.organization_name

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-service-catalog-portfolio"
    Type = "Governance"
  })
}