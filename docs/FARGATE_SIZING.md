# AWS Fargate CPU and Memory Configuration Guide

This document provides a comprehensive reference for valid AWS Fargate CPU and memory combinations, along with guidance on choosing the right configuration for your workload.

## Valid CPU/Memory Combinations

AWS Fargate requires specific CPU and memory combinations. You cannot choose arbitrary values.

### Quick Reference Table

| CPU Value | CPU (vCPU) | Valid Memory Values (MB) |
|-----------|------------|--------------------------|
| 256 | 0.25 vCPU | 512, 1024, 2048 |
| 512 | 0.5 vCPU | 1024, 2048, 3072, 4096 |
| 1024 | 1 vCPU | 2048, 3072, 4096, 5120, 6144, 7168, 8192 |
| 2048 | 2 vCPU | Between 4096 and 16384 in increments of 1024 |
| 4096 | 4 vCPU | Between 8192 and 30720 in increments of 1024 |

### Detailed Combinations

#### CPU: 256 (0.25 vCPU)

```hcl
task_cpu = "256"
```

**Valid Memory Options**:
- `task_memory = "512"`   (0.5 GB)
- `task_memory = "1024"`  (1 GB)
- `task_memory = "2048"`  (2 GB)

**Use Cases**:
- Lightweight microservices
- Simple REST APIs
- Background workers with minimal processing
- Static file servers
- Health check endpoints

**Example Applications**:
- Simple Node.js Express API
- Python Flask microservice
- Go HTTP server
- Nginx reverse proxy

**Cost** (per task per month in us-east-1):
- 256/512: ~$9/month
- 256/1024: ~$12/month
- 256/2048: ~$16/month

---

#### CPU: 512 (0.5 vCPU)

```hcl
task_cpu = "512"
```

**Valid Memory Options**:
- `task_memory = "1024"`  (1 GB)
- `task_memory = "2048"`  (2 GB)
- `task_memory = "3072"`  (3 GB)
- `task_memory = "4096"`  (4 GB)

**Use Cases**:
- Small web applications
- API gateways
- Background job processors
- Caching services
- Development environments

**Example Applications**:
- Django/Flask web application
- Node.js application with moderate traffic
- Ruby on Rails API
- Redis cache
- Small WordPress site

**Cost** (per task per month in us-east-1):
- 512/1024: ~$18/month
- 512/2048: ~$21/month
- 512/3072: ~$25/month
- 512/4096: ~$29/month

---

#### CPU: 1024 (1 vCPU)

```hcl
task_cpu = "1024"
```

**Valid Memory Options**:
- `task_memory = "2048"`  (2 GB)
- `task_memory = "3072"`  (3 GB)
- `task_memory = "4096"`  (4 GB)
- `task_memory = "5120"`  (5 GB)
- `task_memory = "6144"`  (6 GB)
- `task_memory = "7168"`  (7 GB)
- `task_memory = "8192"`  (8 GB)

**Use Cases**:
- Standard web applications
- API servers with moderate traffic
- Data processing tasks
- Application servers
- Database proxies

**Example Applications**:
- Production Node.js/Python/Ruby application
- Java Spring Boot application
- .NET Core application
- GraphQL server
- Elasticsearch node (small)

**Cost** (per task per month in us-east-1):
- 1024/2048: ~$36/month
- 1024/4096: ~$43/month
- 1024/8192: ~$56/month

---

#### CPU: 2048 (2 vCPU)

```hcl
task_cpu = "2048"
```

**Valid Memory Options** (in MB):
- 4096, 5120, 6144, 7168, 8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384

**Memory Range**: 4 GB to 16 GB in 1 GB increments

**Use Cases**:
- Large web applications
- High-traffic API servers
- Data processing pipelines
- Machine learning inference
- Multi-threaded applications

**Example Applications**:
- High-traffic e-commerce site
- Real-time analytics service
- Video processing service
- Large Java applications
- Elasticsearch node (medium)

**Cost** (per task per month in us-east-1):
- 2048/4096: ~$72/month
- 2048/8192: ~$85/month
- 2048/16384: ~$111/month

