# RDS Module - Variables
# Author: Diego A. Zarate

# General Configuration
variable "name_prefix" {
  description = "Name prefix for RDS resources"
  type        = string
  default     = "app"

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "Name prefix must be between 1 and 32 characters."
  }
}

variable "tags" {
  description = "A map of tags to assign to RDS resources"
  type        = map(string)
  default     = {}
}

# DB Subnet Groups
variable "db_subnet_groups" {
  description = "Map of DB subnet groups to create"
  type = map(object({
    subnet_ids  = list(string)
    description = optional(string, "DB subnet group managed by Terraform")
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for group_name, group_config in var.db_subnet_groups :
      length(group_config.subnet_ids) >= 2
    ])
    error_message = "DB subnet groups must have at least 2 subnets for high availability."
  }
}

# DB Parameter Groups
variable "db_parameter_groups" {
  description = "Map of DB parameter groups to create"
  type = map(object({
    family      = string
    description = optional(string, "DB parameter group managed by Terraform")
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for group_name, group_config in var.db_parameter_groups :
      length(group_config.family) > 0
    ])
    error_message = "DB parameter group family must be specified."
  }

  validation {
    condition = alltrue([
      for group_name, group_config in var.db_parameter_groups :
      alltrue([
        for param in group_config.parameters :
        contains(["immediate", "pending-reboot"], param.apply_method)
      ])
    ])
    error_message = "Parameter apply_method must be either 'immediate' or 'pending-reboot'."
  }
}

