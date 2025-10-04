# Variables for complete example

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "organization_name" {
  description = "Organization name"
  type        = string
  default     = "mycompany"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}