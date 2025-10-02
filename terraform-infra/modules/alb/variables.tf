# ALB Module Variables
variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "default-alb"
}

variable "load_balancer_type" {
  description = "Type of load balancer"
  type        = string
  default     = "application"
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
  default     = []
}

variable "security_groups" {
  description = "List of security group IDs to assign to the load balancer"
  type        = list(string)
  default     = []
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the load balancer"
  type        = map(string)
  default     = {}
}
