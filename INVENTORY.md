# Crema AWS ECS Infrastructure — Full Project Inventory

> Use this document to feed into Gemini (or any LLM) for generating comprehensive documentation.
> It catalogs every file, module, variable, output, and resource in this Terraform project.

---

## Project Summary

This is a **modular Terraform infrastructure** for deploying the **Crema Rails application** to **AWS ECS Fargate**. It includes multi-AZ networking, RDS PostgreSQL, ElastiCache Redis, Sidekiq background workers, scheduled rake tasks (EventBridge), CloudWatch monitoring, and CI/CD via CodePipeline.

**Application**: Crema (Ruby on Rails)
**Container Port**: 3000 (Puma)
**AWS Region**: us-east-1 (default)
**Terraform Version**: >= 1.0
**AWS Provider**: ~> 5.0

---

## 1. Root Terraform Files

| File | Purpose |
|------|---------|
| `main.tf` | Orchestrates all 11 modules with dependency wiring |
| `variables.tf` | 50+ input variables (networking, containers, RDS, Redis, autoscaling, monitoring, CI/CD) |
| `outputs.tf` | 10 outputs: ALB DNS, ECR URL, ECS cluster/service, VPC/subnets, NAT IP, RDS endpoint |
| `backend.tf` | Active backend config (not committed) |
| `backend.tf.example` | S3 + DynamoDB remote state template with full setup instructions, IAM policies, troubleshooting |
| `backend.tf.dev` | Dev backend: S3 bucket `crema-terraform-state-dev` |
| `backend.tf.prod` | Prod backend: S3 bucket `crema-terraform-state-prod` |

---

## 2. Modules (12 total, under `modules/`)

### 2.1 Core Infrastructure

