# Checkpoint test configuration for ECR and ALB modules
# This validates that ECR and ALB modules are correctly implemented

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
  region = "us-east-1"
}

# VPC Module - Required for ALB
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone   = "us-east-1a"
  project_name        = "checkpoint-test"
}

# NAT Module - Required for complete VPC setup
module "nat" {
  source = "../../modules/nat"

  public_subnet_id       = module.vpc.public_subnet_id
  private_route_table_id = module.vpc.private_route_table_id
  project_name           = "checkpoint-test"
}

# ECR Module - Test with default settings
module "ecr" {
  source = "../../modules/ecr"

  repository_name = "checkpoint-test-app"
}

# ALB Module - Test with default settings
module "alb" {
  source = "../../modules/alb"

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  project_name     = "checkpoint-test"
  container_port   = 80
}

# Outputs to verify module functionality
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr.repository_arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.alb.alb_security_group_id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = module.alb.target_group_arn
}
