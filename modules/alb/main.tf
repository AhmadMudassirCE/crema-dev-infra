# ALB Module - Application Load Balancer for traffic distribution

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from the internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from the internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-alb-sg"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "alb"
  }
}

# Application Load Balancer
# AWS requires ALBs to span at least 2 availability zones (2 subnets)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name      = "${var.project_name}-alb"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "alb"
  }
}

# Target Group for ECS tasks
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = "200-399"
  }

  deregistration_delay = 30

  tags = {
    Name      = "${var.project_name}-tg"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "alb"
  }
}

# HTTP Listener on port 80 - forwards to target group (used when no SSL cert)
resource "aws_lb_listener" "http" {
  count = var.certificate_arn == null ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name      = "${var.project_name}-http-listener"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "alb"
  }
}

# HTTP Listener on port 80 - redirects to HTTPS (used when SSL cert is present)
resource "aws_lb_listener" "http_redirect" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name      = "${var.project_name}-http-redirect-listener"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "alb"
  }
}

# HTTPS Listener on port 443 (conditional - only created if certificate ARN is provided)
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name      = "${var.project_name}-https-listener"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "alb"
  }
}
