# Minimal Deployment Example

This example demonstrates the simplest possible deployment with only required parameters.

## Configuration

- **Environment**: Development/Testing
- **High Availability**: No (single task)
- **HTTPS**: No (HTTP only)
- **Custom Network**: No (uses defaults)
- **Environment Variables**: None
- **Secrets**: None

## Resources Created

- VPC with default CIDR (10.0.0.0/16)
- Public subnet (10.0.1.0/24) with ALB and NAT Gateway
- Private subnet (10.0.2.0/24) with ECS tasks
- Application Load Balancer (HTTP only)
- ECS Cluster with 1 task (0.25 vCPU, 512 MB memory)
- ECR Repository
- CloudWatch Log Group

## Estimated Monthly Cost

- NAT Gateway: ~$32
- ALB: ~$16
- Fargate (1 task, 0.25 vCPU, 512 MB): ~$10
- **Total**: ~$58/month (excluding data transfer)

## Usage

1. Copy the root module files to a new directory
2. Copy this `terraform.tfvars` file to the root directory
3. Update `container_image` with your ECR repository URL
4. Deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Accessing Your Application

After deployment, get the ALB DNS name:
```bash
terraform output alb_dns_name
```

Access your application at: `http://<alb-dns-name>`

## Pushing Your Docker Image

1. Get ECR repository URL:
   ```bash
   terraform output ecr_repository_url
   ```

2. Authenticate Docker to ECR:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   ```

3. Build and push your image:
   ```bash
   docker build -t minimal-app .
   docker tag minimal-app:latest <ecr-repository-url>:latest
   docker push <ecr-repository-url>:latest
   ```

4. Update ECS service to use new image:
   ```bash
   aws ecs update-service --cluster minimal-app-cluster --service minimal-app-service --force-new-deployment --region us-east-1
   ```
