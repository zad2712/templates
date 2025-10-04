variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow bucket deletion even if it contains objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if using aws:kms)"
  type        = string
  default     = null
}

variable "block_public_acls" {
  description = "Block public ACLs on this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs on this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
