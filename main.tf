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

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  project_name      = var.project_name
  container_port    = var.container_port
  certificate_arn   = var.certificate_arn
}

# ECS Module - Container orchestration and task management
module "ecs" {
  source = "./modules/ecs"

  cluster_name          = "${var.project_name}-cluster"
  service_name          = "${var.project_name}-service"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  container_image       = var.container_image
  container_name        = "${var.project_name}-container"
  container_port        = var.container_port
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.desired_count
  environment_variables = var.environment_variables
  secrets               = var.secrets
}
