# Redis Module Outputs

output "redis_replication_group_id" {
  description = "ID of the Redis replication group"
  value       = aws_elasticache_replication_group.main.id
}

output "redis_primary_endpoint_address" {
  description = "Address of the primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint_address" {
  description = "Address of the reader endpoint (for read replicas)"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_port" {
  description = "Port number for Redis"
  value       = aws_elasticache_replication_group.main.port
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

output "redis_url_parameter_name" {
  description = "SSM Parameter name containing the Redis URL"
  value       = aws_ssm_parameter.redis_url.name
}

output "redis_url_parameter_arn" {
  description = "SSM Parameter ARN containing the Redis URL"
  value       = aws_ssm_parameter.redis_url.arn
}
