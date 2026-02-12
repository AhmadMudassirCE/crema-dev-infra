# Scheduled Tasks Module Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "container_image" {
  description = "Docker image for rake tasks (same as main app)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for task execution"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for task execution"
  type        = string
}

variable "secrets" {
  description = "Secrets from SSM Parameter Store"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "task_cpu" {
  description = "CPU units for rake tasks"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for rake tasks in MB"
  type        = string
  default     = "512"
}

variable "scheduled_tasks" {
  description = "List of scheduled rake tasks to create"
  type = list(object({
    name                = string
    schedule_expression = string  # cron(0 9 * * ? *) or rate(1 hour)
    command             = list(string)  # ["bundle", "exec", "rake", "task:name"]
    enabled             = bool
  }))
  default = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