# DB Option Groups
variable "db_option_groups" {
  description = "Map of DB option groups to create"
  type = map(object({
    engine_name          = string
    major_engine_version = string
    description          = optional(string, "DB option group managed by Terraform")
    options = optional(list(object({
      option_name                    = string
      port                          = optional(number, null)
      version                       = optional(string, null)
      db_security_group_memberships = optional(list(string), [])
      vpc_security_group_memberships = optional(list(string), [])
      option_settings = optional(list(object({
        name  = string
        value = string
      })), [])
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for group_name, group_config in var.db_option_groups :
      contains(["mysql", "oracle-ee", "oracle-se2", "oracle-se1", "oracle-se", "postgres", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"], group_config.engine_name)
    ])
    error_message = "Invalid engine name for DB option group."
  }
}

# RDS Cluster Parameter Groups (Aurora)
variable "rds_cluster_parameter_groups" {
  description = "Map of RDS cluster parameter groups to create"
  type = map(object({
    family      = string
    description = optional(string, "RDS cluster parameter group managed by Terraform")
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for group_name, group_config in var.rds_cluster_parameter_groups :
      length(group_config.family) > 0
    ])
    error_message = "RDS cluster parameter group family must be specified."
  }
}

# RDS Instances
variable "rds_instances" {
  description = "Map of RDS instances to create"
  type = map(object({
    # Basic Configuration
    allocated_storage     = number
    max_allocated_storage = optional(number, null)
    storage_type          = optional(string, "gp3")
    storage_encrypted     = optional(bool, true)
    kms_key_id           = optional(string, null)
    iops                 = optional(number, null)
    storage_throughput   = optional(number, null)

    # Engine Configuration
    engine         = string
    engine_version = optional(string, null)
    instance_class = string
    db_name       = optional(string, null)
    username      = optional(string, "admin")
    password      = optional(string, null)
    manage_master_user_password = optional(bool, true)

    # Network Configuration
    db_subnet_group_name   = optional(string, null)
    vpc_security_group_ids = optional(list(string), [])
    publicly_accessible    = optional(bool, false)
    port                   = optional(number, null)

    # High Availability
    multi_az          = optional(bool, false)
    availability_zone = optional(string, null)

    # Parameter and Option Groups
    parameter_group_name = optional(string, null)
    option_group_name    = optional(string, null)

    # Backup Configuration
    backup_retention_period = optional(number, 7)
    backup_window          = optional(string, "03:00-04:00")
    delete_automated_backups = optional(bool, true)
    copy_tags_to_snapshot   = optional(bool, true)
    final_snapshot_identifier = optional(string, null)
    skip_final_snapshot    = optional(bool, false)

    # Maintenance
    maintenance_window         = optional(string, "sun:04:00-sun:05:00")
    auto_minor_version_upgrade = optional(bool, true)
    allow_major_version_upgrade = optional(bool, false)

    # Monitoring
    monitoring_interval = optional(number, 0)
    monitoring_role_arn = optional(string, null)
    enabled_cloudwatch_logs_exports = optional(list(string), [])
    performance_insights_enabled = optional(bool, false)
    performance_insights_retention_period = optional(number, 7)

    # Security
    deletion_protection = optional(bool, true)
    
    # Lifecycle
    apply_immediately = optional(bool, false)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for instance_name, instance_config in var.rds_instances :
      contains(["mysql", "postgres", "oracle-ee", "oracle-se2", "oracle-se1", "oracle-se", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web", "mariadb"], instance_config.engine)
    ])
    error_message = "Invalid engine specified for RDS instance."
  }

  validation {
    condition = alltrue([
      for instance_name, instance_config in var.rds_instances :
      contains(["gp2", "gp3", "io1", "io2", "standard"], instance_config.storage_type)
    ])
    error_message = "Invalid storage type. Must be one of: gp2, gp3, io1, io2, standard."
  }

  validation {
    condition = alltrue([
      for instance_name, instance_config in var.rds_instances :
      instance_config.allocated_storage >= 20 && instance_config.allocated_storage <= 65536
    ])
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }

  validation {
    condition = alltrue([
      for instance_name, instance_config in var.rds_instances :
      instance_config.backup_retention_period >= 0 && instance_config.backup_retention_period <= 35
    ])
    error_message = "Backup retention period must be between 0 and 35 days."
  }

  validation {
    condition = alltrue([
      for instance_name, instance_config in var.rds_instances :
      instance_config.monitoring_interval == 0 || instance_config.monitoring_interval == 1 || instance_config.monitoring_interval == 5 || instance_config.monitoring_interval == 10 || instance_config.monitoring_interval == 15 || instance_config.monitoring_interval == 30 || instance_config.monitoring_interval == 60
    ])
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60 seconds."
  }
}

# RDS Clusters (Aurora)
variable "rds_clusters" {
  description = "Map of RDS clusters to create"
  type = map(object({
    # Basic Configuration
    engine                 = string
    engine_version         = optional(string, null)
    engine_mode           = optional(string, "provisioned")
    database_name         = optional(string, null)
    master_username       = optional(string, "admin")
    master_password       = optional(string, null)
    manage_master_user_password = optional(bool, true)

    # Network Configuration
    db_subnet_group_name   = optional(string, null)
    vpc_security_group_ids = optional(list(string), [])
    port                   = optional(number, null)
    availability_zones     = optional(list(string), [])

    # Parameter Group
    db_cluster_parameter_group_name = optional(string, null)

    # Backup Configuration
    backup_retention_period = optional(number, 7)
    preferred_backup_window = optional(string, "03:00-04:00")
    copy_tags_to_snapshot   = optional(bool, true)
    final_snapshot_identifier = optional(string, null)
    skip_final_snapshot    = optional(bool, false)

    # Maintenance
    preferred_maintenance_window = optional(string, "sun:04:00-sun:05:00")

    # Storage
    storage_encrypted = optional(bool, true)
    kms_key_id       = optional(string, null)
    storage_type     = optional(string, null)
    allocated_storage = optional(number, null)
    iops            = optional(number, null)

    # Monitoring
    enabled_cloudwatch_logs_exports = optional(list(string), [])

    # Security and Lifecycle
    deletion_protection = optional(bool, true)
    apply_immediately  = optional(bool, false)

    # Serverless Configuration
    scaling_configuration = optional(object({
      auto_pause               = optional(bool, true)
      max_capacity            = optional(number, 1)
      min_capacity            = optional(number, 1)
      seconds_until_auto_pause = optional(number, 300)
      timeout_action          = optional(string, "ForceApplyCapacityChange")
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.rds_clusters :
      contains(["aurora-mysql", "aurora-postgresql"], cluster_config.engine)
    ])
    error_message = "RDS Cluster engine must be either 'aurora-mysql' or 'aurora-postgresql'."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.rds_clusters :
      contains(["provisioned", "serverless", "parallelquery", "global"], cluster_config.engine_mode)
    ])
    error_message = "Engine mode must be one of: provisioned, serverless, parallelquery, global."
  }

  validation {
    condition = alltrue([
      for cluster_name, cluster_config in var.rds_clusters :
      cluster_config.backup_retention_period >= 1 && cluster_config.backup_retention_period <= 35
    ])
    error_message = "Backup retention period for clusters must be between 1 and 35 days."
  }
}

# RDS Cluster Instances
variable "rds_cluster_instances" {
  description = "Map of RDS cluster instances to create"
  type = map(object({
    cluster_identifier = string
    instance_class     = string
    engine            = optional(string, null)
    engine_version    = optional(string, null)

    # Monitoring
    monitoring_interval = optional(number, 0)
    monitoring_role_arn = optional(string, null)
    performance_insights_enabled = optional(bool, false)

    # Maintenance
    auto_minor_version_upgrade = optional(bool, true)
    preferred_maintenance_window = optional(string, null)

    # Security
    publicly_accessible = optional(bool, false)
    
    # Lifecycle
    apply_immediately = optional(bool, false)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for instance_name, instance_config in var.rds_cluster_instances :
      can(regex("^db\\.", instance_config.instance_class))
    ])
    error_message = "Instance class must be a valid RDS instance class (e.g., db.t3.micro)."
  }
}

# RDS Proxy
variable "rds_proxies" {
  description = "Map of RDS proxies to create"
  type = map(object({
    engine_family         = string
    auth                  = list(object({
      auth_scheme = optional(string, "SECRETS")
      secret_arn  = optional(string, null)
      iam_auth    = optional(string, "DISABLED")
      username    = optional(string, null)
    }))
    role_arn              = string
    vpc_subnet_ids        = list(string)
    vpc_security_group_ids = optional(list(string), [])

    require_tls = optional(bool, true)
    idle_client_timeout = optional(number, 1800)
    debug_logging      = optional(bool, false)

    connection_pool_config = optional(object({
      connection_borrow_timeout    = optional(number, 120)
      init_query                  = optional(string, null)
      max_connections_percent     = optional(number, 100)
      max_idle_connections_percent = optional(number, 50)
      session_pinning_filters     = optional(list(string), [])
    }), {})

    targets = list(object({
      db_instance_identifier = optional(string, null)
      db_cluster_identifier  = optional(string, null)
    }))

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for proxy_name, proxy_config in var.rds_proxies :
      contains(["MYSQL", "POSTGRESQL"], proxy_config.engine_family)
    ])
    error_message = "RDS Proxy engine family must be either 'MYSQL' or 'POSTGRESQL'."
  }

  validation {
    condition = alltrue([
      for proxy_name, proxy_config in var.rds_proxies :
      length(proxy_config.vpc_subnet_ids) >= 2
    ])
    error_message = "RDS Proxy must have at least 2 subnet IDs for high availability."
  }

  validation {
    condition = alltrue([
      for proxy_name, proxy_config in var.rds_proxies :
      alltrue([
        for auth in proxy_config.auth :
        contains(["SECRETS"], auth.auth_scheme)
      ])
    ])
    error_message = "RDS Proxy auth scheme must be 'SECRETS'."
  }

  validation {
    condition = alltrue([
      for proxy_name, proxy_config in var.rds_proxies :
      alltrue([
        for target in proxy_config.targets :
        (target.db_instance_identifier != null) != (target.db_cluster_identifier != null)
      ])
    ])
    error_message = "RDS Proxy target must specify either db_instance_identifier or db_cluster_identifier, but not both."
  }
}