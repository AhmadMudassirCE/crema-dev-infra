# Sidekiq Module Variables

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the Sidekiq service"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired number of Sidekiq tasks"
  type        = number
  default     = 1
}

variable "sidekiq_command" {
  description = "Command to run Sidekiq"
  type        = list(string)
  default     = ["bundle", "exec", "sidekiq"]
}

variable "secrets" {
  description = "Secrets from SSM Parameter Store"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "task_execution_role_arn" {
  description = "ARN of the task execution role (reuse from web service)"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role (reuse from web service)"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name (reuse from web service)"
  type        = string
}
