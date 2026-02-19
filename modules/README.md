# Modules

| Module | Description |
|--------|-------------|
| `vpc` | VPC with public/private subnets across 2 AZs, route tables, internet gateway |
| `nat` | NAT Gateway with Elastic IP for private subnet outbound internet |
| `alb` | Application Load Balancer with HTTP/HTTPS listeners, target group, health checks |
| `ecr` | ECR repository with lifecycle policy (keeps last 10 images) |
| `ecs` | ECS Fargate cluster, web service, task definition, auto-scaling policies |
| `sidekiq` | Sidekiq background worker as a separate ECS Fargate service |
| `rds` | PostgreSQL RDS instance with automated backups, SSM parameter for DATABASE_URL |
| `redis` | ElastiCache Redis replication group, SSM parameter for REDIS_URL |
| `scheduled-tasks` | EventBridge Scheduler for running rake tasks on Fargate |
| `monitoring` | CloudWatch alarms for ALB, ECS, RDS with SNS email notifications |
| `codepipeline` | CodePipeline + CodeBuild for GitHub → ECR → ECS deployments |

All modules are referenced from `main.tf` in the root. Each module has its own `variables.tf` and `outputs.tf`.
