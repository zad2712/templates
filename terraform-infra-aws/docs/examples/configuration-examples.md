# Configuration Examples

This document provides comprehensive examples of different configuration scenarios and use cases for the AWS infrastructure. These examples demonstrate best practices for various deployment patterns and requirements.

## Table of Contents

- [Single Environment Setup](#single-environment-setup)
- [Multi-Environment Pipeline](#multi-environment-pipeline)
- [High Availability Configuration](#high-availability-configuration)
- [Development Environment](#development-environment)
- [Production Environment](#production-environment)
- [DR/Multi-Region Setup](#drmulti-region-setup)
- [Microservices Architecture](#microservices-architecture)
- [Monolithic Application](#monolithic-application)
- [Cost-Optimized Setup](#cost-optimized-setup)
- [Compliance-Ready Configuration](#compliance-ready-configuration)

## Single Environment Setup

### Basic Production Environment

This example shows a minimal production setup suitable for small to medium applications.

**Directory Structure:**
```
terraform-infra-aws/
├── main.tf
├── variables.tf
├── terraform.tfvars
└── outputs.tf
```

**terraform.tfvars:**
```hcl
# Basic Production Environment Configuration
project_name = "myapp"
environment  = "prod"
aws_region   = "us-east-1"

# Networking Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# Database Configuration
database_config = {
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.medium"
  allocated_storage = 100
  backup_retention = 7
  multi_az = true
}

# Compute Configuration
ecs_config = {
  cluster_name = "myapp-prod"
  services = {
    api = {
      desired_count = 3
      cpu          = 512
      memory       = 1024
      port         = 8080
    }
    web = {
      desired_count = 2
      cpu          = 256
      memory       = 512
      port         = 80
    }
  }
}

# Load Balancer Configuration
load_balancer_config = {
  type               = "application"
  internal           = false
  deletion_protection = true
  ssl_certificate_arn = null  # Will be created automatically
}

# Security Configuration
security_config = {
  enable_waf = true
  enable_guardduty = true
  enable_config = true
  enable_cloudtrail = true
}

# Monitoring Configuration
monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days = 30
  create_dashboards = true
}

# Backup Configuration
backup_config = {
  enable_automated_backups = true
  backup_retention_days = 30
  cross_region_backup = false
}

# Tags
tags = {
  Project     = "myapp"
  Environment = "prod"
  Owner       = "platform-team"
  CostCenter  = "engineering"
}
```

**main.tf:**
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    # Configure with backend.conf file
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

# Local values for computed configurations
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# Networking Layer
module "vpc" {
  source = "./layers/networking"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  
  tags = local.common_tags
}

# Security Layer
module "security" {
  source = "./layers/security"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id = module.vpc.vpc_id
  
  security_config = var.security_config
  
  tags = local.common_tags
}

# Data Layer
module "data" {
  source = "./layers/data"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id                    = module.vpc.vpc_id
  database_subnet_group_name = module.vpc.database_subnet_group_name
  database_security_groups   = [module.security.database_security_group_id]
  
  database_config = var.database_config
  backup_config   = var.backup_config
  
  kms_key_id = module.security.database_kms_key_id
  
  tags = local.common_tags
}

# Compute Layer
module "compute" {
  source = "./layers/compute"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  public_subnet_ids     = module.vpc.public_subnet_ids
  application_security_groups = [module.security.application_security_group_id]
  
  ecs_config           = var.ecs_config
  load_balancer_config = var.load_balancer_config
  monitoring_config    = var.monitoring_config
  
  database_endpoint = module.data.database_endpoint
  
  tags = local.common_tags
  
  depends_on = [module.vpc, module.security, module.data]
}
```

## Multi-Environment Pipeline

### Environment-Specific Configurations

This example demonstrates how to configure multiple environments with shared and environment-specific settings.

**Workspace Structure:**
```
terraform-infra-aws/
├── environments/
│   ├── dev/
│   │   ├── backend.conf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── backend.conf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── backend.conf
│       └── terraform.tfvars
├── shared/
│   └── variables.tf
└── main.tf
```

**environments/dev/terraform.tfvars:**
```hcl
# Development Environment Configuration
project_name = "myapp"
environment  = "dev"
aws_region   = "us-east-1"

# Smaller infrastructure for development
vpc_cidr = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24"]
database_subnet_cidrs = ["10.1.21.0/24", "10.1.22.0/24"]

# Cost-optimized database
database_config = {
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  backup_retention = 1
  multi_az = false
  skip_final_snapshot = true
}

# Minimal compute resources
ecs_config = {
  cluster_name = "myapp-dev"
  services = {
    api = {
      desired_count = 1
      cpu          = 256
      memory       = 512
      port         = 8080
    }
  }
}

# Basic security for development
security_config = {
  enable_waf = false
  enable_guardduty = false
  enable_config = false
  enable_cloudtrail = true
}

# Basic monitoring
monitoring_config = {
  enable_detailed_monitoring = false
  log_retention_days = 7
  create_dashboards = false
}

# No backup for dev environment
backup_config = {
  enable_automated_backups = false
  backup_retention_days = 0
  cross_region_backup = false
}
```

**environments/staging/terraform.tfvars:**
```hcl
# Staging Environment Configuration
project_name = "myapp"
environment  = "staging"
aws_region   = "us-east-1"

# Production-like but smaller
vpc_cidr = "10.2.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs   = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs  = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
database_subnet_cidrs = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]

# Mid-tier database configuration
database_config = {
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.small"
  allocated_storage = 50
  backup_retention = 3
  multi_az = true
  skip_final_snapshot = false
}

# Moderate compute resources
ecs_config = {
  cluster_name = "myapp-staging"
  services = {
    api = {
      desired_count = 2
      cpu          = 512
      memory       = 1024
      port         = 8080
    }
    web = {
      desired_count = 1
      cpu          = 256
      memory       = 512
      port         = 80
    }
  }
}

# Enhanced security for staging
security_config = {
  enable_waf = true
  enable_guardduty = true
  enable_config = true
  enable_cloudtrail = true
}

# Standard monitoring
monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days = 14
  create_dashboards = true
}

# Short-term backup for staging
backup_config = {
  enable_automated_backups = true
  backup_retention_days = 7
  cross_region_backup = false
}
```

**environments/prod/terraform.tfvars:**
```hcl
# Production Environment Configuration
project_name = "myapp"
environment  = "prod"
aws_region   = "us-east-1"

# Full production networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# Production-grade database
database_config = {
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.r5.large"
  allocated_storage = 500
  backup_retention = 30
  multi_az = true
  skip_final_snapshot = false
  performance_insights = true
}

# Production compute resources
ecs_config = {
  cluster_name = "myapp-prod"
  services = {
    api = {
      desired_count = 5
      cpu          = 1024
      memory       = 2048
      port         = 8080
      auto_scaling = {
        min_capacity = 3
        max_capacity = 20
        target_cpu   = 70
      }
    }
    web = {
      desired_count = 3
      cpu          = 512
      memory       = 1024
      port         = 80
      auto_scaling = {
        min_capacity = 2
        max_capacity = 10
        target_cpu   = 60
      }
    }
  }
}

# Full security suite
security_config = {
  enable_waf = true
  enable_guardduty = true
  enable_config = true
  enable_cloudtrail = true
  enable_security_hub = true
  enable_inspector = true
}

# Comprehensive monitoring
monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days = 90
  create_dashboards = true
  enable_xray = true
}

# Enterprise backup configuration
backup_config = {
  enable_automated_backups = true
  backup_retention_days = 90
  cross_region_backup = true
  backup_schedule = "cron(0 2 * * ? *)"
}
```

## High Availability Configuration

### Multi-AZ Production Setup

This configuration ensures maximum availability and resilience.

**terraform.tfvars:**
```hcl
# High Availability Production Configuration
project_name = "enterprise-app"
environment  = "prod"
aws_region   = "us-east-1"

# Multi-AZ networking across 3 zones
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Subnets distributed across all AZs
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# High availability database cluster
database_config = {
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.02.0"
  instance_class = "db.r6g.xlarge"
  
  cluster_config = {
    database_name   = "enterprise_app"
    master_username = "admin"
    backup_retention_period = 35
    preferred_backup_window = "03:00-04:00"
    preferred_maintenance_window = "Sun:04:00-Sun:05:00"
    deletion_protection = true
  }
  
  instances = {
    primary = {
      instance_class = "db.r6g.xlarge"
      availability_zone = "us-east-1a"
    }
    replica_1 = {
      instance_class = "db.r6g.xlarge"
      availability_zone = "us-east-1b"
    }
    replica_2 = {
      instance_class = "db.r6g.large"
      availability_zone = "us-east-1c"
    }
  }
  
  # Performance and monitoring
  performance_insights_enabled = true
  monitoring_interval = 60
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

# Auto-scaling ECS configuration
ecs_config = {
  cluster_name = "enterprise-prod"
  
  services = {
    api = {
      desired_count = 6
      cpu          = 2048
      memory       = 4096
      port         = 8080
      
      # Advanced auto-scaling
      auto_scaling = {
        min_capacity = 3
        max_capacity = 50
        target_cpu   = 70
        target_memory = 80
        scale_out_cooldown = 300
        scale_in_cooldown = 300
      }
      
      # Health checks
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval           = 30
        matcher            = "200"
        path               = "/health"
        port               = "traffic-port"
        protocol           = "HTTP"
        timeout            = 5
        unhealthy_threshold = 2
      }
    }
    
    web = {
      desired_count = 4
      cpu          = 1024
      memory       = 2048
      port         = 80
      
      auto_scaling = {
        min_capacity = 2
        max_capacity = 20
        target_cpu   = 60
        target_memory = 70
      }
    }
    
    worker = {
      desired_count = 3
      cpu          = 1024
      memory       = 2048
      
      auto_scaling = {
        min_capacity = 2
        max_capacity = 15
        target_cpu   = 80
      }
    }
  }
}

# Redundant load balancer configuration
load_balancer_config = {
  type = "application"
  internal = false
  deletion_protection = true
  
  # Multi-AZ deployment
  subnets = "public_subnets"  # Will use all public subnets
  
  # SSL/TLS configuration
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = null  # Will be created automatically
  
  # Access logging
  access_logs = {
    enabled = true
    bucket_prefix = "alb-access-logs"
  }
}

# Comprehensive caching strategy
cache_config = {
  redis = {
    node_type = "cache.r6g.large"
    num_cache_nodes = 3
    parameter_group_name = "default.redis7"
    port = 6379
    
    # Multi-AZ configuration
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    
    # Backup configuration
    snapshot_retention_limit = 7
    snapshot_window = "03:00-05:00"
    maintenance_window = "sun:05:00-sun:07:00"
  }
}

# Advanced security configuration
security_config = {
  enable_waf = true
  enable_guardduty = true
  enable_config = true
  enable_cloudtrail = true
  enable_security_hub = true
  enable_inspector = true
  
  # WAF configuration
  waf_config = {
    enable_managed_rules = true
    rate_limit = 10000
    geo_blocking = ["CN", "RU"]  # Block specific countries
    ip_whitelist = []  # Add trusted IP ranges
  }
  
  # Network security
  network_security = {
    enable_flow_logs = true
    enable_nacls = true
    enable_vpc_endpoints = true
  }
}

# Comprehensive monitoring and alerting
monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days = 180
  create_dashboards = true
  enable_xray = true
  
  # CloudWatch alarms
  alarms = {
    high_cpu = {
      threshold = 80
      evaluation_periods = 2
      period = 300
    }
    high_memory = {
      threshold = 85
      evaluation_periods = 2
      period = 300
    }
    database_connections = {
      threshold = 80  # 80% of max connections
      evaluation_periods = 1
      period = 60
    }
  }
  
  # SNS notifications
  notification_endpoints = [
    "arn:aws:sns:us-east-1:123456789012:critical-alerts",
    "arn:aws:sns:us-east-1:123456789012:warning-alerts"
  ]
}

# Enterprise backup strategy
backup_config = {
  enable_automated_backups = true
  backup_retention_days = 90
  cross_region_backup = true
  backup_schedule = "cron(0 2 * * ? *)"
  
  # Point-in-time recovery
  enable_pitr = true
  pitr_window = 35
  
  # Backup vault configuration
  backup_vault = {
    name = "enterprise-backup-vault"
    kms_key_arn = null  # Will use default key
  }
}

# Resource tagging strategy
tags = {
  Project      = "enterprise-app"
  Environment  = "prod"
  Owner        = "platform-team"
  CostCenter   = "engineering"
  BusinessUnit = "technology"
  Compliance   = "SOC2"
  Backup       = "required"
  Monitoring   = "critical"
}
```

## Development Environment

### Cost-Optimized Development Setup

This configuration minimizes costs while providing a functional development environment.

**terraform.tfvars:**
```hcl
# Development Environment - Cost Optimized
project_name = "myapp"
environment  = "dev"
aws_region   = "us-east-1"

# Minimal networking - single AZ for cost savings
vpc_cidr = "10.1.0.0/16"
availability_zones = ["us-east-1a"]

public_subnet_cidrs   = ["10.1.1.0/24"]
private_subnet_cidrs  = ["10.1.11.0/24"]
database_subnet_cidrs = ["10.1.21.0/24", "10.1.22.0/24"]  # RDS requires 2+ subnets

# Minimal database configuration
database_config = {
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  backup_retention = 0  # No backups in dev
  multi_az = false
  skip_final_snapshot = true
  
  # Development-specific settings
  deletion_protection = false
  apply_immediately = true
  auto_minor_version_upgrade = false
}

# Single container setup
ecs_config = {
  cluster_name = "myapp-dev"
  
  services = {
    all_in_one = {
      desired_count = 1
      cpu          = 512
      memory       = 1024
      port         = 8080
      
      # No auto-scaling in development
      auto_scaling = {
        enabled = false
      }
      
      # Relaxed health checks
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval           = 60
        matcher            = "200"
        path               = "/health"
        timeout            = 30
        unhealthy_threshold = 5
      }
    }
  }
}

# Basic load balancer
load_balancer_config = {
  type = "application"
  internal = false
  deletion_protection = false  # Allow easy deletion in dev
  
  # No SSL in development
  ssl_certificate_arn = null
  
  # Minimal access logging
  access_logs = {
    enabled = false
  }
}

# No caching in development
cache_config = {
  enabled = false
}

# Minimal security for development
security_config = {
  enable_waf = false
  enable_guardduty = false
  enable_config = false
  enable_cloudtrail = true  # Keep basic auditing
  enable_security_hub = false
  enable_inspector = false
  
  # Relaxed network security
  network_security = {
    enable_flow_logs = false
    enable_nacls = false
    enable_vpc_endpoints = false
  }
}

# Basic monitoring
monitoring_config = {
  enable_detailed_monitoring = false
  log_retention_days = 3  # Short retention to save costs
  create_dashboards = false
  enable_xray = false
  
  # Minimal alerting
  alarms = {
    high_cpu = {
      threshold = 90  # Higher threshold to avoid noise
      evaluation_periods = 3
      period = 300
    }
  }
}

# No backup in development
backup_config = {
  enable_automated_backups = false
  backup_retention_days = 0
  cross_region_backup = false
}

# Development tags
tags = {
  Project     = "myapp"
  Environment = "dev"
  Owner       = "dev-team"
  CostCenter  = "engineering"
  AutoShutdown = "true"  # Tag for automated shutdown scripts
}
```

## DR/Multi-Region Setup

### Disaster Recovery Configuration

This example shows how to configure disaster recovery across multiple regions.

**Primary Region (us-east-1):**
```hcl
# Primary Region Configuration - us-east-1
project_name = "enterprise-app"
environment  = "prod"
aws_region   = "us-east-1"

# Primary region networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# Primary database with cross-region replication
database_config = {
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.02.0"
  instance_class = "db.r6g.xlarge"
  
  cluster_config = {
    database_name   = "enterprise_app"
    backup_retention_period = 35
    deletion_protection = true
    
    # Cross-region backup
    backup_configuration = {
      source_region = "us-east-1"
      destination_region = "us-west-2"
    }
  }
  
  # Global database for DR
  global_cluster_config = {
    global_cluster_identifier = "enterprise-global-cluster"
    engine = "aurora-mysql"
    engine_version = "8.0.mysql_aurora.3.02.0"
    deletion_protection = true
  }
}

# Full production deployment
ecs_config = {
  cluster_name = "enterprise-prod-primary"
  
  services = {
    api = {
      desired_count = 6
      cpu          = 2048
      memory       = 4096
      
      # Aggressive auto-scaling for primary
      auto_scaling = {
        min_capacity = 3
        max_capacity = 50
        target_cpu   = 70
      }
    }
  }
}

# Cross-region replication for static assets
s3_config = {
  buckets = {
    assets = {
      versioning = true
      replication = {
        enabled = true
        destination_bucket = "enterprise-app-assets-dr"
        destination_region = "us-west-2"
        storage_class = "STANDARD_IA"
      }
    }
    
    backups = {
      versioning = true
      replication = {
        enabled = true
        destination_bucket = "enterprise-app-backups-dr"
        destination_region = "us-west-2"
        storage_class = "GLACIER"
      }
    }
  }
}

# Route 53 health checks for automatic failover
dns_config = {
  domain_name = "app.example.com"
  
  # Primary endpoint
  primary_endpoint = {
    region = "us-east-1"
    health_check = {
      enabled = true
      path = "/health"
      interval = 30
    }
  }
  
  # DR endpoint
  dr_endpoint = {
    region = "us-west-2"
    health_check = {
      enabled = true
      path = "/health"
      interval = 30
    }
  }
  
  # Failover routing
  failover_config = {
    primary_region = "us-east-1"
    secondary_region = "us-west-2"
    health_check_grace_period = 60
  }
}

# Comprehensive monitoring
monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days = 180
  create_dashboards = true
  
  # Cross-region monitoring
  cross_region_monitoring = {
    enabled = true
    dr_region = "us-west-2"
  }
}

# Primary region tags
tags = {
  Project      = "enterprise-app"
  Environment  = "prod"
  Region       = "primary"
  DREnabled    = "true"
  Owner        = "platform-team"
  CostCenter   = "engineering"
}
```

**DR Region (us-west-2):**
```hcl
# DR Region Configuration - us-west-2
project_name = "enterprise-app"
environment  = "prod-dr"
aws_region   = "us-west-2"

# DR region networking (different CIDR)
vpc_cidr = "10.1.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
database_subnet_cidrs = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

# DR database (read replica of global cluster)
database_config = {
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.02.0"
  instance_class = "db.r6g.large"  # Smaller instances in DR
  
  # Global cluster secondary region
  global_cluster_config = {
    global_cluster_identifier = "enterprise-global-cluster"
    source_region = "us-east-1"
    
    # Read-only cluster in DR region
    cluster_config = {
      database_name = "enterprise_app"
      backup_retention_period = 7  # Shorter retention in DR
    }
  }
}

# Minimal deployment in DR (scales up during failover)
ecs_config = {
  cluster_name = "enterprise-prod-dr"
  
  services = {
    api = {
      desired_count = 1  # Minimal running for faster activation
      cpu          = 2048
      memory       = 4096
      
      # Rapid scale-up capability
      auto_scaling = {
        min_capacity = 0   # Can scale to zero when not active
        max_capacity = 30  # Quick scale-up capability
        target_cpu   = 70
        
        # Faster scaling for DR activation
        scale_out_cooldown = 60
        scale_in_cooldown = 180
      }
    }
  }
}

# DR-specific configuration
dr_config = {
  activation_mode = "standby"  # standby, active, or manual
  
  # Automated failover triggers
  failover_triggers = {
    health_check_failures = 3
    rto_minutes = 15  # Recovery Time Objective
    rpo_minutes = 5   # Recovery Point Objective
  }
  
  # Data synchronization
  data_sync = {
    database_lag_threshold = 60  # seconds
    s3_sync_frequency = 300      # seconds
  }
}

# DR region tags
tags = {
  Project      = "enterprise-app"
  Environment  = "prod-dr"
  Region       = "secondary"
  DRRegion     = "true"
  Owner        = "platform-team"
  CostCenter   = "engineering"
}
```

## Microservices Architecture

### Service Mesh Configuration

This example shows how to configure infrastructure for a microservices architecture.

**terraform.tfvars:**
```hcl
# Microservices Architecture Configuration
project_name = "microservices-platform"
environment  = "prod"
aws_region   = "us-east-1"

# Large VPC to accommodate many services
vpc_cidr = "10.0.0.0/8"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Segmented subnets for different service tiers
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs    = ["10.0.11.0/20", "10.0.27.0/20", "10.0.43.0/20"]  # Larger subnets
database_subnet_cidrs   = ["10.0.60.0/24", "10.0.61.0/24", "10.0.62.0/24"]

# Multiple databases for different services
database_config = {
  # User service database
  user_service = {
    engine         = "postgres"
    engine_version = "15.4"
    instance_class = "db.r6g.large"
    allocated_storage = 200
    
    cluster_config = {
      database_name = "user_service"
      backup_retention_period = 30
    }
  }
  
  # Order service database
  order_service = {
    engine         = "mysql"
    engine_version = "8.0.35"
    instance_class = "db.r6g.xlarge"
    allocated_storage = 500
    
    cluster_config = {
      database_name = "order_service"
      backup_retention_period = 30
    }
  }
  
  # Analytics database
  analytics_service = {
    engine         = "postgres"
    engine_version = "15.4"
    instance_class = "db.r6g.2xlarge"
    allocated_storage = 1000
    
    cluster_config = {
      database_name = "analytics"
      backup_retention_period = 30
    }
  }
}

# EKS cluster for microservices
eks_config = {
  cluster_name = "microservices-cluster"
  cluster_version = "1.28"
  
  # Multiple node groups for different workloads
  node_groups = {
    # General purpose nodes
    general = {
      instance_types = ["m5.xlarge", "m5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      
      scaling_config = {
        desired_size = 6
        max_size     = 30
        min_size     = 3
      }
      
      taints = []
    }
    
    # Compute-intensive workloads
    compute = {
      instance_types = ["c5.2xlarge", "c5.4xlarge"]
      capacity_type  = "ON_DEMAND"
      
      scaling_config = {
        desired_size = 3
        max_size     = 15
        min_size     = 1
      }
      
      taints = [
        {
          key    = "workload-type"
          value  = "compute-intensive"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    
    # Spot instances for cost optimization
    spot = {
      instance_types = ["m5.large", "m5.xlarge", "m4.large", "m4.xlarge"]
      capacity_type  = "SPOT"
      
      scaling_config = {
        desired_size = 5
        max_size     = 20
        min_size     = 2
      }
      
      taints = [
        {
          key    = "instance-type"
          value  = "spot"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
  
  # Add-ons for microservices
  addons = {
    vpc_cni = {
      version = "v1.15.1-eksbuild.1"
    }
    coredns = {
      version = "v1.10.1-eksbuild.4"
    }
    kube_proxy = {
      version = "v1.28.2-eksbuild.2"
    }
    aws_ebs_csi_driver = {
      version = "v1.24.0-eksbuild.1"
    }
    aws_efs_csi_driver = {
      version = "v1.7.0-eksbuild.1"
    }
  }
}

# Service mesh configuration (Istio)
service_mesh_config = {
  enabled = true
  type = "istio"
  
  # Istio configuration
  istio_config = {
    version = "1.19.0"
    
    # Ingress gateway
    ingress_gateway = {
      enabled = true
      load_balancer_type = "nlb"
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
        "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      }
    }
    
    # Observability
    observability = {
      tracing = {
        enabled = true
        jaeger = {
          enabled = true
        }
      }
      metrics = {
        prometheus = {
          enabled = true
        }
      }
      logging = {
        enabled = true
      }
    }
    
    # Security policies
    security = {
      mtls = {
        mode = "STRICT"
      }
      authorization_policies = {
        enabled = true
        default_deny = true
      }
    }
  }
}

# API Gateway for external access
api_gateway_config = {
  type = "rest"  # REST API Gateway for fine-grained control
  
  # Multiple APIs for different service domains
  apis = {
    user_api = {
      name = "user-service-api"
      description = "User management API"
      
      # VPC Link to private services
      vpc_link = {
        target_arns = ["nlb_arn_placeholder"]
      }
    }
    
    order_api = {
      name = "order-service-api"
      description = "Order processing API"
      
      vpc_link = {
        target_arns = ["nlb_arn_placeholder"]
      }
    }
    
    public_api = {
      name = "public-api"
      description = "Public-facing API"
      
      # Rate limiting
      throttle = {
        rate_limit  = 10000
        burst_limit = 5000
      }
    }
  }
}

# Distributed caching
cache_config = {
  # Redis for session management
  session_cache = {
    engine = "redis"
    node_type = "cache.r6g.large"
    num_cache_clusters = 3
    
    # Cluster mode for high availability
    replication_group_config = {
      automatic_failover_enabled = true
      num_cache_clusters = 3
    }
  }
  
  # ElastiCache for application caching
  app_cache = {
    engine = "redis"
    node_type = "cache.r6g.xlarge"
    num_cache_clusters = 6
    
    replication_group_config = {
      automatic_failover_enabled = true
      num_cache_clusters = 6
    }
  }
}

# Message queues for async communication
messaging_config = {
  # SQS queues for different services
  sqs_queues = {
    order_processing = {
      name = "order-processing-queue"
      visibility_timeout_seconds = 300
      message_retention_seconds = 1209600  # 14 days
      
      # Dead letter queue
      dlq = {
        enabled = true
        max_receive_count = 3
      }
    }
    
    user_notifications = {
      name = "user-notifications-queue"
      visibility_timeout_seconds = 60
      message_retention_seconds = 345600  # 4 days
    }
    
    analytics_events = {
      name = "analytics-events-queue"
      visibility_timeout_seconds = 180
      message_retention_seconds = 1209600  # 14 days
      
      # FIFO queue for ordered events
      fifo_queue = true
      content_based_deduplication = true
    }
  }
  
  # SNS topics for pub/sub patterns
  sns_topics = {
    order_events = {
      name = "order-events"
      
      # Multiple subscribers
      subscriptions = [
        {
          protocol = "sqs"
          endpoint = "order-processing-queue"
        },
        {
          protocol = "sqs"
          endpoint = "analytics-events-queue"
        }
      ]
    }
  }
}

# Comprehensive monitoring for microservices
monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days = 90
  create_dashboards = true
  enable_xray = true
  
  # Service-specific monitoring
  service_monitoring = {
    # Application Performance Monitoring
    apm = {
      enabled = true
      sampling_rate = 0.1  # 10% sampling
    }
    
    # Distributed tracing
    tracing = {
      enabled = true
      trace_sampling = {
        reservoir_size = 1
        fixed_rate = 0.1
      }
    }
    
    # Custom metrics
    custom_metrics = {
      business_metrics = {
        namespace = "MicroservicesPlatform/Business"
        metrics = [
          "OrdersPerMinute",
          "UserRegistrations",
          "PaymentTransactions"
        ]
      }
    }
  }
  
  # Alerting strategy
  alerts = {
    service_health = {
      error_rate_threshold = 5  # 5% error rate
      latency_threshold = 2000  # 2 seconds
    }
    
    infrastructure = {
      cpu_threshold = 80
      memory_threshold = 85
      disk_threshold = 85
    }
  }
}

# Microservices-specific tags
tags = {
  Project      = "microservices-platform"
  Environment  = "prod"
  Architecture = "microservices"
  ServiceMesh  = "istio"
  Owner        = "platform-team"
  CostCenter   = "engineering"
}
```

This comprehensive configuration examples document provides detailed setups for various scenarios, from simple single environments to complex microservices architectures with disaster recovery. Each example includes specific configurations tailored to the use case, demonstrating best practices for different deployment patterns.