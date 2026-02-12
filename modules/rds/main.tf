# RDS Module - PostgreSQL database

# DB Subnet Group - spans multiple AZs for high availability
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name      = "${var.project_name}-db-subnet-group"
    ManagedBy = "Terraform"
    Module    = "rds"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL - allows access from ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name      = "${var.project_name}-rds-sg"
    ManagedBy = "Terraform"
    Module    = "rds"
  }
}

# Ingress rule: Allow PostgreSQL traffic from ECS security group
resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.ecs_security_group_id
  description              = "Allow PostgreSQL access from ECS tasks"
}

# Egress rule: Allow all outbound (for updates, etc.)
resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = false  # Only letters and numbers - no special characters
}

# Store password in SSM Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/db_password"
  description = "RDS PostgreSQL master password"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = {
    Name      = "${var.project_name}-db-password"
    ManagedBy = "Terraform"
    Module    = "rds"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = var.postgres_version

  # Instance configuration - smallest production-ready size
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # Database configuration
  db_name  = var.database_name
  username = var.master_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # High availability
  multi_az = var.multi_az

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled
  
  # Apply changes immediately instead of during maintenance window
  apply_immediately = true

  tags = {
    Name      = "${var.project_name}-postgres"
    ManagedBy = "Terraform"
    Module    = "rds"
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-rds-monitoring-role"
    ManagedBy = "Terraform"
    Module    = "rds"
  }
}

# Attach AWS managed policy for RDS monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Store database connection URL in SSM Parameter Store
resource "aws_ssm_parameter" "database_url" {
  name        = "/${var.project_name}/DATABASE_URL"
  description = "PostgreSQL database connection URL"
  type        = "SecureString"
  value       = "postgresql://${var.master_username}:${random_password.db_password.result}@${aws_db_instance.main.endpoint}/${var.database_name}"

  tags = {
    Name      = "${var.project_name}-database-url"
    ManagedBy = "Terraform"
    Module    = "rds"
  }
}
