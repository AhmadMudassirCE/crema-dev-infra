# Modular Terraform ECS Infrastructure

A production-ready, modular Terraform infrastructure solution for deploying Docker applications on AWS ECS with proper networking, load balancing, and security.

## Overview

This infrastructure deploys a complete AWS environment with:

- **VPC** with public and private subnets in a single availability zone
- **NAT Gateway** for private subnet internet access
- **ECR Repository** for Docker image storage
- **Application Load Balancer** (ALB) in public subnet for internet-facing traffic
- **ECS Fargate Cluster** in private subnet for running containerized applications
- **CloudWatch Logs** for container logging
- **IAM Roles** with least-privilege permissions
- **Security Groups** following AWS best practices

### Architecture

```
Internet
   ↓
Application Load Balancer (Public Subnet)
   ↓
ECS Fargate Tasks (Private Subnet)
   ↓
NAT Gateway (Public Subnet) → Internet Gateway → Internet
```

**Key Features:**
- Modular design with reusable components
- Secure by default with proper network isolation
- Configurable parameters for different environments
- Support for environment variables and secrets
- HTTPS support with SSL certificates
- Comprehensive CloudWatch logging

## Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [Docker](https://www.docker.com/get-started) for building and pushing images

### AWS Account Requirements

You need an AWS account with appropriate permissions. See [Required AWS Permissions](#required-aws-permissions) below.

### AWS Service Limits

Ensure your AWS account has sufficient limits for:
- VPCs (default: 5 per region)
- Elastic IPs (default: 5 per region)
- ECS Clusters (default: 10,000 per region)
- Application Load Balancers (default: 50 per region)

## Quick Start

### 1. Clone and Configure

```bash
# Clone the repository (or copy the files)
cd terraform-ecs-infrastructure

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings
# At minimum, update: aws_region, project_name, container_image
```

### 2. Push Docker Image to ECR

Before deploying, you need to push your Docker image to ECR:

```bash
# Initialize Terraform to create the ECR repository
terraform init
terraform apply -target=module.ecr

# Get the ECR repository URL from output
ECR_URL=$(terraform output -raw ecr_repository_url)
echo "ECR Repository: $ECR_URL"

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Build your Docker image
docker build -t myapp:latest .

# Tag the image for ECR
docker tag myapp:latest $ECR_URL:latest

# Push to ECR
docker push $ECR_URL:latest

# Update terraform.tfvars with the ECR image URL
# container_image = "<ECR_URL>:latest"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply

# Note the ALB DNS name from outputs
```

### 4. Access Your Application

After deployment completes, access your application using the ALB DNS name:

```bash
# Get the ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Application URL: http://$ALB_DNS"

# Test the application
curl http://$ALB_DNS
```

**Note:** It may take 2-3 minutes for the ECS tasks to start and pass health checks before the application is accessible.

## Configuration

### Required Variables

Edit `terraform.tfvars` and set these required variables:

```hcl
aws_region        = "us-east-1"        # AWS region for deployment
availability_zone = "us-east-1a"       # Availability zone for subnets
project_name      = "myapp"            # Project name for resource naming
container_image   = "<ECR_URL>:latest" # Docker image URL from ECR
```

### Optional Variables

```hcl
# Network Configuration (defaults provided)
vpc_cidr            = "10.0.0.0/16"    # VPC CIDR block
public_subnet_cidr  = "10.0.1.0/24"    # Public subnet CIDR
private_subnet_cidr = "10.0.2.0/24"    # Private subnet CIDR

# Container Configuration
container_port = 80                     # Port your container listens on

# ECS Task Configuration
task_cpu    = "256"                     # CPU units (256, 512, 1024, 2048, 4096)
task_memory = "512"                     # Memory in MB (see valid combinations below)

# Service Configuration
desired_count = 2                       # Number of tasks to run

# SSL Certificate (for HTTPS)
certificate_arn = "arn:aws:acm:..."    # ACM certificate ARN (optional)

# Environment Variables
environment_variables = {
  LOG_LEVEL = "info"
  APP_ENV   = "production"
}

# Secrets (from AWS Secrets Manager or SSM Parameter Store)
secrets = [
  {
    name      = "DATABASE_PASSWORD"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:name"
  }
]
```

### Valid Fargate CPU/Memory Combinations

| CPU (units) | Memory (MB) |
|-------------|-------------|
| 256         | 512, 1024, 2048 |
| 512         | 1024, 2048, 3072, 4096 |
| 1024        | 2048, 3072, 4096, 5120, 6144, 7168, 8192 |
| 2048        | 4096 to 16384 (in 1024 MB increments) |
| 4096        | 8192 to 30720 (in 1024 MB increments) |

## Required AWS Permissions

The AWS user or role running Terraform needs the following permissions:

### VPC and Networking
- `ec2:CreateVpc`, `ec2:DeleteVpc`, `ec2:DescribeVpcs`
- `ec2:CreateSubnet`, `ec2:DeleteSubnet`, `ec2:DescribeSubnets`
- `ec2:CreateInternetGateway`, `ec2:DeleteInternetGateway`, `ec2:AttachInternetGateway`, `ec2:DetachInternetGateway`
- `ec2:CreateRouteTable`, `ec2:DeleteRouteTable`, `ec2:DescribeRouteTables`
- `ec2:CreateRoute`, `ec2:DeleteRoute`
- `ec2:AssociateRouteTable`, `ec2:DisassociateRouteTable`
- `ec2:AllocateAddress`, `ec2:ReleaseAddress`, `ec2:DescribeAddresses`
- `ec2:CreateNatGateway`, `ec2:DeleteNatGateway`, `ec2:DescribeNatGateways`

### Security Groups
- `ec2:CreateSecurityGroup`, `ec2:DeleteSecurityGroup`, `ec2:DescribeSecurityGroups`
- `ec2:AuthorizeSecurityGroupIngress`, `ec2:RevokeSecurityGroupIngress`
- `ec2:AuthorizeSecurityGroupEgress`, `ec2:RevokeSecurityGroupEgress`
- `ec2:CreateTags`, `ec2:DeleteTags`, `ec2:DescribeTags`

### ECR
- `ecr:CreateRepository`, `ecr:DeleteRepository`, `ecr:DescribeRepositories`
- `ecr:PutLifecyclePolicy`, `ecr:GetLifecyclePolicy`
- `ecr:PutImageScanningConfiguration`
- `ecr:GetAuthorizationToken` (for pushing images)
- `ecr:BatchCheckLayerAvailability`, `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage` (for pulling images)

### Application Load Balancer
- `elasticloadbalancing:CreateLoadBalancer`, `elasticloadbalancing:DeleteLoadBalancer`, `elasticloadbalancing:DescribeLoadBalancers`
- `elasticloadbalancing:CreateTargetGroup`, `elasticloadbalancing:DeleteTargetGroup`, `elasticloadbalancing:DescribeTargetGroups`
- `elasticloadbalancing:CreateListener`, `elasticloadbalancing:DeleteListener`, `elasticloadbalancing:DescribeListeners`
- `elasticloadbalancing:ModifyLoadBalancerAttributes`, `elasticloadbalancing:ModifyTargetGroupAttributes`
- `elasticloadbalancing:AddTags`, `elasticloadbalancing:RemoveTags`

### ECS
- `ecs:CreateCluster`, `ecs:DeleteCluster`, `ecs:DescribeClusters`
- `ecs:RegisterTaskDefinition`, `ecs:DeregisterTaskDefinition`, `ecs:DescribeTaskDefinition`
- `ecs:CreateService`, `ecs:DeleteService`, `ecs:DescribeServices`, `ecs:UpdateService`
- `ecs:RunTask`, `ecs:StopTask`, `ecs:DescribeTasks`

### IAM
- `iam:CreateRole`, `iam:DeleteRole`, `iam:GetRole`
- `iam:AttachRolePolicy`, `iam:DetachRolePolicy`
- `iam:PutRolePolicy`, `iam:DeleteRolePolicy`, `iam:GetRolePolicy`
- `iam:PassRole` (for ECS task execution)
- `iam:CreatePolicy`, `iam:DeletePolicy` (if creating custom policies)

### CloudWatch Logs
- `logs:CreateLogGroup`, `logs:DeleteLogGroup`, `logs:DescribeLogGroups`
- `logs:PutRetentionPolicy`
- `logs:CreateLogStream`, `logs:PutLogEvents` (for ECS tasks)

### Secrets Manager / SSM (if using secrets)
- `secretsmanager:GetSecretValue` (for Secrets Manager)
- `ssm:GetParameters` (for SSM Parameter Store)

### Example IAM Policy

See `examples/terraform-deployment-policy.json` for a complete IAM policy that grants all required permissions.

## Pushing Docker Images to ECR

### Initial Setup

1. **Create ECR repository** (done automatically by Terraform):
   ```bash
   terraform apply -target=module.ecr
   ```

2. **Get repository URL**:
   ```bash
   ECR_URL=$(terraform output -raw ecr_repository_url)
   ```

3. **Authenticate Docker to ECR**:
   ```bash
   aws ecr get-login-password --region <your-region> | \
     docker login --username AWS --password-stdin $ECR_URL
   ```

### Building and Pushing Images

```bash
# Build your Docker image
docker build -t myapp:latest .

# Tag for ECR
docker tag myapp:latest $ECR_URL:latest

# Push to ECR
docker push $ECR_URL:latest

# Optional: Tag with version
docker tag myapp:latest $ECR_URL:v1.0.0
docker push $ECR_URL:v1.0.0
```

### Updating the Application

After pushing a new image:

```bash
# Update the ECS service to use the new image
# Option 1: Update terraform.tfvars with new image tag and apply
terraform apply

# Option 2: Force new deployment without changing image tag
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

## Accessing the Application

### Via Application Load Balancer

The application is accessible through the ALB DNS name:

```bash
# Get the ALB DNS name
terraform output alb_dns_name

# Access via HTTP
curl http://<alb-dns-name>

# If HTTPS is configured
curl https://<alb-dns-name>
```

### Custom Domain (Optional)

To use a custom domain:

1. Create a Route 53 hosted zone for your domain
2. Create an A record (alias) pointing to the ALB DNS name
3. Request an ACM certificate for your domain
4. Update `terraform.tfvars` with the certificate ARN
5. Apply the changes: `terraform apply`

### Health Checks

The ALB performs health checks on the path `/` (configurable). Ensure your application responds with HTTP 200 on the health check path.

### Troubleshooting Access Issues

If you cannot access the application:

1. **Check ECS task status**:
   ```bash
   aws ecs describe-services \
     --cluster $(terraform output -raw ecs_cluster_name) \
     --services $(terraform output -raw ecs_service_name)
   ```

2. **Check task health**:
   ```bash
   aws ecs list-tasks \
     --cluster $(terraform output -raw ecs_cluster_name) \
     --service-name $(terraform output -raw ecs_service_name)
   ```

3. **Check ALB target health**:
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn <target-group-arn>
   ```

4. **Check container logs**:
   ```bash
   aws logs tail /ecs/$(terraform output -raw ecs_service_name) --follow
   ```

## Terraform State Management

### Local State (Development)

By default, Terraform stores state locally in `terraform.tfstate`. This is suitable for:
- Individual development
- Testing and experimentation
- Single-user environments

**Pros:**
- Simple setup, no additional configuration
- Fast operations

**Cons:**
- No collaboration support
- No state locking
- Risk of state file loss
- No state versioning

### Remote State (Production)

For team environments and production deployments, use remote state with S3 backend.

#### Setting Up Remote State

1. **Create S3 bucket for state storage**:
   ```bash
   aws s3api create-bucket \
     --bucket my-terraform-state-bucket \
     --region us-east-1
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket my-terraform-state-bucket \
     --versioning-configuration Status=Enabled
   
   # Enable encryption
   aws s3api put-bucket-encryption \
     --bucket my-terraform-state-bucket \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "AES256"
         }
       }]
     }'
   ```

2. **Create DynamoDB table for state locking**:
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

3. **Create backend configuration**:
   ```bash
   cp backend.tf.example backend.tf
   # Edit backend.tf with your bucket and table names
   ```

4. **Initialize with remote backend**:
   ```bash
   terraform init -migrate-state
   ```

#### Backend Configuration

See `backend.tf.example` for a complete backend configuration template.

**Pros:**
- Team collaboration with state locking
- State versioning and history
- Encrypted state storage
- Backup and disaster recovery

**Cons:**
- Additional AWS resources required
- Slightly slower operations
- More complex setup

### Switching Between Local and Remote State

**From Local to Remote:**
```bash
# Create backend.tf with S3 configuration
terraform init -migrate-state
```

**From Remote to Local:**
```bash
# Remove or rename backend.tf
mv backend.tf backend.tf.disabled
terraform init -migrate-state
```

## Outputs

After deployment, Terraform provides these outputs:

| Output | Description |
|--------|-------------|
| `alb_dns_name` | DNS name of the ALB - use this to access your application |
| `ecr_repository_url` | ECR repository URL - push your Docker images here |
| `ecs_cluster_name` | Name of the ECS cluster |
| `ecs_service_name` | Name of the ECS service |
| `vpc_id` | ID of the VPC |
| `public_subnet_id` | ID of the public subnet |
| `private_subnet_id` | ID of the private subnet |
| `nat_gateway_ip` | Elastic IP of the NAT Gateway |

View outputs:
```bash
# All outputs
terraform output

# Specific output
terraform output alb_dns_name
```

## Module Structure

```
.
├── main.tf                 # Root module orchestration
├── variables.tf            # Root module variables
├── outputs.tf              # Root module outputs
├── versions.tf             # Terraform and provider versions
├── terraform.tfvars        # Your configuration (not in git)
├── terraform.tfvars.example # Example configuration
├── backend.tf              # Backend configuration (optional)
├── backend.tf.example      # Example backend configuration
├── README.md               # This file
├── modules/
│   ├── vpc/                # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── nat/                # NAT Gateway module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecr/                # ECR module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/                # Application Load Balancer module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── ecs/                # ECS module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── test/                   # Terratest tests
    └── ...
```

## Common Operations

### Updating the Infrastructure

```bash
# Review changes
terraform plan

# Apply changes
terraform apply
```

### Scaling the Application

Update `desired_count` in `terraform.tfvars`:
```hcl
desired_count = 4  # Scale to 4 tasks
```

Then apply:
```bash
terraform apply
```

### Destroying the Infrastructure

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**Warning:** This will delete all resources including the ECR repository and its images.

## Security Best Practices

1. **Never commit sensitive data**:
   - Add `terraform.tfvars` to `.gitignore`
   - Use AWS Secrets Manager or SSM for sensitive values
   - Never hardcode credentials in Terraform files

2. **Use remote state with encryption**:
   - Enable S3 bucket encryption
   - Enable S3 versioning for state history
   - Use DynamoDB for state locking

3. **Restrict IAM permissions**:
   - Use least-privilege IAM policies
   - Avoid using root AWS account
   - Use IAM roles for ECS tasks

4. **Enable HTTPS**:
   - Request ACM certificate for your domain
   - Configure `certificate_arn` in `terraform.tfvars`
   - Redirect HTTP to HTTPS (optional)

5. **Monitor and audit**:
   - Enable CloudWatch Container Insights
   - Review CloudWatch logs regularly
   - Enable AWS CloudTrail for API auditing

## Troubleshooting

### Terraform Errors

**Error: Invalid CIDR block**
- Ensure CIDR blocks are valid IPv4 notation (e.g., `10.0.0.0/16`)
- Ensure subnet CIDRs are within VPC CIDR range
- Ensure subnet CIDRs don't overlap

**Error: Invalid CPU/Memory combination**
- Check the valid combinations table above
- Ensure CPU and memory values are strings (e.g., `"256"`, not `256`)

**Error: State locked**
- Another Terraform process is running
- Wait for it to complete or force unlock: `terraform force-unlock <lock-id>`

### Deployment Issues

**ECS tasks not starting**
- Check CloudWatch logs: `aws logs tail /ecs/<service-name> --follow`
- Verify container image exists in ECR
- Check IAM permissions for task execution role
- Verify CPU/memory limits are sufficient

**Cannot access application via ALB**
- Wait 2-3 minutes for tasks to start and pass health checks
- Check target health: `aws elbv2 describe-target-health --target-group-arn <arn>`
- Verify security group rules allow traffic
- Check container is listening on correct port

**Image pull errors**
- Verify ECR repository URL is correct
- Check task execution role has ECR permissions
- Ensure image exists: `aws ecr describe-images --repository-name <name>`

## Cost Estimation

Approximate monthly costs (us-east-1, as of 2024):

| Resource | Configuration | Estimated Cost |
|----------|--------------|----------------|
| NAT Gateway | 1 gateway | ~$32/month + data transfer |
| Application Load Balancer | 1 ALB | ~$16/month + LCU charges |
| ECS Fargate | 2 tasks (256 CPU, 512 MB) | ~$15/month |
| ECR Storage | 1 GB | ~$0.10/month |
| CloudWatch Logs | 1 GB ingestion | ~$0.50/month |
| **Total** | | **~$64/month** |

**Notes:**
- Costs vary by region and usage
- Data transfer charges apply
- Use [AWS Pricing Calculator](https://calculator.aws/) for accurate estimates

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review [AWS ECS documentation](https://docs.aws.amazon.com/ecs/)
- Review [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Acknowledgments

Built with:
- [Terraform](https://www.terraform.io/)
- [AWS ECS](https://aws.amazon.com/ecs/)
- [AWS Fargate](https://aws.amazon.com/fargate/)
