# Terraform ECS Infrastructure Examples

This directory contains example configurations demonstrating different deployment scenarios for the modular Terraform ECS infrastructure.

## Available Examples

### 1. [Minimal Deployment](./minimal-deployment/)
**Use Case**: Development, testing, proof of concept

**Features**:
- Minimal configuration with defaults
- Single task (no high availability)
- HTTP only (no HTTPS)
- No environment variables or secrets
- Lowest cost option

**Estimated Cost**: ~$58/month

**Best For**:
- Learning and experimentation
- Development environments
- Quick prototypes
- Cost-sensitive projects

---

### 2. [Production Deployment](./production-deployment/)
**Use Case**: Production environments with security and reliability requirements

**Features**:
- High availability (3 tasks)
- HTTPS with ACM certificate
- Comprehensive environment variables
- Secrets management (Secrets Manager + SSM)
- Custom VPC CIDR
- Larger task resources (1 vCPU, 2 GB)

**Estimated Cost**: ~$170-200/month

**Best For**:
- Production applications
- Customer-facing services
- Applications requiring high availability
- Security-sensitive workloads

---

### 3. [Custom Network](./custom-network/)
**Use Case**: Integration with existing network infrastructure

**Features**:
- Custom VPC and subnet CIDR blocks
- Network planning guidance
- CIDR conflict avoidance
- Subnet sizing examples

**Best For**:
- VPC peering scenarios
- VPN integration
- Multi-region deployments
- Specific IP addressing requirements

---

## Quick Start

### 1. Choose an Example

Select the example that best matches your use case:

```bash
# For development/testing
cd examples/minimal-deployment/

# For production
cd examples/production-deployment/

# For custom networking
cd examples/custom-network/
```

### 2. Copy Configuration

Copy the example configuration to your project root:

```bash
# From the example directory
cp terraform.tfvars ../../terraform.tfvars
```

### 3. Customize Values

Edit `terraform.tfvars` and update:
- AWS region and availability zone
- Project name
- Container image URL (after ECR is created)
- Any other parameters specific to your needs

### 4. Deploy

