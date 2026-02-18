# ECS Module - Container orchestration and task management

# Get current AWS region and account ID
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM Role for ECS Task Execution
# This role is used by ECS to pull images, write logs, and access secrets
resource "aws_iam_role" "task_execution" {
  name = "${var.service_name}-task-execution-role"

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
    Name      = "${var.service_name}-task-execution-role"
    ManagedBy = "Terraform"
    Module    = "ecs"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "task_execution_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy for ECR permissions
resource "aws_iam_role_policy" "task_execution_ecr" {
  name = "${var.service_name}-ecr-policy"
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

# Inline policy for CloudWatch Logs permissions
resource "aws_iam_role_policy" "task_execution_logs" {
  name = "${var.service_name}-logs-policy"
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
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.service_name}:*"
      }
    ]
  })
}

# Conditional inline policy for Secrets Manager and SSM Parameter Store permissions
resource "aws_iam_role_policy" "task_execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0
  name  = "${var.service_name}-secrets-policy"
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
        Resource = [
          for secret in var.secrets : secret.valueFrom
        ]
      }
    ]
  })
}

# IAM Role for ECS Tasks
# This role is used by the application running in the container
resource "aws_iam_role" "task" {
  name = "${var.service_name}-task-role"

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
    Name      = "${var.service_name}-task-role"
    ManagedBy = "Terraform"
    Module    = "ecs"
  }
}

# Attach additional policies to task role based on input parameter
resource "aws_iam_role_policy_attachment" "task_additional_policies" {
  count      = length(var.additional_task_policy_arns)
  role       = aws_iam_role.task.name
  policy_arn = var.additional_task_policy_arns[count.index]
}

# ECS Cluster with Container Insights enabled
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = {
    Name      = var.cluster_name
    ManagedBy = "Terraform"
    Module    = "ecs"
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.service_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks - allows traffic from ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name      = "${var.service_name}-ecs-tasks-sg"
    ManagedBy = "Terraform"
    Module    = "ecs"
  }
}

# Ingress rule: Allow traffic from ALB security group on container port
resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = var.alb_security_group_id
  description              = "Allow inbound traffic from ALB on container port"
}

# Egress rule: Allow all outbound traffic to internet (via NAT Gateway)
resource "aws_security_group_rule" "ecs_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow all outbound traffic to internet"
}

# CloudWatch Log Group for ECS container logs
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.service_name}" 
  retention_in_days = var.log_retention_days

  tags = {
    Name      = "/ecs/${var.service_name}"
    ManagedBy = "Terraform"
    Module    = "ecs"
  }
}

# ECS Task Definition - Web only (Puma/Rails)
resource "aws_ecs_task_definition" "main" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

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
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "web"
        }
      }
    }
  ])

  tags = {
    Name      = var.service_name
    ManagedBy = "Terraform"
    Module    = "ecs"
  }
}

# ECS Service with ALB integration
resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 420  # 7 minutes - allows time for Rails boot + 3 health checks

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name      = var.service_name
    ManagedBy = "Terraform"
    Module    = "ecs"
  }

  # Ensure the service waits for the load balancer to be ready
  depends_on = [aws_iam_role_policy_attachment.task_execution_policy]

  # Let the autoscaler manage desired_count - don't reset it on apply
  lifecycle {
    ignore_changes = [desired_count]
  }
}
