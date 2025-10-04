# Monitoring and Logging Configuration for AWS Landing Zone

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.organization_name}-${var.environment}"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = aws_kms_key.landing_zone.arn

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-vpc-flow-logs"
    Type = "Monitoring"
  })
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name              = "/aws/cloudtrail/${var.organization_name}-${var.environment}"
  retention_in_days = var.cloudtrail_retention_days
  kms_key_id        = aws_kms_key.landing_zone.arn

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-cloudtrail-logs"
    Type = "Monitoring"
  })
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.organization_name}-${var.environment}-flow-logs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-flow-logs-role"
    Type = "Security"
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.organization_name}-${var.environment}-flow-logs-"
  role        = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "vpc" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-vpc-flow-logs"
    Type = "Monitoring"
  })
}

# S3 Bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket        = "${var.organization_name}-${var.environment}-cloudtrail-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-cloudtrail-bucket"
    Type = "Monitoring"
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.landing_zone.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${var.organization_name}-${var.environment}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail[0].bucket
  s3_key_prefix  = "cloudtrail-logs"

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail[0].arn

  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  kms_key_id = aws_kms_key.landing_zone.arn

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = ["kms.amazonaws.com", "rdsdata.amazonaws.com"]

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-cloudtrail"
    Type = "Monitoring"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# IAM Role for CloudTrail
resource "aws_iam_role" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name_prefix = "${var.organization_name}-${var.environment}-cloudtrail-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-cloudtrail-role"
    Type = "Security"
  })
}

resource "aws_iam_role_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name_prefix = "${var.organization_name}-${var.environment}-cloudtrail-"
  role        = aws_iam_role.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}

# AWS Config Configuration Recorder
resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0

  name     = "${var.organization_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_config_delivery_channel.main]
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0

  name           = "${var.organization_name}-${var.environment}-config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config[0].bucket
}

# S3 Bucket for AWS Config
resource "aws_s3_bucket" "config" {
  count = var.enable_config ? 1 : 0

  bucket        = "${var.organization_name}-${var.environment}-config-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-config-bucket"
    Type = "Monitoring"
  })
}

resource "aws_s3_bucket_policy" "config" {
  count = var.enable_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config[0].arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config[0].arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# IAM Role for AWS Config
resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name_prefix = "${var.organization_name}-${var.environment}-config-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-config-role"
    Type = "Security"
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-guardduty"
    Type = "Security"
  })
}

# Security Hub
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0

  enable_default_standards = true

  control_finding_generator = "STANDARD_CONTROL"
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  count = var.enable_cloudwatch_alarms && length(var.sns_email_endpoints) > 0 ? 1 : 0

  name         = "${var.organization_name}-${var.environment}-alerts"
  display_name = "Landing Zone Alerts"

  kms_master_key_id = aws_kms_key.landing_zone.key_id

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-alerts-topic"
    Type = "Monitoring"
  })
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "email_alerts" {
  count = var.enable_cloudwatch_alarms && length(var.sns_email_endpoints) > 0 ? length(var.sns_email_endpoints) : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoints[count.index]
}

# CloudWatch Alarms - VPC
resource "aws_cloudwatch_metric_alarm" "high_nat_gateway_error_rate" {
  count = var.enable_cloudwatch_alarms && var.enable_nat_gateway ? local.az_count : 0

  alarm_name          = "${var.organization_name}-${var.environment}-nat-gateway-high-error-rate-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NATGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors NAT Gateway error rate"
  alarm_actions       = length(var.sns_email_endpoints) > 0 ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    NatGatewayId = aws_nat_gateway.main[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-nat-gateway-alarm-${count.index + 1}"
    Type = "Monitoring"
  })
}

# Budget Alert
resource "aws_budgets_budget" "monthly" {
  name         = "${var.organization_name}-${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKey"
    values = ["Environment"]
  }
  
  cost_filter {
    name   = "TagKey" 
    values = ["Organization"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.budget_threshold_percentage
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.sns_email_endpoints
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-budget"
    Type = "Cost Management"
  })
}