# =============================================================================
# VPC ENDPOINTS MODULE VARIABLES
# =============================================================================

variable "vpc_id" {
  description = "ID of the VPC where endpoints will be created"
  type        = string
  default     = ""
}

variable "endpoints" {
  description = "List of VPC endpoints to create"
  type        = list(string)
  default     = ["s3", "dynamodb"]
  validation {
    condition = alltrue([
      for endpoint in var.endpoints : contains(["s3", "dynamodb", "ec2", "ssm", "ssmmessages", "ec2messages"], endpoint)
    ])
    error_message = "Endpoints must be one of: s3, dynamodb, ec2, ssm, ssmmessages, ec2messages."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for interface endpoints"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "List of route table IDs for gateway endpoints"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
