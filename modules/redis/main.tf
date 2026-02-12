# Redis Module - ElastiCache for caching and session storage

# Subnet Group for ElastiCache
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name      = "${var.project_name}-redis-subnet-group"
    ManagedBy = "Terraform"
    Module    = "redis"
  }
}

# Security Group for Redis
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for ElastiCache Redis - allows access from ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name      = "${var.project_name}-redis-sg"
    ManagedBy = "Terraform"
    Module    = "redis"
  }
}

# Ingress rule: Allow Redis traffic from ECS security group
resource "aws_security_group_rule" "redis_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis.id
  source_security_group_id = var.ecs_security_group_id
  description              = "Allow Redis access from ECS tasks"
}

# Egress rule: Allow all outbound
resource "aws_security_group_rule" "redis_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis.id
  description       = "Allow all outbound traffic"
}

# ElastiCache Replication Group (Redis)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cluster for ${var.project_name}"
  
  engine               = "redis"
  engine_version       = var.redis_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  parameter_group_name = var.parameter_group_name
  port                 = 6379

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  # Backup configuration
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  # Encryption
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.transit_encryption_enabled && var.auth_token_enabled ? random_password.auth_token[0].result : null

  # Automatic failover (requires at least 2 nodes)
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  multi_az_enabled          = var.num_cache_nodes > 1 ? var.multi_az_enabled : false

  # Notifications
  notification_topic_arn = var.notification_topic_arn

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = {
    Name      = "${var.project_name}-redis"
    ManagedBy = "Terraform"
    Module    = "redis"
  }
}

# Random auth token (only if transit encryption is enabled)
resource "random_password" "auth_token" {
  count   = var.transit_encryption_enabled && var.auth_token_enabled ? 1 : 0
  length  = 32
  special = false
}

# Store Redis connection URL in SSM Parameter Store
resource "aws_ssm_parameter" "redis_url" {
  name        = "/${var.project_name}/REDIS_URL"
  description = "Redis connection URL"
  type        = "SecureString"
  value       = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"

  tags = {
    Name      = "${var.project_name}-redis-url"
    ManagedBy = "Terraform"
    Module    = "redis"
  }
}
