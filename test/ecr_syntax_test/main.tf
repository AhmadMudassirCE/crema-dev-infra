# Test configuration to validate ECR module syntax

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

# Test ECR module with default settings
module "ecr_default" {
  source = "../../modules/ecr"

  repository_name = "test-app"
}

# Test ECR module with custom settings
module "ecr_custom" {
  source = "../../modules/ecr"

  repository_name      = "test-app-custom"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = false
}

# Test ECR module with custom lifecycle policy
module "ecr_with_policy" {
  source = "../../modules/ecr"

  repository_name = "test-app-policy"
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "default_repo_url" {
  value = module.ecr_default.repository_url
}

output "custom_repo_url" {
  value = module.ecr_custom.repository_url
}

output "policy_repo_url" {
  value = module.ecr_with_policy.repository_url
}
