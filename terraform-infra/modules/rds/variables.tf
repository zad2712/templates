variable "create_db_instance" {
  type    = bool
  default = true
}

variable "create_db_subnet_group" {
  type    = bool
  default = true
}

variable "db_instance_identifier" {
  type    = string
  default = "default-db"
}

variable "db_subnet_group_name" {
  type    = string
  default = "default-db-subnet-group"
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "engine" {
  type    = string
  default = "mysql"
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "storage_type" {
  type    = string
  default = "gp2"
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "kms_key_id" {
  type    = string
  default = null
}

variable "db_name" {
  type    = string
  default = "defaultdb"
}

variable "username" {
  type    = string
  default = "admin"
}

variable "password" {
  type      = string
  sensitive = true
  default   = "changeme123!"
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "backup_window" {
  type    = string
  default = "03:00-04:00"
}

variable "maintenance_window" {
  type    = string
  default = "sun:04:00-sun:05:00"
}

variable "monitoring_interval" {
  type    = number
  default = 0
}

variable "monitoring_role_arn" {
  type    = string
  default = null
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
