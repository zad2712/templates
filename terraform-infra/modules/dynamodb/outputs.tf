# DynamoDB Table Outputs

# Table Information
output "table_name" {
  description = "Name of the DynamoDB table"
  value       = try(aws_dynamodb_table.this[0].name, "")
}

output "table_id" {
  description = "Name of the DynamoDB table"
  value       = try(aws_dynamodb_table.this[0].id, "")
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = try(aws_dynamodb_table.this[0].arn, "")
}

output "table_stream_arn" {
  description = "The ARN of the Table Stream. Only available when var.stream_enabled is true"
  value       = try(aws_dynamodb_table.this[0].stream_arn, "")
}

output "table_stream_label" {
  description = "A timestamp, in ISO 8601 format of the Table Stream. Only available when var.stream_enabled is true"
  value       = try(aws_dynamodb_table.this[0].stream_label, "")
}

# Table Configuration
output "table_billing_mode" {
  description = "The billing mode of the table"
  value       = try(aws_dynamodb_table.this[0].billing_mode, "")
}

output "table_hash_key" {
  description = "The hash key of the table"
  value       = try(aws_dynamodb_table.this[0].hash_key, "")
}

output "table_range_key" {
  description = "The range key of the table"
  value       = try(aws_dynamodb_table.this[0].range_key, "")
}

output "table_read_capacity" {
  description = "The read capacity of the table"
  value       = try(aws_dynamodb_table.this[0].read_capacity, null)
}

output "table_write_capacity" {
  description = "The write capacity of the table"
  value       = try(aws_dynamodb_table.this[0].write_capacity, null)
}

# Global Secondary Indexes
output "table_global_secondary_index_names" {
  description = "The names of the global secondary indexes"
  value       = [for gsi in var.global_secondary_indexes : gsi.name]
}

output "table_local_secondary_index_names" {
  description = "The names of the local secondary indexes"
  value       = [for lsi in var.local_secondary_indexes : lsi.name]
}

# Auto Scaling
output "autoscaling_read_target_arn" {
  description = "The ARN of the read capacity autoscaling target"
  value       = try(aws_appautoscaling_target.read_target[0].arn, "")
}

output "autoscaling_write_target_arn" {
  description = "The ARN of the write capacity autoscaling target"
  value       = try(aws_appautoscaling_target.write_target[0].arn, "")
}

output "autoscaling_read_policy_arn" {
  description = "The ARN of the read capacity autoscaling policy"
  value       = try(aws_appautoscaling_policy.read_policy[0].arn, "")
}

output "autoscaling_write_policy_arn" {
  description = "The ARN of the write capacity autoscaling policy"
  value       = try(aws_appautoscaling_policy.write_policy[0].arn, "")
}

# CloudWatch
output "cloudwatch_alarms" {
  description = "Map of CloudWatch alarms created"
  value = {
    read_throttled_requests  = try(aws_cloudwatch_metric_alarm.read_throttled_requests[0].arn, "")
    write_throttled_requests = try(aws_cloudwatch_metric_alarm.write_throttled_requests[0].arn, "")
    consumed_read_capacity   = try(aws_cloudwatch_metric_alarm.consumed_read_capacity[0].arn, "")
    consumed_write_capacity  = try(aws_cloudwatch_metric_alarm.consumed_write_capacity[0].arn, "")
  }
}

# Kinesis Data Firehose
output "kinesis_firehose_delivery_stream_name" {
  description = "The name of the Kinesis Data Firehose delivery stream"
  value       = try(aws_kinesis_firehose_delivery_stream.dynamodb_stream[0].name, "")
}

output "kinesis_firehose_delivery_stream_arn" {
  description = "The ARN of the Kinesis Data Firehose delivery stream"
  value       = try(aws_kinesis_firehose_delivery_stream.dynamodb_stream[0].arn, "")
}

# Contributor Insights
output "contributor_insights_table_rule_name" {
  description = "The name of the contributor insights rule for the table"
  value       = try(aws_dynamodb_contributor_insights.this[0].rule_name, "")
}

output "contributor_insights_gsi_rule_names" {
  description = "The names of the contributor insights rules for GSIs"
  value       = { for k, v in aws_dynamodb_contributor_insights.gsi : k => v.rule_name }
}

# Table Tags
output "table_tags" {
  description = "A map of tags assigned to the table"
  value       = try(aws_dynamodb_table.this[0].tags_all, {})
}
