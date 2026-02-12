variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for subnets (requires at least 2 for ALB)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "container_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 80
}

# Web Service Configuration
variable "web_task_cpu" {
  description = "CPU units for the web task"
  type        = string
  default     = "256"
}

variable "web_task_memory" {
  description = "Memory for the web task in MB"
  type        = string
  default     = "512"
}

variable "web_desired_count" {
  description = "Desired number of web ECS tasks"
  type        = number
  default     = 1
}

# Sidekiq Service Configuration
variable "sidekiq_task_cpu" {
  description = "CPU units for the Sidekiq task"
  type        = string
  default     = "256"
}

variable "sidekiq_task_memory" {
  description = "Memory for the Sidekiq task in MB"
  type        = string
  default     = "512"
}

variable "sidekiq_desired_count" {
  description = "Desired number of Sidekiq ECS tasks"
  type        = number
  default     = 1
}

variable "sidekiq_command" {
  description = "Command to run Sidekiq"
  type        = list(string)
  default     = ["bundle", "exec", "sidekiq"]
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for HTTPS (optional)"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Sensitive environment variables from Secrets Manager or SSM"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

# RDS Configuration Variables
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "crema_production"
}

variable "database_username" {
  description = "Master username for the database"
  type        = string
  default     = "crema_admin"
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on RDS deletion"
  type        = bool
  default     = false
}

# Redis Configuration Variables
variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes (1 for single node, 2+ for cluster)"
  type        = number
  default     = 1
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 5
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ for Redis (requires num_cache_nodes > 1)"
  type        = bool
  default     = false
}

# Scheduled Tasks Configuration (EventBridge Scheduler)
variable "scheduled_tasks" {
  description = "List of scheduled rake tasks to create with EventBridge"
  type = list(object({
    name                = string
    schedule_expression = string  # cron(0 9 * * ? *) or rate(1 hour)
    command             = list(string)  # ["bundle", "exec", "rake", "task:name"]
    enabled             = bool
  }))
  default = []
}


# Web Service Auto-Scaling Configuration
variable "web_enable_autoscaling" {
  description = "Enable auto-scaling for the web service"
  type        = bool
  default     = false
}

variable "web_autoscaling_min_capacity" {
  description = "Minimum number of web tasks"
  type        = number
  default     = 1
}

variable "web_autoscaling_max_capacity" {
  description = "Maximum number of web tasks"
  type        = number
  default     = 4
}

variable "web_autoscaling_cpu_enabled" {
  description = "Enable CPU-based auto-scaling for web service"
  type        = bool
  default     = true
}

variable "web_autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for web service"
  type        = number
  default     = 70
}

variable "web_autoscaling_memory_enabled" {
  description = "Enable memory-based auto-scaling for web service"
  type        = bool
  default     = false
}

variable "web_autoscaling_memory_target" {
  description = "Target memory utilization percentage for web service"
  type        = number
  default     = 80
}

variable "web_autoscaling_scale_in_cooldown" {
  description = "Cooldown period (seconds) after scale-in for web service"
  type        = number
  default     = 300
}

variable "web_autoscaling_scale_out_cooldown" {
  description = "Cooldown period (seconds) after scale-out for web service"
  type        = number
  default     = 60
}
