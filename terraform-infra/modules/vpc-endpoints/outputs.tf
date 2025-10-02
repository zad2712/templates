# =============================================================================
# VPC ENDPOINTS MODULE OUTPUTS
# =============================================================================

output "vpc_endpoints" {
  description = "Map of VPC endpoints created"
  value = {
    for k, v in aws_vpc_endpoint.endpoints : k => {
      id           = v.id
      arn          = v.arn
      service_name = v.service_name
      state        = v.state
      dns_entry    = v.dns_entry
    }
  }
}

output "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs"
  value       = [for endpoint in aws_vpc_endpoint.endpoints : endpoint.id]
}

output "security_group_id" {
  description = "Security group ID for interface endpoints"
  value       = aws_security_group.vpc_endpoints.id
}
