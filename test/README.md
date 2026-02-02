# Terraform Infrastructure Tests

This directory contains property-based tests and unit tests for the Terraform infrastructure using Terratest.

## Test Structure

Tests will be implemented using Go and Terratest framework:
- Property-based tests validate universal properties across randomized configurations
- Unit tests validate specific examples and edge cases
- Each test automatically cleans up resources using `defer terraform.Destroy()`

## Running Tests

```bash
cd test
go test -v -timeout 30m
```

## Test Coverage

Tests will be implemented in subsequent tasks to validate:
- VPC and network foundation (Tasks 2.2-2.4)
- NAT Gateway configuration (Tasks 3.2-3.3)
- ECR repository setup (Task 5.2)
- ALB configuration (Tasks 6.4-6.7)
- ECS cluster and service (Tasks 8.2-8.3, 9.2-9.3, 10.2-10.3, 11.2-11.4)
- Module structure and orchestration (Tasks 13.3-13.4, 14.1-14.3)
- Documentation and backend configuration (Task 15.3)
- Integration testing (Tasks 16.1-16.2)
