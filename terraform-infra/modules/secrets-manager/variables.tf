# Secrets Manager Module Variables
variable "name" {
  description = "Name of the secret"
  type        = string
  default     = "default-secret"
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = "Secret managed by Terraform"
}

variable "secret_string" {
  description = "Secret value as a string"
  type        = string
  default     = null
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}
