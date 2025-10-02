variable "name" {
  description = "Name for the WAF Web ACL"
  type        = string
  default     = "default-waf-acl"
}

variable "scope" {
  description = "Scope of the WebACL (CLOUDFRONT or REGIONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "default_action" {
  description = "Default action for the WebACL (allow or block)"
  type        = string
  default     = "allow"
}

variable "rules" {
  description = "Map of WAF rules"
  type        = map(any)
  default     = {}
}

variable "cloudwatch_metrics_enabled" {
  description = "Enable CloudWatch metrics"
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Enable sampled requests"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
