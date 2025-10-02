# ECS Module Variables
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "default-cluster"
}

variable "capacity_providers" {
  description = "List of short names of one or more capacity providers"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = map(string)
  default     = {}
}
