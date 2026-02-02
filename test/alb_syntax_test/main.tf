# Test configuration to validate ALB module syntax

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

# Mock VPC for testing
resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "test" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Test ALB module
module "alb" {
  source = "../../modules/alb"

  vpc_id           = aws_vpc.test.id
  public_subnet_id = aws_subnet.test.id
  project_name     = "test"
  container_port   = 80
  certificate_arn  = null
}

# Test with certificate
module "alb_with_https" {
  source = "../../modules/alb"

  vpc_id           = aws_vpc.test.id
  public_subnet_id = aws_subnet.test.id
  project_name     = "test-https"
  container_port   = 8080
  certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}

output "http_listener_test" {
  value = module.alb.alb_dns_name
}

output "https_listener_test" {
  value = module.alb_with_https.alb_dns_name
}
