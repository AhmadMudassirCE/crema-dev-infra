# VPC Module - Network foundation with public and private subnets
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  project_name         = var.project_name
}

# NAT Module - Network Address Translation for private subnet internet access
module "nat" {
  source = "./modules/nat"

  public_subnet_ids      = module.vpc.public_subnet_ids
  private_route_table_id = module.vpc.private_route_table_id
  project_name           = var.project_name
}

# ECR Module - Container registry for Docker images
module "ecr" {
  source = "./modules/ecr"

  repository_name = "${var.project_name}-app"
}

# ALB Module - Application Load Balancer for traffic distribution
module "alb" {
  source = "./modules/alb"

  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  project_name           = var.project_name
  container_port         = var.container_port
  certificate_arn        = var.certificate_arn
  
  # Very forgiving health checks for slow Rails boot time
  health_check_timeout   = 30    # 30 seconds to wait for response
  health_check_interval  = 60    # Check every 60 seconds
  unhealthy_threshold    = 10    # 10 failed checks before marking unhealthy (10 minutes)
  healthy_threshold      = 2     # 2 successful checks to mark healthy (2 minutes)
}

# RDS Module - PostgreSQL database
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs.ecs_security_group_id
  
  # Database configuration
  postgres_version    = var.postgres_version
  instance_class      = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  database_name       = var.database_name
  master_username     = var.database_username
  
  # Backup and maintenance
  backup_retention_period = var.rds_backup_retention_period
  multi_az                = var.rds_multi_az
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.rds_skip_final_snapshot
}

# Redis Module - ElastiCache for caching and sessions
module "redis" {
  source = "./modules/redis"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs.ecs_security_group_id
  
  # Redis configuration
  redis_version           = var.redis_version
  node_type               = var.redis_node_type
  num_cache_nodes         = var.redis_num_cache_nodes
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  multi_az_enabled        = var.redis_multi_az_enabled
}

# ECS Module - Container orchestration and task management (Web service)
module "ecs" {
  source = "./modules/ecs"

  cluster_name          = "${var.project_name}-cluster"
  service_name          = "${var.project_name}-web-service"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  container_image       = var.container_image
  container_name        = "${var.project_name}-web"
  container_port        = var.container_port
  task_cpu              = var.web_task_cpu
  task_memory           = var.web_task_memory
  desired_count         = var.web_desired_count
  environment_variables = var.environment_variables
  secrets               = concat(var.secrets, [
    {
      name      = "DATABASE_URL"
      valueFrom = module.rds.database_url_parameter_arn
    },
    {
      name      = "REDIS_URL"
      valueFrom = module.redis.redis_url_parameter_arn
    }
  ])
  
  # Log retention
  log_retention_days = var.log_retention_days

  # Auto-scaling configuration
  enable_autoscaling           = var.web_enable_autoscaling
  autoscaling_min_capacity     = var.web_autoscaling_min_capacity
  autoscaling_max_capacity     = var.web_autoscaling_max_capacity
  autoscaling_cpu_enabled      = var.web_autoscaling_cpu_enabled
  autoscaling_cpu_target       = var.web_autoscaling_cpu_target
  autoscaling_memory_enabled   = var.web_autoscaling_memory_enabled
  autoscaling_memory_target    = var.web_autoscaling_memory_target
  autoscaling_scale_in_cooldown  = var.web_autoscaling_scale_in_cooldown
  autoscaling_scale_out_cooldown = var.web_autoscaling_scale_out_cooldown
}

# Sidekiq Module - Background job processing service
module "sidekiq" {
  source = "./modules/sidekiq"

  cluster_id                = module.ecs.cluster_id
  service_name              = "${var.project_name}-sidekiq-service"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  ecs_security_group_id     = module.ecs.ecs_security_group_id
  container_image           = var.container_image
  task_cpu                  = var.sidekiq_task_cpu
  task_memory               = var.sidekiq_task_memory
  desired_count             = var.sidekiq_desired_count
  sidekiq_command           = var.sidekiq_command
  environment_variables     = var.environment_variables
  task_execution_role_arn   = module.ecs.task_execution_role_arn
  task_role_arn             = module.ecs.task_role_arn
  log_group_name            = module.ecs.cloudwatch_log_group_name
  secrets                   = concat(var.secrets, [
    {
      name      = "DATABASE_URL"
      valueFrom = module.rds.database_url_parameter_arn
    },
    {
      name      = "REDIS_URL"
      valueFrom = module.redis.redis_url_parameter_arn
    }
  ])
}

# Scheduled Tasks Module - EventBridge Scheduler for Rake Tasks
module "scheduled_tasks" {
  source = "./modules/scheduled-tasks"

  project_name       = var.project_name
  cluster_arn        = module.ecs.cluster_arn
  container_image    = var.container_image
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.ecs.ecs_security_group_id
  
  secrets = concat(var.secrets, [
    {
      name      = "DATABASE_URL"
      valueFrom = module.rds.database_url_parameter_arn
    },
    {
      name      = "REDIS_URL"
      valueFrom = module.redis.redis_url_parameter_arn
    }
  ])
  
  scheduled_tasks = var.scheduled_tasks

  # Log retention
  log_retention_days = var.log_retention_days
}

# Monitoring Module - CloudWatch Alarms with SNS Notifications
module "monitoring" {
  source = "./modules/monitoring"

  project_name            = var.project_name
  alert_email             = var.alert_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  rds_instance_identifier = module.rds.db_instance_identifier
}

# CodePipeline Module - CI/CD for ECS deployments
module "codepipeline" {
  source = "./modules/codepipeline"
  count  = var.enable_codepipeline ? 1 : 0

  project_name             = var.project_name
  aws_region               = var.aws_region
  codestar_connection_arn  = var.codestar_connection_arn
  github_repo_id           = var.github_repo_id
  github_branch            = var.github_branch
  dockerfile_path          = var.dockerfile_path
  ecr_repository_url       = module.ecr.repository_url
  ecr_repository_arn       = module.ecr.repository_arn
  ecs_cluster_name         = module.ecs.cluster_name
  ecs_web_service_name     = module.ecs.service_name
  ecs_sidekiq_service_name = "${var.project_name}-sidekiq-service"
  container_name           = "${var.project_name}-web"
  container_port           = var.container_port
}
