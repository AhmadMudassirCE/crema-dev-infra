# Sidekiq Module - Background job processing service

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ECS Task Definition for Sidekiq
resource "aws_ecs_task_definition" "sidekiq" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "sidekiq"
      image     = var.container_image
      essential = true
      command   = var.sidekiq_command

      environment = [
        for key, value in var.environment_variables : {
          name  = key
          value = value
        }
      ]

      secrets = var.secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "sidekiq"
        }
      }
    }
  ])

  tags = {
    Name      = var.service_name
    ManagedBy = "Terraform"
    Module    = "sidekiq"
  }
}

# ECS Service for Sidekiq (no ALB, just runs in background)
resource "aws_ecs_service" "sidekiq" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.sidekiq.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  tags = {
    Name      = var.service_name
    ManagedBy = "Terraform"
    Module    = "sidekiq"
  }
}
