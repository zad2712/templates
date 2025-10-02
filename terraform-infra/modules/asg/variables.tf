# Auto Scaling Group Module Variables
variable "name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "default-asg"
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "vpc_zone_identifier" {
  description = "List of subnet IDs to launch resources in"
  type        = list(string)
  default     = []
}

variable "launch_template" {
  description = "Launch template configuration"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the Auto Scaling Group"
  type        = map(string)
  default     = {}
}
