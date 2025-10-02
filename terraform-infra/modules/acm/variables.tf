# ACM Certificate Module Variables
variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "List of domains that should be SANs in the issued certificate"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Method to use for validation"
  type        = string
  default     = "DNS"
}

variable "tags" {
  description = "Tags to apply to the certificate"
  type        = map(string)
  default     = {}
}