| Module | Files | Resources Created |
|--------|-------|-------------------|
| **vpc/** | main.tf, variables.tf, outputs.tf | VPC, public/private subnets (multi-AZ via `count`), Internet Gateway, route tables, route table associations |
| **nat/** | main.tf, variables.tf, outputs.tf | Elastic IP, NAT Gateway, private route to NAT |
| **ecr/** | main.tf, variables.tf, outputs.tf | ECR repository, image scanning, lifecycle policy |
| **alb/** | main.tf, variables.tf, outputs.tf, README.md | ALB (internet-facing), security group (80/443), target group (IP-based), HTTP listener, conditional HTTPS listener (TLS 1.3) |

### 2.2 Compute & Application

| Module | Files | Resources Created |
|--------|-------|-------------------|
| **ecs/** | main.tf, autoscaling.tf, variables.tf, outputs.tf | ECS cluster (Container Insights), Fargate task definition, ECS service, IAM execution/task roles, CloudWatch log group, security group, auto-scaling target + CPU/memory/ALB-request policies |
| **sidekiq/** | main.tf, variables.tf, outputs.tf | Fargate task definition (custom command), ECS service (no ALB), deployment circuit breaker |
| **scheduled-tasks/** | main.tf, variables.tf, outputs.tf | ECS task definition (rake-runner), EventBridge Scheduler schedules (one per task), IAM roles for scheduler + task execution, CloudWatch log group |

### 2.3 Data Stores

| Module | Files | Resources Created |
|--------|-------|-------------------|
| **rds/** | main.tf, variables.tf, outputs.tf | DB subnet group, security group (5432 from ECS), RDS PostgreSQL instance (gp3, encrypted, enhanced monitoring, Performance Insights), random password, SSM parameters (`db_password`, `DATABASE_URL`), IAM monitoring role |
| **redis/** | main.tf, variables.tf, outputs.tf | ElastiCache subnet group, security group (6379 from ECS), Redis replication group (encryption at rest/transit, optional auth token), SSM parameter (`REDIS_URL`) |

### 2.4 Operations

| Module | Files | Resources Created |
|--------|-------|-------------------|
| **monitoring/** | main.tf, variables.tf, outputs.tf | SNS topic + email subscription, 10 CloudWatch alarms (ALB 5xx target/ELB, unhealthy hosts, response time; ECS CPU/memory/running tasks; RDS CPU/storage/connections/memory), EventBridge rule for ECS scaling events → SNS |
| **codepipeline/** | main.tf, variables.tf, outputs.tf | S3 artifact bucket (KMS encrypted, public access blocked), CodeBuild project (privileged Docker, buildspec.yml), CodePipeline (Source→Build→Deploy), IAM roles for CodeBuild + CodePipeline |
| **github-oidc/** | (empty) | GitHub OIDC provider for GitHub Actions |

---

## 3. Root Variables (all from `variables.tf`)

### AWS & Project
| Variable | Type | Default | Required |
|----------|------|---------|----------|
| `aws_region` | string | — | Yes |
| `project_name` | string | — | Yes |
| `availability_zones` | list(string) | `["us-east-1a", "us-east-1b"]` | No |

### Networking
| Variable | Type | Default |
|----------|------|---------|
| `vpc_cidr` | string | `10.0.0.0/16` |
| `public_subnet_cidrs` | list(string) | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | list(string) | `["10.0.11.0/24", "10.0.12.0/24"]` |

### Container & Web Service
| Variable | Type | Default | Required |
|----------|------|---------|----------|
| `container_image` | string | — | Yes |
| `container_port` | number | `80` | No |
| `web_task_cpu` | string | `"256"` | No |
| `web_task_memory` | string | `"512"` | No |
| `web_desired_count` | number | `1` | No |
| `certificate_arn` | string | `null` | No |
| `environment_variables` | map(string) | `{}` | No |
| `secrets` | list(object) | `[]` | No |

### Sidekiq
| Variable | Type | Default |
|----------|------|---------|
| `sidekiq_task_cpu` | string | `"256"` |
| `sidekiq_task_memory` | string | `"512"` |
| `sidekiq_desired_count` | number | `1` |
| `sidekiq_command` | list(string) | `["bundle", "exec", "sidekiq"]` |

### RDS PostgreSQL
| Variable | Type | Default |
|----------|------|---------|
| `postgres_version` | string | `"15.4"` |
| `rds_instance_class` | string | `"db.t4g.micro"` |
| `rds_allocated_storage` | number | `20` |
| `rds_max_allocated_storage` | number | `0` (disabled) |
| `database_name` | string | `"crema_production"` |
| `database_username` | string | `"crema_admin"` |
| `rds_backup_retention_period` | number | `7` |
| `rds_multi_az` | bool | `false` |
| `rds_deletion_protection` | bool | `false` |
| `rds_skip_final_snapshot` | bool | `false` |

### Redis
| Variable | Type | Default |
|----------|------|---------|
| `redis_version` | string | `"7.0"` |
| `redis_node_type` | string | `"cache.t4g.micro"` |
| `redis_num_cache_nodes` | number | `1` |
| `redis_snapshot_retention_limit` | number | `5` |
| `redis_multi_az_enabled` | bool | `false` |

### Scheduled Tasks
| Variable | Type | Default |
|----------|------|---------|
| `scheduled_tasks` | list(object{name, schedule_expression, command, enabled}) | `[]` |

### Auto-Scaling (Web)
| Variable | Type | Default |
|----------|------|---------|
| `web_enable_autoscaling` | bool | `false` |
| `web_autoscaling_min_capacity` | number | `1` |
| `web_autoscaling_max_capacity` | number | `4` |
| `web_autoscaling_cpu_enabled` | bool | `true` |
| `web_autoscaling_cpu_target` | number | `70` |
| `web_autoscaling_memory_enabled` | bool | `false` |
| `web_autoscaling_memory_target` | number | `80` |
| `web_autoscaling_scale_in_cooldown` | number | `300` |
| `web_autoscaling_scale_out_cooldown` | number | `60` |

### Monitoring & Logging
| Variable | Type | Default | Required |
|----------|------|---------|----------|
| `alert_email` | string | — | Yes |
| `log_retention_days` | number | `7` | No |

### CI/CD (CodePipeline)
| Variable | Type | Default |
|----------|------|---------|
| `enable_codepipeline` | bool | `false` |
| `codestar_connection_arn` | string | `""` |
| `github_repo_id` | string | `""` |
| `github_branch` | string | `"main"` |
| `dockerfile_path` | string | `"Dockerfile"` |

---

## 4. Root Outputs (from `outputs.tf`)

| Output | Description |
|--------|-------------|
| `alb_dns_name` | DNS name of the ALB — access your app here |
| `ecr_repository_url` | ECR URL — push Docker images here |
| `ecs_cluster_name` | ECS cluster name |
| `ecs_service_name` | ECS web service name |
| `vpc_id` | VPC ID |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_ip` | NAT Gateway Elastic IP |
| `rds_endpoint` | RDS PostgreSQL endpoint |
| `rds_database_name` | RDS database name |

---

## 5. Environment Configurations

### terraform.tfvars variants

| File | Environment | Key Differences |
|------|-------------|-----------------|
| `terraform.tfvars.example` | Template | All 50+ vars documented with Fargate CPU/memory table |
| `terraform.tfvars.dev` | Development | project=`crema`, web 1vCPU/2GB, RDS db.t4g.small/20GB, autoscaling OFF, 10 scheduled tasks ENABLED |
| `terraform.tfvars.prod` | Production | project=`crema-prod`, web 1vCPU/2GB, RDS db.m6g.large/50GB, autoscaling ON (1-3), 10 scheduled tasks DISABLED |

### Scheduled Tasks (10 total, from tfvars)

| Task Name | Schedule | Command |
|-----------|----------|---------|
| process-brewlists | Daily 08:00 UTC | `rake crema:process_brewlists` |
| process-next-up | Daily 17:00 UTC | `rake crema:process_next_up` |
| daily-run | Daily 06:00 UTC | `rake crema:daily_run` |
| process-workplace-playlists | (defined in tfvars) | `rake crema:process_workplace_playlists` |
| + 6 more | Various cron schedules | Various rake tasks |

### Environment Files

| File | Purpose | Content |
|------|---------|---------|
| `dev.env` | Dev secrets | 60+ env vars (API keys, DB URLs, Stripe test keys, Slack tokens, etc.) |
| `prod.env` | Prod secrets | 50+ env vars (production API keys, Stripe live keys, etc.) |

---

## 6. Automation Scripts (Windows .bat)

| Script | Purpose | Usage |
|--------|---------|-------|
| `generate-secrets-config.bat` | Reads .env, generates `secrets = [...]` block for terraform.tfvars with SSM ARNs | `generate-secrets-config.bat dev.env ACCOUNT_ID us-east-1` |
| `load-env-to-ssm.bat` | Batch uploads env vars from .env to SSM Parameter Store (`/crema/` prefix) | `load-env-to-ssm.bat dev.env us-east-1` |
| `generate-secrets-config-prod.bat` | Same as above for prod (`/crema-prod/` prefix) | `generate-secrets-config-prod.bat prod.env ACCOUNT_ID` |
| `load-env-to-ssm-prod.bat` | Same as above for prod (`/crema-prod/` prefix) | `load-env-to-ssm-prod.bat prod.env us-east-1` |

All scripts skip `DATABASE_URL`, `REDIS_URL`, and other DB-related vars (Terraform creates those automatically).

---

## 7. Documentation Files

| File | Content Summary |
|------|-----------------|
| `README.md` | Project overview, architecture diagram, quick start, prerequisites, configuration guide, deployment steps, troubleshooting, cost estimation, security best practices |
| `docs/FARGATE_SIZING.md` | Complete Fargate CPU/memory combinations table, cost per tier, use cases per size, monitoring & optimization tips |
| `docs/buildspec.yml.example` | CodeBuild buildspec: ECR login → Docker build → push → generate imagedefinitions.json → force Sidekiq redeploy |
| `AUTOSCALING_EXAMPLE.md` | Auto-scaling configuration walkthrough, scaling scenarios, cost implications |
| `MULTI_AZ_MIGRATION.md` | Documents the migration from single-AZ to multi-AZ: variable changes, module updates, root module updates |
| `modules/alb/README.md` | ALB module docs: resources created, HTTP/HTTPS listener behavior, usage examples with/without HTTPS, health check config |
| `modules/README.md` | (placeholder) |

---

## 8. Example Configurations (`examples/`)

| Example | Estimated Cost | Key Features |
|---------|---------------|--------------|
| `minimal-deployment/` | ~$58/month | 1 task, HTTP only, no secrets, defaults everywhere |
| `production-deployment/` | ~$170-200/month | 3 tasks, HTTPS + ACM cert, secrets, 1vCPU/2GB, custom VPC CIDR |
| `custom-network/` | Varies | Custom VPC/subnet CIDRs for peering/VPN scenarios |
| `examples/README.md` | — | Comparison matrix, Fargate pricing reference, customization guide |

---

## 9. Specification Files (`.kiro/specs/modular-terraform-ecs-infrastructure/`)

| File | Content |
|------|---------|
| `requirements.md` | 12 formal requirements with user stories and acceptance criteria (VPC, NAT, ECR, ECS, IAM, ALB, security groups, modularity, networking, logging, outputs, state management) |
| `design.md` | Architecture diagrams (Mermaid), module interfaces (inputs/outputs), data models, traffic flow, security architecture, implementation details |
| `tasks.md` | 17 implementation tasks with checkpoints, requirement traceability, property test definitions |

---

## 10. Test & Verification Files (`test/`)

### Syntax Test Configs
| Directory | Tests |
|-----------|-------|
| `test/vpc_module_test/` | VPC module syntax validation |
| `test/ecr_syntax_test/` | ECR module syntax validation |
| `test/alb_syntax_test/` | ALB module syntax validation |
| `test/ecs_syntax_test/` | ECS module syntax validation |
| `test/ecr_alb_checkpoint/` | ECR + ALB integration checkpoint |

### Verification Reports
| File | Checkpoint |
|------|-----------|
| `test/CHECKPOINT_7_VERIFICATION.md` | ECR + ALB modules verified |
| `test/CHECKPOINT_12_VERIFICATION.md` | ECS module verified |
| `test/TASK_8.1_VERIFICATION.md` through `test/TASK_15.2_VERIFICATION.md` | Individual task verifications |
| `test/TASK_17_FINAL_CHECKPOINT_VERIFICATION.md` | Final infrastructure validation |

---

## 11. Architecture Overview

```
Internet
    │
    ▼
ALB (Public Subnets, multi-AZ)  ──── HTTPS/HTTP listeners
    │
    ▼
ECS Fargate Web Service (Private Subnets, multi-AZ)
    │                    │
    │                    ├── RDS PostgreSQL (Private Subnets)
    │                    ├── ElastiCache Redis (Private Subnets)
    │                    └── NAT Gateway → Internet Gateway → Internet
    │
    ├── Sidekiq Service (same cluster, no ALB)
    └── Scheduled Tasks (EventBridge → ECS RunTask)

Monitoring: CloudWatch Alarms → SNS → Email
CI/CD: GitHub → CodePipeline → CodeBuild → ECR → ECS Deploy
Secrets: SSM Parameter Store (loaded via .bat scripts)
```

---

## 12. AWS Services Used

VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables, Security Groups, ALB, Target Groups, ECS (Fargate), ECR, RDS (PostgreSQL), ElastiCache (Redis), CloudWatch (Logs + Alarms + Container Insights), IAM (Roles + Policies), SSM Parameter Store, SNS, EventBridge Scheduler, CodePipeline, CodeBuild, CodeStar Connections, S3 (artifacts), KMS

---

## 13. Cost Estimates

| Environment | Monthly Cost |
|-------------|-------------|
| Dev (terraform.tfvars.dev) | ~$90-120 |
| Production (terraform.tfvars.prod) | ~$170-200 |
| Minimal example | ~$58 |

---

## 14. Files NOT to Include in Documentation (sensitive/generated)

| File | Reason |
|------|--------|
| `dev.env` / `prod.env` | Contains real API keys and secrets |
| `secrets.txt` | Secrets file |
| `terraform.tfstate` / `terraform.tfstate.backup` | State files with resource IDs |
| `prod.tfplan` | Plan output |
| `.terraform/` directories | Provider binaries |
| `.terraform.lock.hcl` | Lock files (auto-generated) |
