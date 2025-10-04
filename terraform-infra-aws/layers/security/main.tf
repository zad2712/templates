# =============================================================================
# SECURITY LAYER - IAM, KMS, Security Groups, and Security Services
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

# Configure AWS Provider
provider "aws" {
  # Provider configuration will be set by environment-specific backend configuration
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Layer       = "security"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Data from networking layer
  networking_outputs = data.terraform_remote_state.networking.outputs
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Current AWS region and account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Networking layer outputs
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}"
    key    = "networking/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

# =============================================================================
# IAM MODULE
# =============================================================================

module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix

  # IAM Roles for various AWS services
  roles = {
    # ECS Task Execution Role
    ecs_task_execution = {
      description = "ECS Task Execution Role"
      assume_role_policy = {
        version = "2012-10-17"
        statements = [
          {
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["ecs-tasks.amazonaws.com"]
            }
            actions = ["sts:AssumeRole"]
          }
        ]
      }
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      ]
      
      inline_policies = {
        secrets_access = {
          version = "2012-10-17"
          statements = [
            {
              effect = "Allow"
              actions = [
                "secretsmanager:GetSecretValue",
                "kms:Decrypt"
              ]
              resources = ["*"]
            }
          ]
        }
      }
    }

    # ECS Task Role
    ecs_task = {
      description = "ECS Task Role"
      assume_role_policy = {
        version = "2012-10-17"
        statements = [
          {
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["ecs-tasks.amazonaws.com"]
            }
            actions = ["sts:AssumeRole"]
          }
        ]
      }
      
      inline_policies = {
        application_permissions = {
          version = "2012-10-17"
          statements = [
            {
              effect = "Allow"
              actions = [
                "s3:GetObject",
                "s3:PutObject",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query",
                "dynamodb:Scan"
              ]
              resources = ["*"]
            }
          ]
        }
      }
    }

    # EKS Cluster Role
    eks_cluster = {
      description = "EKS Cluster Service Role"
      assume_role_policy = {
        version = "2012-10-17"
        statements = [
          {
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["eks.amazonaws.com"]
            }
            actions = ["sts:AssumeRole"]
          }
        ]
      }
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
    }

    # EKS Node Group Role
    eks_node_group = {
      description = "EKS Node Group Role"
      assume_role_policy = {
        version = "2012-10-17"
        statements = [
          {
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["ec2.amazonaws.com"]
            }
            actions = ["sts:AssumeRole"]
          }
        ]
      }
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
    }

    # Lambda Execution Role
    lambda_execution = {
      description = "Lambda Execution Role"
      assume_role_policy = {
        version = "2012-10-17"
        statements = [
          {
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["lambda.amazonaws.com"]
            }
            actions = ["sts:AssumeRole"]
          }
        ]
      }
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
      ]
      
      inline_policies = {
        lambda_permissions = {
          version = "2012-10-17"
          statements = [
            {
              effect = "Allow"
              actions = [
                "dynamodb:*",
                "s3:*",
                "secretsmanager:GetSecretValue",
                "kms:Decrypt"
              ]
              resources = ["*"]
            }
          ]
        }
      }
    }

    # RDS Enhanced Monitoring Role
    rds_monitoring = {
      description = "RDS Enhanced Monitoring Role"
      assume_role_policy = {
        version = "2012-10-17"
        statements = [
          {
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["monitoring.rds.amazonaws.com"]
            }
            actions = ["sts:AssumeRole"]
          }
        ]
      }
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
      ]
    }

    # API Gateway CloudWatch Role
    api_gateway_cloudwatch = {
      description = "API Gateway CloudWatch Role"
      assume_role_policy = {
        version = "2012-10-17"
        statements = [
          {
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["apigateway.amazonaws.com"]
            }
            actions = ["sts:AssumeRole"]
          }
        ]
      }
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
      ]
    }
  }

  # IAM Groups
  groups = var.iam_groups

  # IAM Users
  users = var.iam_users

  # Custom IAM Policies
  policies = var.custom_iam_policies

  tags = local.common_tags
}

# =============================================================================
# KMS MODULE
# =============================================================================

module "kms" {
  source = "../../modules/kms"

  name_prefix = local.name_prefix

