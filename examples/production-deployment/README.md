# Production Deployment Example

This example demonstrates a production-ready deployment with high availability, HTTPS, comprehensive environment configuration, and secrets management.

## Configuration

- **Environment**: Production
- **High Availability**: Yes (3 tasks)
- **HTTPS**: Yes (with ACM certificate)
- **Custom Network**: Yes (custom VPC CIDR)
- **Environment Variables**: Comprehensive configuration
- **Secrets**: Database credentials, API keys, OAuth secrets

## Resources Created

- VPC with custom CIDR (10.1.0.0/16)
- Public subnet (10.1.1.0/24) with ALB and NAT Gateway
- Private subnet (10.1.2.0/24) with ECS tasks
- Application Load Balancer (HTTP + HTTPS)
- ECS Cluster with 3 tasks (1 vCPU, 2 GB memory each)
- ECR Repository
- CloudWatch Log Group
- IAM roles with secrets access

## Estimated Monthly Cost

- NAT Gateway: ~$32
- ALB: ~$16 + LCU charges
- Fargate (3 tasks, 1 vCPU, 2 GB each): ~$120
- Data transfer: Variable
- **Total**: ~$170-200/month (excluding data transfer and LCU charges)

## Prerequisites

### 1. ACM Certificate

Create an SSL certificate in AWS Certificate Manager:

```bash
# Request a certificate for your domain
aws acm request-certificate \
  --domain-name example.com \
  --subject-alternative-names "*.example.com" \
  --validation-method DNS \
  --region us-east-1

# Follow the DNS validation process in the AWS Console
# Copy the certificate ARN to terraform.tfvars
```

### 2. Secrets Setup

Create all required secrets before deployment:

```bash
# Database credentials
aws secretsmanager create-secret \
  --name prod/database/url \
  --secret-string "postgresql://user@host:5432/dbname" \
  --region us-east-1

aws secretsmanager create-secret \
  --name prod/database/password \
  --secret-string "your-secure-password" \
  --region us-east-1

# API keys
aws secretsmanager create-secret \
  --name prod/stripe/api-key \
  --secret-string "sk_live_..." \
  --region us-east-1

aws ssm put-parameter \
  --name /prod/sendgrid/api-key \
  --value "SG...." \
  --type SecureString \
  --region us-east-1

# OAuth credentials
aws ssm put-parameter \
  --name /prod/oauth/client-id \
  --value "your-client-id" \
  --type String \
  --region us-east-1

aws secretsmanager create-secret \
  --name prod/oauth/client-secret \
  --secret-string "your-client-secret" \
  --region us-east-1

# Encryption keys
aws secretsmanager create-secret \
  --name prod/encryption/key \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1

# Session secret
aws secretsmanager create-secret \
  --name prod/session/secret \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1
```

### 3. Remote State Backend

Configure S3 backend for state management (see `backend.tf.example`):

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket prod-app-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket prod-app-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket prod-app-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name prod-app-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review the plan**:
   ```bash
   terraform plan -out=tfplan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply tfplan
   ```

4. **Save outputs**:
   ```bash
   terraform output > outputs.txt
   ```

## Post-Deployment

### 1. DNS Configuration

Point your domain to the ALB:

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Create Route 53 record (or use your DNS provider)
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "example.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "'$ALB_DNS'"}]
      }
    }]
  }'
```

### 2. Deploy Application

```bash
# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Authenticate Docker
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

# Build and push
docker build -t prod-app:v1.2.3 .
docker tag prod-app:v1.2.3 $ECR_URL:v1.2.3
docker push $ECR_URL:v1.2.3

# Force new deployment
aws ecs update-service \
  --cluster prod-app-cluster \
  --service prod-app-service \
  --force-new-deployment \
  --region us-east-1
```

### 3. Monitoring Setup

```bash
# Create CloudWatch alarms
aws cloudwatch put-metric-alarm \
  --alarm-name prod-app-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=ServiceName,Value=prod-app-service Name=ClusterName,Value=prod-app-cluster

aws cloudwatch put-metric-alarm \
  --alarm-name prod-app-high-memory \
  --alarm-description "Alert when memory exceeds 80%" \
  --metric-name MemoryUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=ServiceName,Value=prod-app-service Name=ClusterName,Value=prod-app-cluster
```

### 4. Health Check Verification

```bash
# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn) \
  --region us-east-1

# Check ECS service status
aws ecs describe-services \
  --cluster prod-app-cluster \
  --services prod-app-service \
  --region us-east-1
```

## Maintenance

### Updating the Application

```bash
# Build new version
docker build -t prod-app:v1.2.4 .
docker tag prod-app:v1.2.4 $ECR_URL:v1.2.4
docker push $ECR_URL:v1.2.4

# Update task definition with new image
# (Terraform will handle this on next apply)

# Or force immediate deployment
aws ecs update-service \
  --cluster prod-app-cluster \
  --service prod-app-service \
  --force-new-deployment \
  --region us-east-1
```

### Scaling

```bash
# Scale up
terraform apply -var="desired_count=5"

# Scale down
terraform apply -var="desired_count=2"
```

### Rotating Secrets

```bash
# Update secret value
aws secretsmanager update-secret \
  --secret-id prod/database/password \
  --secret-string "new-secure-password" \
  --region us-east-1

# Force new deployment to pick up new secret
aws ecs update-service \
  --cluster prod-app-cluster \
  --service prod-app-service \
  --force-new-deployment \
  --region us-east-1
```

## Disaster Recovery

### Backup

```bash
# Terraform state is automatically backed up in S3 with versioning
# Export current configuration
terraform show -json > backup-$(date +%Y%m%d).json

# Backup secrets
aws secretsmanager list-secrets --region us-east-1 > secrets-list.json
```

### Rollback

```bash
# Rollback to previous task definition
aws ecs update-service \
  --cluster prod-app-cluster \
  --service prod-app-service \
  --task-definition prod-app-service:PREVIOUS_REVISION \
  --region us-east-1

# Or rollback Terraform state
terraform state pull > current-state.json
# Restore from backup if needed
```

## Security Best Practices

1. **Secrets Rotation**: Rotate all secrets every 90 days
2. **Access Control**: Use IAM roles with least-privilege permissions
3. **Network Security**: Keep ECS tasks in private subnet
4. **Encryption**: Enable encryption at rest for all data stores
5. **Monitoring**: Set up CloudWatch Alarms and AWS GuardDuty
6. **Compliance**: Regular security audits and vulnerability scans
7. **Backup**: Regular backups of state and configuration

## Troubleshooting

### Tasks Not Starting

```bash
# Check service events
aws ecs describe-services \
  --cluster prod-app-cluster \
  --services prod-app-service \
  --region us-east-1 | jq '.services[0].events'

# Check task logs
aws logs tail /ecs/prod-app-service --follow --region us-east-1
```

### Health Check Failures

```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn) \
  --region us-east-1

# Test health endpoint
curl -v http://$(terraform output -raw alb_dns_name)/health
```

### High Costs

```bash
# Check Fargate usage
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://filter.json

# Optimize: Reduce task count or size if underutilized
```
