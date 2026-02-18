# ECS Module Variables

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy (ECR URL)"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 80

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory for the task in MB (512, 1024, 2048, etc.)"
  type        = string
  default     = "512"

  validation {
    condition     = can(regex("^(512|1024|2048|3072|4096|5120|6144|7168|8192|9216|10240|11264|12288|13312|14336|15360|16384|30720)$", var.task_memory))
    error_message = "Task memory must be a valid value. See AWS Fargate documentation for valid CPU/memory combinations."
  }
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be a non-negative integer."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "additional_task_policy_arns" {
  description = "Additional IAM policy ARNs to attach to task role"
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Environment variables for the container as key-value pairs"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Sensitive environment variables from AWS Secrets Manager or SSM Parameter Store (ARN format)"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}


# Auto-Scaling Configuration
variable "enable_autoscaling" {
  description = "Enable auto-scaling for the ECS service"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 4
}

variable "autoscaling_cpu_enabled" {
  description = "Enable CPU-based auto-scaling"
  type        = bool
  default     = true
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "autoscaling_memory_enabled" {
  description = "Enable memory-based auto-scaling"
  type        = bool
  default     = false
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "autoscaling_alb_requests_enabled" {
  description = "Enable ALB request count based auto-scaling"
  type        = bool
  default     = false
}

variable "autoscaling_alb_requests_target" {
  description = "Target number of requests per target for auto-scaling"
  type        = number
  default     = 1000
}

variable "autoscaling_scale_in_cooldown" {
  description = "Cooldown period (seconds) after scale-in activity"
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown" {
  description = "Cooldown period (seconds) after scale-out activity"
  type        = number
  default     = 60
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for ALB request count scaling)"
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group (for ALB request count scaling)"
  type        = string
  default     = ""
}