```bash
# Return to project root
cd ../..

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Comparison Matrix

| Feature | Minimal | Production | Custom Network |
|---------|---------|------------|----------------|
| **Cost/Month** | ~$58 | ~$170-200 | ~$90-120 |
| **High Availability** | No (1 task) | Yes (3 tasks) | Yes (2 tasks) |
| **HTTPS Support** | No | Yes | Optional |
| **Environment Variables** | No | Yes | Yes |
| **Secrets Management** | No | Yes | Optional |
| **Custom Network** | No | Yes | Yes |
| **Task Resources** | 0.25 vCPU, 512 MB | 1 vCPU, 2 GB | 0.5 vCPU, 1 GB |
| **Monitoring Setup** | Basic | Comprehensive | Basic |
| **Best For** | Dev/Test | Production | Network Integration |

## Common Customizations

### Scaling Tasks

Adjust the number of running tasks:

```hcl
desired_count = 3  # Run 3 tasks for high availability
```

### Changing Task Size

Adjust CPU and memory (must be valid Fargate combinations):

```hcl
task_cpu    = "512"   # 0.5 vCPU
task_memory = "1024"  # 1 GB
```

**Valid Fargate CPU/Memory Combinations**:

| CPU (vCPU) | Memory (MB) |
|------------|-------------|
| 256 (0.25) | 512, 1024, 2048 |
| 512 (0.5)  | 1024, 2048, 3072, 4096 |
| 1024 (1)   | 2048, 3072, 4096, 5120, 6144, 7168, 8192 |
| 2048 (2)   | 4096 to 16384 (1 GB increments) |
| 4096 (4)   | 8192 to 30720 (1 GB increments) |

### Adding HTTPS

1. Create an ACM certificate:
   ```bash
   aws acm request-certificate \
     --domain-name example.com \
     --validation-method DNS \
     --region us-east-1
   ```

2. Add certificate ARN to `terraform.tfvars`:
   ```hcl
   certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
   ```

### Adding Environment Variables

```hcl
environment_variables = {
  LOG_LEVEL = "info"
  APP_ENV   = "production"
  REGION    = "us-east-1"
}
```

### Adding Secrets

1. Create secrets in AWS:
   ```bash
   aws secretsmanager create-secret \
     --name myapp/db-password \
     --secret-string "your-password"
   ```

2. Reference in `terraform.tfvars`:
   ```hcl
   secrets = [
     {
       name      = "DATABASE_PASSWORD"
       valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/db-password-abc123"
     }
   ]
   ```

## Fargate CPU/Memory Reference

### Detailed Combinations

#### CPU: 256 (0.25 vCPU)
- Memory: 512 MB, 1024 MB (1 GB), 2048 MB (2 GB)
- **Use Case**: Lightweight applications, microservices, simple APIs
- **Cost**: Lowest tier

#### CPU: 512 (0.5 vCPU)
- Memory: 1024 MB (1 GB), 2048 MB (2 GB), 3072 MB (3 GB), 4096 MB (4 GB)
- **Use Case**: Small web applications, background workers
- **Cost**: Low tier

#### CPU: 1024 (1 vCPU)
- Memory: 2048 MB (2 GB), 3072 MB (3 GB), 4096 MB (4 GB), 5120 MB (5 GB), 6144 MB (6 GB), 7168 MB (7 GB), 8192 MB (8 GB)
- **Use Case**: Standard web applications, API servers, moderate workloads
- **Cost**: Medium tier

#### CPU: 2048 (2 vCPU)
- Memory: 4096 MB (4 GB) to 16384 MB (16 GB) in 1024 MB increments
- **Use Case**: Large applications, data processing, high-traffic services
- **Cost**: High tier

#### CPU: 4096 (4 vCPU)
- Memory: 8192 MB (8 GB) to 30720 MB (30 GB) in 1024 MB increments
- **Use Case**: Very large applications, intensive processing, high-performance requirements
- **Cost**: Highest tier

### Pricing Considerations

Fargate pricing is based on vCPU-hours and GB-hours:

**Example Pricing** (us-east-1, as of 2024):
- vCPU: $0.04048 per vCPU per hour
- Memory: $0.004445 per GB per hour

**Monthly Cost Examples** (730 hours/month):

| Configuration | vCPU Cost | Memory Cost | Total/Month |
|---------------|-----------|-------------|-------------|
| 0.25 vCPU, 0.5 GB | $7.39 | $1.62 | $9.01 |
| 0.5 vCPU, 1 GB | $14.78 | $3.24 | $18.02 |
| 1 vCPU, 2 GB | $29.55 | $6.49 | $36.04 |
| 2 vCPU, 4 GB | $59.10 | $12.98 | $72.08 |
| 4 vCPU, 8 GB | $118.20 | $25.95 | $144.15 |

**Note**: Add costs for ALB (~$16/month), NAT Gateway (~$32/month), and data transfer.

### Choosing the Right Size

1. **Start Small**: Begin with 256 CPU / 512 MB and scale up based on metrics
2. **Monitor**: Use CloudWatch to track CPU and memory utilization
3. **Right-Size**: Aim for 60-80% utilization for cost efficiency
4. **Scale Out**: Add more tasks rather than larger tasks when possible

**Monitoring Commands**:
```bash
# Check CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=myapp-service Name=ClusterName,Value=myapp-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average

# Check memory utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=myapp-service Name=ClusterName,Value=myapp-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

## Environment Variables vs Secrets

### When to Use Environment Variables

**Use for non-sensitive configuration**:
- Log levels (`LOG_LEVEL=info`)
- Feature flags (`FEATURE_X_ENABLED=true`)
- Public endpoints (`API_URL=https://api.example.com`)
- Region identifiers (`AWS_REGION=us-east-1`)
- Application mode (`NODE_ENV=production`)

**Characteristics**:
- Stored in plain text in task definition
- Visible in AWS Console and CLI
- Easy to update (requires new task definition)
- No additional IAM permissions needed

### When to Use Secrets

**Use for sensitive data**:
- Database passwords
- API keys and tokens
- OAuth credentials
- Encryption keys
- Session secrets
- Private keys

**Characteristics**:
- Stored securely in Secrets Manager or SSM Parameter Store
- Not visible in task definition (only ARN reference)
- Can be rotated without updating task definition
- Requires IAM permissions (automatically granted by this module)
- Encrypted at rest and in transit

### Example Configuration

```hcl
# Non-sensitive configuration
environment_variables = {
  LOG_LEVEL = "info"
  APP_ENV   = "production"
  API_URL   = "https://api.example.com"
}

# Sensitive credentials
secrets = [
  {
    name      = "DATABASE_PASSWORD"
    valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password-abc123"
  },
  {
    name      = "API_KEY"
    valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/api-key"
  }
]
```

## Next Steps

1. **Choose an example** that matches your use case
2. **Review the README** in the example directory
3. **Copy and customize** the configuration
4. **Deploy** using Terraform
5. **Monitor** your infrastructure using CloudWatch
6. **Scale** as needed based on metrics

## Additional Resources

- [Main README](../README.md) - Project overview and setup
- [Backend Configuration](../backend.tf.example) - Remote state setup
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

For issues or questions:
1. Check the example README files
2. Review the main project README
3. Consult AWS documentation
4. Check Terraform AWS provider documentation
