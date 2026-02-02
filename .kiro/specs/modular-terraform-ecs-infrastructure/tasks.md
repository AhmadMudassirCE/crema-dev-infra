# Implementation Plan: Modular Terraform ECS Infrastructure

## Overview

This implementation plan breaks down the modular Terraform infrastructure into discrete coding tasks. The approach follows a bottom-up strategy: building foundational modules first (VPC, NAT), then dependent modules (ECR, ALB), and finally the orchestration layer (ECS, root module). Each module is implemented with its core resources, then tested before moving to the next.

The implementation includes property-based tests using Terratest to validate that the infrastructure behaves correctly across a wide range of configurations.

## Tasks

- [x] 1. Set up project structure and Terraform configuration
  - Create directory structure: `modules/vpc`, `modules/nat`, `modules/ecr`, `modules/alb`, `modules/ecs`, `test`
  - Create root-level `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
  - Configure Terraform version constraints and required providers (AWS)
  - Create example `terraform.tfvars.example` file
  - Create `.gitignore` for Terraform files
  - _Requirements: 8.1, 8.6_

- [ ] 2. Implement VPC module
  - [x] 2.1 Create VPC module structure and core resources
    - Create `modules/vpc/main.tf`, `modules/vpc/variables.tf`, `modules/vpc/outputs.tf`
    - Implement `aws_vpc` resource with configurable CIDR and DNS support
    - Implement `aws_subnet` resources for public and private subnets
    - Implement `aws_internet_gateway` resource
    - Implement `aws_route_table` resources for public and private subnets
    - Implement `aws_route` for public subnet to Internet Gateway
    - Implement `aws_route_table_association` resources
    - Add resource tagging with project name
    - Define input variables: `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidr`, `availability_zone`, `project_name`
    - Define outputs: `vpc_id`, `public_subnet_id`, `private_subnet_id`, `internet_gateway_id`, `public_route_table_id`, `private_route_table_id`
    - Add variable validation for CIDR blocks
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.7, 1.8, 8.7_

  - [ ]* 2.2 Write property test for VPC network foundation
    - **Property 1: VPC Network Foundation Completeness**
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.7**
    - Create `test/vpc_test.go`
    - Generate random valid VPC and subnet CIDRs
    - Apply VPC module with random configuration
    - Verify VPC, subnets, IGW, and route tables are created
    - Verify resources have correct configuration
    - Run 100 iterations with different configurations

  - [ ]* 2.3 Write property test for public subnet routing
    - **Property 2: Public Subnet Internet Routing**
    - **Validates: Requirements 1.5**
    - Verify public route table has route to 0.0.0.0/0 via IGW
    - Run 100 iterations

  - [ ]* 2.4 Write unit tests for VPC module edge cases
    - Test with minimum and maximum valid CIDR ranges
    - Test with different availability zones
    - Test invalid CIDR block rejection

- [ ] 3. Implement NAT module
  - [x] 3.1 Create NAT module structure and resources
    - Create `modules/nat/main.tf`, `modules/nat/variables.tf`, `modules/nat/outputs.tf`
    - Implement `aws_eip` resource for NAT Gateway
    - Implement `aws_nat_gateway` resource in public subnet
    - Implement `aws_route` for private subnet to NAT Gateway
    - Add resource tagging
    - Define input variables: `public_subnet_id`, `private_route_table_id`, `project_name`
    - Define outputs: `nat_gateway_id`, `elastic_ip`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ]* 3.2 Write property test for NAT Gateway configuration
    - **Property 4: NAT Gateway Configuration**
    - **Validates: Requirements 2.1, 2.2**
    - Verify EIP and NAT Gateway are created
    - Verify NAT Gateway is in public subnet
    - Run 100 iterations

  - [ ]* 3.3 Write property test for private subnet NAT routing
    - **Property 3: Private Subnet NAT Routing**
    - **Validates: Requirements 1.6, 2.3**
    - Verify private route table has route to 0.0.0.0/0 via NAT Gateway
    - Run 100 iterations

- [x] 4. Checkpoint - Verify VPC and NAT modules
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement ECR module
  - [x] 5.1 Create ECR module structure and resources
    - Create `modules/ecr/main.tf`, `modules/ecr/variables.tf`, `modules/ecr/outputs.tf`
    - Implement `aws_ecr_repository` resource with configurable name
    - Configure image tag mutability setting
    - Enable image scanning on push
    - Implement `aws_ecr_lifecycle_policy` resource with conditional creation
    - Provide default lifecycle policy (keep last 10 images)
    - Define input variables: `repository_name`, `image_tag_mutability`, `scan_on_push`, `lifecycle_policy`
    - Define outputs: `repository_url`, `repository_arn`, `repository_name`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ]* 5.2 Write property test for ECR repository configuration
    - **Property 5: ECR Repository Configuration**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
    - Generate random repository names and configurations
    - Verify repository is created with correct settings
    - Test with and without lifecycle policies
    - Run 100 iterations

- [ ] 6. Implement ALB module
  - [x] 6.1 Create ALB module structure and security group
    - Create `modules/alb/main.tf`, `modules/alb/variables.tf`, `modules/alb/outputs.tf`
    - Implement `aws_security_group` for ALB
    - Add ingress rules for ports 80 and 443 from 0.0.0.0/0
    - Add egress rule for all traffic
    - Add resource tagging
    - Define input variables: `vpc_id`, `public_subnet_id`, `project_name`, `container_port`, `health_check_path`, `health_check_interval`, `health_check_timeout`, `healthy_threshold`, `unhealthy_threshold`, `certificate_arn`
    - _Requirements: 6.3, 6.4, 7.1_

  - [x] 6.2 Create ALB and target group resources
    - Implement `aws_lb` resource (Application Load Balancer)
    - Configure as internet-facing in public subnet
    - Implement `aws_lb_target_group` resource with target type "ip"
    - Configure health check with parameters
    - Add resource tagging
    - _Requirements: 6.1, 6.2, 6.5_

  - [x] 6.3 Create ALB listeners
    - Implement `aws_lb_listener` for HTTP on port 80
    - Configure default action to forward to target group
    - Implement conditional `aws_lb_listener` for HTTPS on port 443
    - Configure SSL certificate when provided
    - Define outputs: `alb_dns_name`, `alb_arn`, `target_group_arn`, `alb_security_group_id`
    - _Requirements: 6.6, 6.7, 6.8_

  - [ ]* 6.4 Write property test for ALB configuration
    - **Property 11: ALB Public Subnet Placement**
    - **Validates: Requirements 6.1, 6.2**
    - Verify ALB is created in public subnet with internet-facing scheme
    - Run 100 iterations

  - [ ]* 6.5 Write property test for ALB security group
    - **Property 12: ALB Security Group Ingress Rules**
    - **Validates: Requirements 6.3, 6.4, 7.1**
    - Verify security group allows traffic on ports 80 and 443
    - Test with and without certificate ARN
    - Run 100 iterations

  - [ ]* 6.6 Write property test for target group and health checks
    - **Property 13: ALB Target Group and Health Checks**
    - **Validates: Requirements 6.5, 9.5, 9.6**
    - Generate random health check parameters
    - Verify target group configuration
    - Run 100 iterations

  - [ ]* 6.7 Write property test for ALB listeners
    - **Property 14: ALB Listener Configuration**
    - **Validates: Requirements 6.6, 6.7**
    - Verify HTTP listener exists
    - Verify HTTPS listener exists when certificate provided
    - Run 100 iterations

- [x] 7. Checkpoint - Verify ECR and ALB modules
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement ECS module - IAM roles
  - [x] 8.1 Create ECS module structure and IAM roles
    - Create `modules/ecs/main.tf`, `modules/ecs/variables.tf`, `modules/ecs/outputs.tf`
    - Implement `aws_iam_role` for task execution
    - Attach `AmazonECSTaskExecutionRolePolicy` managed policy
    - Create inline policy for ECR permissions (GetAuthorizationToken, BatchCheckLayerAvailability, GetDownloadUrlForLayer, BatchGetImage)
    - Create inline policy for CloudWatch Logs permissions (CreateLogStream, PutLogEvents)
    - Create conditional inline policy for Secrets Manager/SSM permissions when secrets are provided
    - Implement `aws_iam_role` for task role
    - Attach additional policies based on input parameter
    - Define input variables: `cluster_name`, `service_name`, `vpc_id`, `private_subnet_id`, `alb_security_group_id`, `target_group_arn`, `container_image`, `container_name`, `container_port`, `task_cpu`, `task_memory`, `desired_count`, `log_retention_days`, `additional_task_policy_arns`, `environment_variables`, `secrets`
    - Add variable validation for CPU/memory combinations
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

  - [ ]* 8.2 Write property test for IAM task execution role
    - **Property 9: IAM Task Execution Role Permissions**
    - **Validates: Requirements 5.1, 5.2, 5.4, 5.5, 5.7, 10.5**
    - Verify execution role has correct policies attached
    - Test with and without secrets
    - Run 100 iterations

  - [ ]* 8.3 Write property test for IAM task role
    - **Property 10: IAM Task Role Configuration**
    - **Validates: Requirements 5.3, 5.6**
    - Generate random additional policies
    - Verify task role has policies attached
    - Run 100 iterations

- [ ] 9. Implement ECS module - cluster and security group
  - [x] 9.1 Create ECS cluster and security group
    - Implement `aws_ecs_cluster` resource with container insights
    - Implement `aws_security_group` for ECS tasks
    - Add ingress rule allowing traffic from ALB security group on container port
    - Add egress rule allowing all traffic to 0.0.0.0/0
    - Add resource tagging
    - _Requirements: 4.1, 4.7, 7.3, 7.4_

  - [ ]* 9.2 Write property test for ECS security group
    - **Property 15: ECS Security Group Isolation**
    - **Validates: Requirements 4.7, 7.3, 7.4**
    - Verify ECS security group allows traffic only from ALB
    - Verify outbound traffic is allowed
    - Run 100 iterations

  - [ ]* 9.3 Write property test for security group traffic flow
    - **Property 16: Security Group Traffic Flow**
    - **Validates: Requirements 7.2**
    - Verify bidirectional traffic rules between ALB and ECS
    - Run 100 iterations

- [ ] 10. Implement ECS module - CloudWatch and task definition
  - [x] 10.1 Create CloudWatch log group and task definition
    - Implement `aws_cloudwatch_log_group` resource with configurable retention
    - Implement `aws_ecs_task_definition` resource
    - Configure Fargate compatibility and awsvpc network mode
    - Set CPU and memory from variables
    - Configure container definition with image, port mappings, environment variables, and secrets
    - Configure awslogs log driver pointing to CloudWatch log group
    - Associate execution role and task role
    - _Requirements: 4.2, 4.3, 9.3, 10.1, 10.2, 10.4_

  - [ ]* 10.2 Write property test for ECS task definition
    - **Property 7: ECS Task Definition Correctness**
    - **Validates: Requirements 4.2, 4.3, 9.3**
    - Generate random CPU/memory combinations
    - Verify task definition configuration
    - Run 100 iterations

  - [ ]* 10.3 Write property test for CloudWatch logging
    - **Property 23: CloudWatch Logging Configuration**
    - **Validates: Requirements 10.1, 10.2, 10.3, 10.4**
    - Verify log group exists with correct retention
    - Verify task definition uses awslogs driver
    - Run 100 iterations

- [ ] 11. Implement ECS module - service
  - [x] 11.1 Create ECS service with ALB integration
    - Implement `aws_ecs_service` resource
    - Configure Fargate launch type
    - Set desired count from variable
    - Configure network configuration with private subnet and ECS security group
    - Configure load balancer with target group and container port
    - Set health check grace period
    - Define outputs: `cluster_id`, `cluster_name`, `service_name`, `task_definition_arn`, `task_execution_role_arn`, `task_role_arn`
    - _Requirements: 4.4, 4.5, 4.6, 4.8, 9.1, 9.2, 9.4_

  - [ ]* 11.2 Write property test for ECS cluster and service
    - **Property 6: ECS Cluster and Service Configuration**
    - **Validates: Requirements 4.1, 4.4, 4.6, 4.8**
    - Generate random task counts
    - Verify cluster and service configuration
    - Run 100 iterations

  - [ ]* 11.3 Write property test for ECS-ALB integration
    - **Property 8: ECS-ALB Integration**
    - **Validates: Requirements 4.5, 9.1, 9.2**
    - Verify service is configured with target group
    - Run 100 iterations

  - [ ]* 11.4 Write property test for ECS task networking
    - **Property 22: ECS Task Network Assignment**
    - **Validates: Requirements 9.4**
    - Verify tasks are assigned IPs from private subnet
    - Run 100 iterations

- [x] 12. Checkpoint - Verify ECS module
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Implement root module orchestration
  - [x] 13.1 Create root module with all sub-modules
    - Update root `main.tf` to invoke VPC module
    - Invoke NAT module with VPC outputs
    - Invoke ECR module
    - Invoke ALB module with VPC outputs
    - Invoke ECS module with VPC, ALB, and ECR outputs
    - Configure provider with AWS region variable
    - _Requirements: 8.3, 8.5_

  - [x] 13.2 Define root module variables and outputs
    - Update `variables.tf` with all required parameters: `aws_region`, `project_name`, `availability_zone`, `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidr`, `container_image`, `container_port`, `task_cpu`, `task_memory`, `desired_count`, `certificate_arn`, `environment_variables`, `secrets`
    - Provide default values for optional parameters
    - Update `outputs.tf` with: `alb_dns_name`, `ecr_repository_url`, `ecs_cluster_name`, `ecs_service_name`, `vpc_id`, `public_subnet_id`, `private_subnet_id`, `nat_gateway_ip`
    - Add descriptions to all outputs
    - _Requirements: 8.4, 8.7, 11.1, 11.2, 11.3, 11.4, 11.5_

  - [ ]* 13.3 Write property test for root module orchestration
    - **Property 20: Root Module Orchestration**
    - **Validates: Requirements 8.3, 8.4**
    - Verify all modules are invoked correctly
    - Verify parameters are passed between modules
    - Run 100 iterations

  - [ ]* 13.4 Write property test for module outputs
    - **Property 24: Infrastructure Output Completeness**
    - **Validates: Requirements 1.8, 2.4, 3.5, 6.8, 11.1, 11.2, 11.3, 11.4, 11.5**
    - Verify all required outputs exist with descriptions
    - Run 100 iterations

- [ ] 14. Implement modular code structure validation
  - [ ]* 14.1 Write property test for module structure
    - **Property 18: Modular Code Organization**
    - **Validates: Requirements 8.1, 8.6**
    - Verify directory structure exists
    - Verify each module has main.tf, variables.tf, outputs.tf
    - Run 100 iterations

  - [ ]* 14.2 Write property test for module parameterization
    - **Property 19: Module Parameterization**
    - **Validates: Requirements 8.2, 8.5**
    - Verify modules accept variables and expose outputs
    - Run 100 iterations

  - [ ]* 14.3 Write property test for default values
    - **Property 21: Default Parameter Values**
    - **Validates: Requirements 8.7**
    - Verify optional parameters have defaults
    - Run 100 iterations

- [ ] 15. Create documentation and examples
  - [x] 15.1 Create README and backend configuration
    - Create `README.md` with overview, prerequisites, usage instructions
    - Document required AWS permissions
    - Document how to push Docker images to ECR
    - Document how to access the application via ALB DNS
    - Create `backend.tf.example` with S3 backend configuration
    - Document S3 bucket and DynamoDB table setup for state locking
    - Document local vs remote state usage
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [x] 15.2 Create example configuration files
    - Create `terraform.tfvars.example` with all parameters documented
    - Include examples for environment variables and secrets
    - Create `examples/` directory with sample configurations
    - Document Fargate CPU/memory valid combinations

  - [ ]* 15.3 Write property test for backend documentation
    - **Property 25: Backend Configuration Documentation**
    - **Validates: Requirements 12.1, 12.2, 12.3, 12.4**
    - Verify documentation files exist
    - Verify backend examples are present
    - Run 100 iterations

- [ ] 16. Integration testing and validation
  - [ ]* 16.1 Write integration test for complete infrastructure
    - Create end-to-end test deploying all modules
    - Verify VPC, NAT, ECR, ALB, and ECS are created
    - Verify network connectivity (ALB can reach ECS)
    - Verify security groups allow correct traffic
    - Test with environment variables and secrets
    - Clean up resources after test

  - [ ]* 16.2 Write property test for custom security group rules
    - **Property 17: Custom Security Group Rules Application**
    - **Validates: Requirements 7.5**
    - Test with custom security group rules
    - Verify rules are applied correctly
    - Run 100 iterations

- [x] 17. Final checkpoint - Complete infrastructure validation
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties with 100 iterations each
- Unit tests validate specific examples and edge cases
- Terratest is used for all infrastructure testing
- Tests should clean up resources automatically using `defer terraform.Destroy()`
- Module implementation follows bottom-up approach: VPC → NAT → ECR → ALB → ECS → Root
- Each module is tested before moving to the next
- Checkpoints ensure incremental validation
