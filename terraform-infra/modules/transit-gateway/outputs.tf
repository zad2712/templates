# =============================================================================
# TRANSIT GATEWAY MODULE OUTPUTS
# =============================================================================

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_association_default_route_table_id" {
  description = "ID of the default association route table"
  value       = aws_ec2_transit_gateway.main.association_default_route_table_id
}

output "transit_gateway_propagation_default_route_table_id" {
  description = "ID of the default propagation route table"
  value       = aws_ec2_transit_gateway.main.propagation_default_route_table_id
}

output "transit_gateway_route_table_id" {
  description = "ID of the custom route table (if created)"
  value       = var.create_transit_gateway_route_table ? aws_ec2_transit_gateway_route_table.main[0].id : null
}

output "vpc_attachments" {
  description = "Map of VPC attachments created"
  value = {
    for k, v in aws_ec2_transit_gateway_vpc_attachment.vpc_attachments : k => {
      id     = v.id
      state  = v.state
      vpc_id = v.vpc_id
    }
  }
}

output "vpc_attachment_ids" {
  description = "List of VPC attachment IDs"
  value       = [for attachment in aws_ec2_transit_gateway_vpc_attachment.vpc_attachments : attachment.id]
}