  # KMS Keys for different services
  keys = {
    # General application encryption key
    application = {
      description             = "General application encryption key"
      deletion_window_in_days = var.kms_deletion_window
      enable_key_rotation     = true
      
      key_policy = {
        version = "2012-10-17"
        statements = [
          {
            sid    = "Enable IAM User Permissions"
            effect = "Allow"
            principals = {
              type        = "AWS"
              identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
            }
            actions   = ["kms:*"]
            resources = ["*"]
          },
          {
            sid    = "Allow ECS Tasks"
            effect = "Allow"
            principals = {
              type        = "AWS"
              identifiers = [module.iam.role_arns["ecs_task"], module.iam.role_arns["ecs_task_execution"]]
            }
            actions = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            resources = ["*"]
          }
        ]
      }
    }

    # RDS encryption key
    rds = {
      description             = "RDS database encryption key"
      deletion_window_in_days = var.kms_deletion_window
      enable_key_rotation     = true
      
      key_policy = {
        version = "2012-10-17"
        statements = [
          {
            sid    = "Enable IAM User Permissions"
            effect = "Allow"
            principals = {
              type        = "AWS"
              identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
            }
            actions   = ["kms:*"]
            resources = ["*"]
          },
          {
            sid    = "Allow RDS Service"
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["rds.amazonaws.com"]
            }
            actions = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            resources = ["*"]
          }
        ]
      }
    }

    # S3 encryption key
    s3 = {
      description             = "S3 bucket encryption key"
      deletion_window_in_days = var.kms_deletion_window
      enable_key_rotation     = true
      
      key_policy = {
        version = "2012-10-17"
        statements = [
          {
            sid    = "Enable IAM User Permissions"
            effect = "Allow"
            principals = {
              type        = "AWS"
              identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
            }
            actions   = ["kms:*"]
            resources = ["*"]
          },
          {
            sid    = "Allow S3 Service"
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["s3.amazonaws.com"]
            }
            actions = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            resources = ["*"]
          }
        ]
      }
    }

    # Lambda encryption key
    lambda = {
      description             = "Lambda function encryption key"
      deletion_window_in_days = var.kms_deletion_window
      enable_key_rotation     = true
      
      key_policy = {
        version = "2012-10-17"
        statements = [
          {
            sid    = "Enable IAM User Permissions"
            effect = "Allow"
            principals = {
              type        = "AWS"
              identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
            }
            actions   = ["kms:*"]
            resources = ["*"]
          },
          {
            sid    = "Allow Lambda Service"
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["lambda.amazonaws.com"]
            }
            actions = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            resources = ["*"]
          }
        ]
      }
    }

    # Secrets Manager encryption key
    secrets = {
      description             = "Secrets Manager encryption key"
      deletion_window_in_days = var.kms_deletion_window
      enable_key_rotation     = true
      
      key_policy = {
        version = "2012-10-17"
        statements = [
          {
            sid    = "Enable IAM User Permissions"
            effect = "Allow"
            principals = {
              type        = "AWS"
              identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
            }
            actions   = ["kms:*"]
            resources = ["*"]
          },
          {
            sid    = "Allow Secrets Manager Service"
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["secretsmanager.amazonaws.com"]
            }
            actions = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            resources = ["*"]
          }
        ]
      }
    }

    # CloudWatch Logs encryption key
    logs = {
      description             = "CloudWatch Logs encryption key"
      deletion_window_in_days = var.kms_deletion_window
      enable_key_rotation     = true
      
      key_policy = {
        version = "2012-10-17"
        statements = [
          {
            sid    = "Enable IAM User Permissions"
            effect = "Allow"
            principals = {
              type        = "AWS"
              identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
            }
            actions   = ["kms:*"]
            resources = ["*"]
          },
          {
            sid    = "Allow CloudWatch Logs"
            effect = "Allow"
            principals = {
              type        = "Service"
              identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
            }
            actions = [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ]
            resources = ["*"]
          }
        ]
      }
    }
  }

  # Key aliases
  aliases = {
    application = "alias/${local.name_prefix}-application"
    rds         = "alias/${local.name_prefix}-rds"
    s3          = "alias/${local.name_prefix}-s3"
    lambda      = "alias/${local.name_prefix}-lambda"
    secrets     = "alias/${local.name_prefix}-secrets"
    logs        = "alias/${local.name_prefix}-logs"
  }

  tags = local.common_tags
}