---

#### CPU: 4096 (4 vCPU)

```hcl
task_cpu = "4096"
```

**Valid Memory Options** (in MB):
- 8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384, 17408, 18432, 19456, 20480, 21504, 22528, 23552, 24576, 25600, 26624, 27648, 28672, 29696, 30720

**Memory Range**: 8 GB to 30 GB in 1 GB increments

**Use Cases**:
- Very large applications
- Intensive data processing
- Machine learning training
- High-performance computing
- Large-scale batch processing

**Example Applications**:
- Large-scale data analytics
- Video encoding/transcoding
- Scientific computing
- Large Elasticsearch cluster nodes
- High-performance databases

**Cost** (per task per month in us-east-1):
- 4096/8192: ~$144/month
- 4096/16384: ~$170/month
- 4096/30720: ~$223/month

---

## Choosing the Right Configuration

### Step 1: Estimate Your Requirements

#### CPU Requirements

Consider:
- **Request rate**: How many requests per second?
- **Processing complexity**: Simple CRUD vs complex calculations?
- **Concurrency**: How many concurrent operations?
- **Language/Framework**: Interpreted (Python, Ruby) vs compiled (Go, Rust)?

**General Guidelines**:
- **0.25 vCPU**: < 10 requests/second, simple operations
- **0.5 vCPU**: 10-50 requests/second, moderate complexity
- **1 vCPU**: 50-200 requests/second, standard applications
- **2 vCPU**: 200-500 requests/second, complex operations
- **4 vCPU**: > 500 requests/second, intensive processing

#### Memory Requirements

Consider:
- **Application footprint**: Base memory usage
- **Request handling**: Memory per request
- **Caching**: In-memory cache size
- **Framework overhead**: Java/JVM vs Node.js vs Go

**General Guidelines**:
- **512 MB - 1 GB**: Minimal applications, microservices
- **2 GB - 4 GB**: Standard web applications
- **4 GB - 8 GB**: Large applications, moderate caching
- **8 GB - 16 GB**: Heavy caching, data processing
- **16 GB - 30 GB**: Large-scale data processing, ML inference

### Step 2: Start Small and Scale

**Recommended Approach**:

1. **Start with**: 512 CPU / 1024 MB (0.5 vCPU, 1 GB)
2. **Deploy and monitor** for 24-48 hours
3. **Check metrics**:
   - CPU utilization
   - Memory utilization
   - Response times
   - Error rates
4. **Adjust** based on metrics:
   - CPU > 80%: Increase CPU or add more tasks
   - Memory > 80%: Increase memory
   - Both high: Increase both or add more tasks

### Step 3: Monitor and Optimize

#### Key Metrics to Monitor

