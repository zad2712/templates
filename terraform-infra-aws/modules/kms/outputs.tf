# =============================================================================
# KMS MODULE OUTPUTS
# =============================================================================

output "key_id" {
  description = "The globally unique identifier for the key"
  value       = aws_kms_key.main.key_id
}

output "key_arn" {
  description = "The Amazon Resource Name (ARN) of the key"
  value       = aws_kms_key.main.arn
}

output "alias_arn" {
  description = "The Amazon Resource Name (ARN) of the key alias"
  value       = var.create_alias ? aws_kms_alias.main[0].arn : null
}

output "alias_name" {
  description = "The display name of the alias"
  value       = var.create_alias ? aws_kms_alias.main[0].name : null
}
