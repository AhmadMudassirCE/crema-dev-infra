# Scheduled Tasks Module - EventBridge Scheduler for Rake Tasks

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# CloudWatch Log Group for scheduled tasks
resource "aws_cloudwatch_log_group" "rake_tasks" {
  name              = "/ecs/${var.project_name}-rake-tasks"
  retention_in_days = var.log_retention_days

  tags = {
    Name      = "/ecs/${var.project_name}-rake-tasks"
    ManagedBy = "Terraform"
    Module    = "scheduled-tasks"
  }
}

# IAM Role for Task Execution (pulling images, fetching secrets)
resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-rake-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-rake-task-execution-role"
    ManagedBy = "Terraform"
    Module    = "scheduled-tasks"
  }
}

resource "aws_iam_role_policy_attachment" "task_execution_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ECR permissions for task execution
resource "aws_iam_role_policy" "task_execution_ecr" {
  name = "${var.project_name}-rake-ecr-policy"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Logs permissions
resource "aws_iam_role_policy" "task_execution_logs" {
  name = "${var.project_name}-rake-logs-policy"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.rake_tasks.arn}:*"
      }
    ]
  })
}

# Secrets permissions (SSM Parameter Store)
resource "aws_iam_role_policy" "task_execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0
  name  = "${var.project_name}-rake-secrets-policy"
  role  = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters"
        ]
        Resource = [for secret in var.secrets : secret.valueFrom]
      }
    ]
  })
}

# IAM Role for the Task itself (app permissions like S3 access)
resource "aws_iam_role" "task" {
  name = "${var.project_name}-rake-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-rake-task-role"
    ManagedBy = "Terraform"
    Module    = "scheduled-tasks"
  }
}


# ECS Task Definition for Rake Tasks
resource "aws_ecs_task_definition" "rake_tasks" {
  family                   = "${var.project_name}-rake-tasks"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "rake-runner"
      image     = var.container_image
      essential = true
      
      # Default command - will be overridden by EventBridge
      command = ["echo", "Command overridden by EventBridge"]

      secrets = var.secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.rake_tasks.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "rake"
        }
      }
    }
  ])

  tags = {
    Name      = "${var.project_name}-rake-tasks"
    ManagedBy = "Terraform"
    Module    = "scheduled-tasks"
  }
}

# IAM Role for EventBridge Scheduler to run ECS tasks
resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-scheduler-role"
    ManagedBy = "Terraform"
    Module    = "scheduled-tasks"
  }
}

# Policy allowing EventBridge to run ECS tasks
resource "aws_iam_role_policy" "scheduler_ecs" {
  name = "${var.project_name}-scheduler-ecs-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ecs:RunTask"]
        Resource = [aws_ecs_task_definition.rake_tasks.arn]
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.cluster_arn
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.task_execution.arn,
          aws_iam_role.task.arn
        ]
      }
    ]
  })
}


# EventBridge Scheduler Rules for each scheduled task
resource "aws_scheduler_schedule" "rake_tasks" {
  for_each = { for task in var.scheduled_tasks : task.name => task }

  name       = "${var.project_name}-${each.value.name}"
  group_name = "default"

  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = "UTC"

  state = each.value.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.cluster_arn
    role_arn = aws_iam_role.scheduler.arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.rake_tasks.arn
      launch_type         = "FARGATE"
      task_count          = 1

      network_configuration {
        subnets          = var.private_subnet_ids
        security_groups  = [var.security_group_id]
        assign_public_ip = false
      }
    }

    input = jsonencode({
      containerOverrides = [
        {
          name    = "rake-runner"
          command = each.value.command
        }
      ]
    })
  }
}
