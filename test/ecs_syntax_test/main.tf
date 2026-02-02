# ECS Module Syntax Test
# This test validates the Terraform syntax of the ECS module

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# Mock data sources for testing
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "ecs" {
  source = "../../modules/ecs"

  cluster_name          = "test-cluster"
  service_name          = "test-service"
  vpc_id                = "vpc-12345678"
  private_subnet_id     = "subnet-12345678"
  alb_security_group_id = "sg-12345678"
  target_group_arn      = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890123456"
  container_image       = "nginx:latest"
  container_name        = "test-container"
  container_port        = 80
  task_cpu              = "256"
  task_memory           = "512"
  desired_count         = 1
  log_retention_days    = 7

  environment_variables = {
    ENV = "test"
  }

  secrets = [
    {
      name      = "DB_PASSWORD"
      valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-secret"
    }
  ]

  additional_task_policy_arns = []
}

output "task_execution_role_arn" {
  value = module.ecs.task_execution_role_arn
}

output "task_role_arn" {
  value = module.ecs.task_role_arn
}

output "task_definition_arn" {
  value = module.ecs.task_definition_arn
}

output "cloudwatch_log_group_name" {
  value = module.ecs.cloudwatch_log_group_name
}

output "cluster_id" {
  value = module.ecs.cluster_id
}

output "cluster_name" {
  value = module.ecs.cluster_name
}

output "service_name" {
  value = module.ecs.service_name
}
