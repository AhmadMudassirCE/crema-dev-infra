# Scheduled Tasks Module Outputs

output "task_definition_arn" {
  description = "ARN of the rake tasks task definition"
  value       = aws_ecs_task_definition.rake_tasks.arn
}

output "log_group_name" {
  description = "CloudWatch log group name for rake tasks"
  value       = aws_cloudwatch_log_group.rake_tasks.name
}

output "scheduler_role_arn" {
  description = "ARN of the EventBridge scheduler role"
  value       = aws_iam_role.scheduler.arn
}

output "scheduled_task_names" {
  description = "Names of created scheduled tasks"
  value       = [for task in var.scheduled_tasks : "${var.project_name}-${task.name}"]
}
