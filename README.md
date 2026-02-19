# Crema ECS Infrastructure

Terraform infrastructure for deploying the Crema Rails application on AWS ECS Fargate. This repo manages the complete production environment including networking, database, caching, background jobs, scheduled tasks, monitoring, and CI/CD.

## Architecture

```
Internet
    │
    ▼
Application Load Balancer (Public Subnets - us-east-1a, us-east-1b)
    │                                         │
    ▼                                         ▼
┌─────────────────────┐    ┌──────────────────────────────────┐
│  ECS Web Service    │    │  Private Subnets                  │
│  (Fargate, 2 tasks) │    │  ├── RDS PostgreSQL 15            │
│  Rails + Puma       │    │  ├── ElastiCache Redis 7.0        │
│  Port 3000          │    │  ├── Sidekiq Service (1 task)     │
└─────────────────────┘    │  └── Scheduled Rake Tasks         │
    │                      └──────────────────────────────────┘
    ▼
NAT Gateway (Public Subnet) → Internet Gateway → Internet
```

## What Gets Deployed

| Module | Resources | Purpose |
|--------|-----------|---------|
| VPC | VPC, 2 public + 2 private subnets, route tables, IGW | Multi-AZ networking |
| NAT | NAT Gateway, Elastic IP | Private subnet internet access |
| ALB | Application Load Balancer, target group, listeners | HTTPS traffic distribution |
| ECR | Container registry with lifecycle policy | Docker image storage |
| ECS | Fargate cluster, web service, task definitions, auto-scaling | Runs the Rails app |
| Sidekiq | Fargate service, task definition | Background job processing |
| RDS | PostgreSQL 15 instance, security group, subnet group | Application database |
| Redis | ElastiCache replication group | Caching and Sidekiq backend |
| Scheduled Tasks | EventBridge Scheduler, task definitions | Cron-based rake tasks |
| Monitoring | CloudWatch alarms, SNS topic | Alerts for ALB, ECS, RDS |
| CodePipeline | Pipeline, CodeBuild project, IAM roles, S3 artifacts | CI/CD from GitHub |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- S3 bucket for Terraform state (e.g., `crema-terraform-state-prod`)
- CodeStar connection to GitHub in "Available" status
- ACM certificate for your domain (for HTTPS)
- Application secrets loaded into SSM Parameter Store

## File Structure

```
├── main.tf                      # Root module - wires all modules together
├── variables.tf                 # All input variable definitions
├── outputs.tf                   # Terraform outputs (ALB DNS, ECR URL, etc.)
├── backend.tf                   # S3 backend config (not in git)
├── backend.tf.example           # Backend template
├── terraform.tfvars             # Your config values (not in git)
├── terraform.tfvars.example     # Full annotated example config
├── modules/
│   ├── vpc/                     # VPC, subnets, route tables
│   ├── nat/                     # NAT Gateway + Elastic IP
│   ├── alb/                     # Load balancer, target group, listeners
│   ├── ecr/                     # Container registry
│   ├── ecs/                     # ECS cluster, web service, auto-scaling
│   ├── sidekiq/                 # Sidekiq background worker service
│   ├── rds/                     # PostgreSQL database
│   ├── redis/                   # ElastiCache Redis
│   ├── scheduled-tasks/         # EventBridge scheduled rake tasks
│   ├── monitoring/              # CloudWatch alarms + SNS
│   └── codepipeline/            # CI/CD pipeline
├── docs/
│   ├── buildspec.yml.example    # CodeBuild buildspec (copy to app repo)
│   └── FARGATE_SIZING.md        # CPU/memory sizing guide
├── examples/                    # Example tfvars for different scenarios
├── load-env-to-ssm.bat          # Load .env secrets to SSM Parameter Store
├── generate-secrets-config.bat  # Generate secrets block for tfvars
└── test/                        # Syntax validation tests
```

## Getting Started

### 1. Configure Backend

```bash
copy backend.tf.example backend.tf
```

Edit `backend.tf` with your S3 bucket name:

```hcl
terraform {
  backend "s3" {
    bucket  = "crema-terraform-state-prod"
    key     = "ecs-infrastructure/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

### 2. Configure Variables

```bash
copy terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values. See `terraform.tfvars.example` for a fully annotated reference. Key settings:

```hcl
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
project_name       = "crema-prod"
container_image    = "<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/crema-prod-app:latest"
container_port     = 3000
certificate_arn    = "arn:aws:acm:us-east-1:<ACCOUNT_ID>:certificate/<CERT_ID>"
alert_email        = "your-email@example.com"
```

### 3. Load Secrets to SSM

Before deploying, load your application secrets into SSM Parameter Store:

```bash
load-env-to-ssm.bat prod.env us-east-1
```

Then generate the `secrets` block for your tfvars:

```bash
generate-secrets-config.bat prod.env <ACCOUNT_ID> us-east-1
```

Paste the output into `terraform.tfvars` under the `secrets` variable.

### 4. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 5. Push Docker Image to ECR

After the first deploy, push your Docker image:

```bash
# Authenticate
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t crema-prod-app:latest -f Dockerfile.prod .
docker tag crema-prod-app:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/crema-prod-app:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/crema-prod-app:latest

# Force ECS to pull the new image
aws ecs update-service --cluster crema-prod-cluster --service crema-prod-web-service --force-new-deployment --region us-east-1
```

## CI/CD Pipeline (CodePipeline)

When enabled, CodePipeline automates deployments on every push to the configured branch.

### How It Works

1. **Source** — Pulls code from GitHub via CodeStar connection
2. **Build** — CodeBuild builds the Docker image using `buildspec.yml` and pushes to ECR
3. **Deploy** — ECS rolling deployment updates the web service; Sidekiq is force-redeployed during build

### Setup

