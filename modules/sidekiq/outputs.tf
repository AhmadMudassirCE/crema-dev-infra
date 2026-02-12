# Sidekiq Module Outputs

output "service_name" {
  description = "Name of the Sidekiq ECS service"
  value       = aws_ecs_service.sidekiq.name
}

output "service_id" {
  description = "ID of the Sidekiq ECS service"
  value       = aws_ecs_service.sidekiq.id
}

output "task_definition_arn" {
  description = "ARN of the Sidekiq task definition"
  value       = aws_ecs_task_definition.sidekiq.arn
}