```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=myapp-service Name=ClusterName,Value=myapp-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# Memory Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=myapp-service Name=ClusterName,Value=myapp-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

#### Optimization Guidelines

**Target Utilization**:
- **CPU**: 60-80% average, < 90% peak
- **Memory**: 60-80% average, < 85% peak

**If CPU is high but memory is low**:
- Increase CPU while keeping memory the same
- Or add more tasks (scale horizontally)

**If memory is high but CPU is low**:
- Increase memory while keeping CPU the same
- Check for memory leaks

**If both are high**:
- Increase both CPU and memory
- Or scale horizontally (add more tasks)

**If both are low**:
- Decrease CPU and memory to save costs
- Ensure you maintain headroom for traffic spikes

### Step 4: Consider Scaling Strategy

#### Vertical Scaling (Larger Tasks)
**Pros**:
- Simpler architecture
- Lower networking overhead
- Better for CPU-intensive workloads

**Cons**:
- Higher cost per task
- Less fault tolerance
- Longer deployment times

**When to use**:
- CPU-bound applications
- Applications with high memory requirements
- Single-threaded workloads

#### Horizontal Scaling (More Tasks)
**Pros**:
- Better fault tolerance
- Faster deployments
- Better load distribution
- More cost-effective for variable loads

**Cons**:
- More complex architecture
- Higher networking overhead
- Requires stateless design

**When to use**:
- I/O-bound applications
- Web applications with variable traffic
- Stateless microservices
- High availability requirements

## Common Configurations by Application Type

### Microservices / REST APIs

**Small** (< 100 req/s):
```hcl
task_cpu    = "256"
task_memory = "512"
desired_count = 2
```

**Medium** (100-500 req/s):
```hcl
task_cpu    = "512"
task_memory = "1024"
desired_count = 3
```

**Large** (> 500 req/s):
```hcl
task_cpu    = "1024"
task_memory = "2048"
desired_count = 5
```

### Web Applications

**Development**:
```hcl
task_cpu    = "256"
task_memory = "512"
desired_count = 1
```

**Staging**:
```hcl
task_cpu    = "512"
task_memory = "1024"
desired_count = 2
```

**Production**:
```hcl
task_cpu    = "1024"
task_memory = "2048"
desired_count = 3
```

### Background Workers

**Light Processing**:
```hcl
task_cpu    = "256"
task_memory = "512"
desired_count = 2
```

**Heavy Processing**:
```hcl
task_cpu    = "2048"
task_memory = "4096"
desired_count = 2
```

### Data Processing

**Batch Jobs**:
```hcl
task_cpu    = "2048"
task_memory = "8192"
desired_count = 1  # Scale based on queue depth
```

**Stream Processing**:
```hcl
task_cpu    = "1024"
task_memory = "4096"
desired_count = 3
```

## Cost Optimization Tips

### 1. Right-Size Your Tasks

- Monitor utilization for 1-2 weeks
- Aim for 60-80% average utilization
- Don't over-provision "just in case"

### 2. Use Spot Capacity (Fargate Spot)

- Save up to 70% on compute costs
- Good for fault-tolerant workloads
- Not covered in this module (requires additional configuration)

### 3. Scale Horizontally When Possible

- Multiple small tasks often cheaper than one large task
- Better fault tolerance
- More flexible scaling

### 4. Use Auto Scaling

- Scale based on metrics (CPU, memory, request count)
- Reduce costs during low-traffic periods
- Not covered in this module (requires additional configuration)

### 5. Optimize Your Application

- Reduce memory footprint
- Improve CPU efficiency
- Use connection pooling
- Implement caching

## Troubleshooting

### Task Keeps Restarting

**Possible Causes**:
- Out of memory (OOM)
- Application crash
- Health check failures

**Solutions**:
1. Check CloudWatch Logs for errors
2. Increase memory if OOM errors
3. Fix application bugs
4. Adjust health check settings

### High CPU Utilization

**Solutions**:
1. Increase CPU allocation
2. Add more tasks (horizontal scaling)
3. Optimize application code
4. Add caching layer

### High Memory Utilization

**Solutions**:
1. Increase memory allocation
2. Check for memory leaks
3. Optimize application memory usage
4. Implement connection pooling

### Tasks Not Starting

**Possible Causes**:
- Invalid CPU/memory combination
- Insufficient capacity in region
- IAM permission issues

**Solutions**:
1. Verify CPU/memory combination is valid
2. Try different availability zone
3. Check IAM role permissions

## Additional Resources

- [AWS Fargate Task Definition Parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [ECS Best Practices Guide](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)

## Quick Reference Commands

### Check Current Configuration

```bash
# Get task definition
aws ecs describe-task-definition \
  --task-definition myapp-service \
  --query 'taskDefinition.{CPU:cpu,Memory:memory}' \
  --output table

# Get running tasks
aws ecs list-tasks \
  --cluster myapp-cluster \
  --service-name myapp-service

# Describe task
aws ecs describe-tasks \
  --cluster myapp-cluster \
  --tasks <task-arn>
```

### Update Configuration

```bash
# Update via Terraform
terraform apply -var="task_cpu=1024" -var="task_memory=2048"

# Force new deployment
aws ecs update-service \
  --cluster myapp-cluster \
  --service myapp-service \
  --force-new-deployment
```
