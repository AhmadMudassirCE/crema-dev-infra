# CodePipeline Module Variables

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection to GitHub"
  type        = string
}

variable "github_repo_id" {
  description = "GitHub repository in format owner/repo"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to trigger pipeline"
  type        = string
}

variable "dockerfile_path" {
  description = "Path to the Dockerfile to build"
  type        = string
  default     = "Dockerfile"
}

variable "ecr_repository_url" {
  description = "ECR repository URL for pushing images"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_web_service_name" {
  description = "Name of the ECS web service"
  type        = string
}

variable "ecs_sidekiq_service_name" {
  description = "Name of the ECS sidekiq service"
  type        = string
}

variable "container_name" {
  description = "Name of the container in the task definition"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "CodeBuild build image"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 30
}
