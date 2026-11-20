output "table_name" {
  description = "Global table name (same in both regions)."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "Table ARN in the primary region."
  value       = aws_dynamodb_table.this.arn
}

output "health_check_id" {
  description = "Route 53 health check on the primary endpoint."
  value       = aws_route53_health_check.primary.id
}

output "record_fqdn" {
  description = "The name clients use."
  value       = aws_route53_record.primary.fqdn
}