1. Create a CodeStar connection in the AWS Console (Developer Tools → Connections)
2. Authorize it with your GitHub account and confirm status is "Available"
3. Add the `buildspec.yml` to your application repo root (see `docs/buildspec.yml.example`)
4. Add these variables to `terraform.tfvars`:

```hcl
enable_codepipeline     = true
codestar_connection_arn = "arn:aws:codeconnections:us-east-1:<ACCOUNT_ID>:connection/<CONNECTION_ID>"
github_repo_id          = "YourOrg/your-repo"
github_branch           = "master-aws"
dockerfile_path         = "Dockerfile.prod"
```

5. Run `terraform apply`

### Important Notes

- CodePipeline triggers automatically on creation (first run pulls latest from the branch)
- To prevent the initial deployment from affecting running tasks, stop the pipeline execution in the AWS Console immediately after `terraform apply`
- Subsequent runs only trigger on new pushes to the configured branch
- The `buildspec.yml` must exist in the root of your application repository

## Scheduled Tasks

Rake tasks are run via EventBridge Scheduler on ECS Fargate. Configure them in `terraform.tfvars`:

```hcl
scheduled_tasks = [
  {
    name                = "daily-run"
    schedule_expression = "cron(0 6 * * ? *)"
    command             = ["bundle", "exec", "rake", "crema:daily_run"]
    enabled             = true
  }
]
```

Each task runs as a standalone Fargate task using the same container image and secrets as the web service.

## Auto-Scaling

The web service supports target-tracking auto-scaling based on CPU and memory utilization:

```hcl
web_enable_autoscaling         = true
web_autoscaling_min_capacity   = 2
web_autoscaling_max_capacity   = 4
web_autoscaling_cpu_target     = 80
web_autoscaling_memory_target  = 80
```

## Monitoring

CloudWatch alarms are configured for:

- ALB 5xx errors (target and ELB)
- ALB high response time
- ALB unhealthy hosts
- ECS high CPU / memory utilization
- ECS no running tasks
- RDS high CPU / low memory / low storage / high connections
- ECS scaling events

Alerts are sent to the SNS topic subscribed to `alert_email`. Confirm the subscription email after first deploy.

## Outputs

After deployment:

```bash
terraform output alb_dns_name           # Application URL
terraform output ecr_repository_url     # ECR push target
terraform output rds_endpoint           # Database endpoint
terraform output redis_endpoint         # Redis endpoint
terraform output pipeline_name          # CodePipeline name (if enabled)
```

## Common Operations

### Force New Deployment (no code change)

```bash
aws ecs update-service --cluster crema-prod-cluster --service crema-prod-web-service --force-new-deployment --region us-east-1
```

### View Container Logs

```bash
aws logs tail /ecs/crema-prod-web-service --follow --region us-east-1
```

### Check Target Health

```bash
aws elbv2 describe-target-health --target-group-arn <TG_ARN> --region us-east-1
```

### Scale Manually

Update `web_desired_count` in `terraform.tfvars` and run `terraform apply`, or:

```bash
aws ecs update-service --cluster crema-prod-cluster --service crema-prod-web-service --desired-count 3 --region us-east-1
```

### Destroy Infrastructure

```bash
# Delete ECR images first (required if repo has images)
aws ecr delete-repository --repository-name crema-prod-app --force --region us-east-1

terraform destroy
```

**Warning**: If RDS has `deletion_protection = true`, you must disable it first via the AWS Console or by setting `rds_deletion_protection = false` and running `terraform apply` before destroy.

## Multi-Environment Usage

This repo supports multiple environments by swapping `backend.tf` and `terraform.tfvars`:

```bash
# Switch to dev
copy backend.tf.dev backend.tf
copy terraform.tfvars.dev terraform.tfvars
terraform init -reconfigure

# Switch back to prod
copy backend.tf.prod backend.tf
copy terraform.tfvars.prod terraform.tfvars
terraform init -reconfigure
```

Each environment uses a separate S3 state bucket and AWS account/credentials.

## Fargate Sizing Reference

| CPU (vCPU) | Valid Memory Range |
|------------|-------------------|
| 256 (0.25) | 512, 1024, 2048 MB |
| 512 (0.5)  | 1024 – 4096 MB |
| 1024 (1)   | 2048 – 8192 MB |
| 2048 (2)   | 4096 – 16384 MB |
| 4096 (4)   | 8192 – 30720 MB |

See `docs/FARGATE_SIZING.md` for detailed guidance.

## Security Notes

- `terraform.tfvars`, `backend.tf`, `*.env`, and `*.tfstate` are gitignored — never commit these
- All secrets are stored in SSM Parameter Store and referenced by ARN
- ECS tasks run in private subnets with no public IPs
- RDS and Redis are only accessible from ECS security groups
- S3 artifact bucket has public access blocked and KMS encryption
- IAM roles follow least-privilege principles

## Cost Estimate (Monthly, us-east-1)

| Resource | Configuration | Approx. Cost |
|----------|--------------|-------------|
| NAT Gateway | 1 gateway | ~$32 |
| ALB | 1 load balancer | ~$16 |
| ECS Web | 2 tasks × 2 vCPU / 14 GB | ~$170 |
| ECS Sidekiq | 1 task × 1 vCPU / 2 GB | ~$36 |
| RDS | db.t4g.medium, 50 GB | ~$55 |
| Redis | cache.t4g.micro | ~$12 |
| CloudWatch | Logs + alarms | ~$5 |
| CodePipeline | 1 pipeline | ~$1 |
| **Total (2 web tasks)** | | **~$400/month** |
| **Total (4 web tasks, max auto-scale)** | | **~$611/month** |

Costs vary by usage and data transfer. Use the [AWS Pricing Calculator](https://calculator.aws/) for precise estimates.
