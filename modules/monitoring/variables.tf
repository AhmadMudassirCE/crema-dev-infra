# Monitoring Module Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS alert notifications"
  type        = string
}

# ALB variables
variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  type        = string
}

# ECS variables
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS web service"
  type        = string
}

# RDS variables
variable "rds_instance_identifier" {
  description = "Identifier of the RDS instance"
  type        = string
}