# =============================================================================
# SECRETS MANAGER MODULE
# =============================================================================

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  name_prefix = local.name_prefix

  # Database secrets
  secrets = {
    rds_master_password = {
      description = "RDS master password"
      kms_key_id  = module.kms.key_ids["secrets"]
      
      generate_secret_string = {
        length  = 32
        exclude_characters = "\"@/\\"
        exclude_numbers    = false
        exclude_punctuation = false
        exclude_uppercase   = false
        exclude_lowercase   = false
        include_space      = false
        require_each_included_type = true
      }
      
      replica_regions = var.enable_cross_region_backup ? [
        {
          region     = var.backup_region
          kms_key_id = "alias/aws/secretsmanager"
        }
      ] : []
    }

    # Application API keys
    api_keys = {
      description = "External API keys and tokens"
      kms_key_id  = module.kms.key_ids["secrets"]
      
      secret_string = jsonencode({
        github_token = "placeholder-token"
        stripe_key   = "placeholder-key"
      })
    }

    # JWT signing keys
    jwt_keys = {
      description = "JWT signing keys"
      kms_key_id  = module.kms.key_ids["secrets"]
      
      generate_secret_string = {
        length = 64
        exclude_characters = "\"@/\\ "
        exclude_numbers    = false
        exclude_punctuation = false
        include_space      = false
      }
    }
  }

  # Automatic rotation configuration
  rotation_rules = var.enable_secret_rotation ? {
    rds_master_password = {
      automatically_after_days = 30
    }
    
    jwt_keys = {
      automatically_after_days = 90
    }
  } : {}

  tags = local.common_tags
}

# =============================================================================
# WAF MODULE
# =============================================================================

module "waf" {
  count = var.enable_waf ? 1 : 0
  
  source = "../../modules/waf"

  name_prefix = local.name_prefix
  scope       = "REGIONAL"  # For ALB, API Gateway

  # Web ACL configuration
  web_acls = {
    application = {
      description = "WAF for application load balancer"
      
      default_action = {
        type = "ALLOW"
      }
      
      rules = [
        {
          name     = "AWS-AWSManagedRulesCommonRuleSet"
          priority = 1
          
          override_action = {
            type = "NONE"
          }
          
          managed_rule_group_statement = {
            name        = "AWSManagedRulesCommonRuleSet"
            vendor_name = "AWS"
          }
          
          visibility_config = {
            sampled_requests_enabled   = true
            cloudwatch_metrics_enabled = true
            metric_name               = "CommonRuleSet"
          }
        },
        
        {
          name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
          priority = 2
          
          override_action = {
            type = "NONE"
          }
          
          managed_rule_group_statement = {
            name        = "AWSManagedRulesKnownBadInputsRuleSet"
            vendor_name = "AWS"
          }
          
          visibility_config = {
            sampled_requests_enabled   = true
            cloudwatch_metrics_enabled = true
            metric_name               = "KnownBadInputsRuleSet"
          }
        },
        
        {
          name     = "RateLimitRule"
          priority = 3
          
          action = {
            type = "BLOCK"
          }
          
          rate_based_statement = {
            limit              = 2000
            aggregate_key_type = "IP"
          }
          
          visibility_config = {
            sampled_requests_enabled   = true
            cloudwatch_metrics_enabled = true
            metric_name               = "RateLimitRule"
          }
        }
      ]
      
      visibility_config = {
        sampled_requests_enabled   = true
        cloudwatch_metrics_enabled = true
        metric_name               = "ApplicationWebACL"
      }
    }
  }

  tags = local.common_tags
}

# =============================================================================
# CLOUDWATCH LOG GROUPS
# =============================================================================

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/application/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = module.kms.key_arns["logs"]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-application-logs"
  })
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = module.kms.key_arns["logs"]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-logs"
  })
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = module.kms.key_arns["logs"]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-logs"
  })
}

# =============================================================================
# SNS TOPICS FOR NOTIFICATIONS
# =============================================================================

resource "aws_sns_topic" "alerts" {
  name              = "${local.name_prefix}-alerts"
  kms_master_key_id = module.kms.key_ids["application"]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alerts"
  })
}

resource "aws_sns_topic_policy" "alerts_policy" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "alerts-topic-policy"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}