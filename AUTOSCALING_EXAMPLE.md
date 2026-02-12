# ECS Auto-Scaling Configuration Example

## How It Works

Auto-scaling automatically adjusts the number of running tasks based on metrics:

1. **CloudWatch monitors metrics** (CPU, memory, request count)
2. **When threshold exceeded** → Scale out (add tasks)
3. **When threshold drops** → Scale in (remove tasks)
4. **Cooldown periods** prevent rapid scaling

## Configuration Example

Add these to your `terraform.tfvars`:

```hcl
# Web Service Auto-Scaling
web_enable_autoscaling        = true
web_autoscaling_min_capacity  = 1    # Minimum tasks (always running)
web_autoscaling_max_capacity  = 10   # Maximum tasks (scale up to)

# CPU-based scaling (recommended for Rails apps)
web_autoscaling_cpu_enabled   = true
web_autoscaling_cpu_target    = 70   # Scale when avg CPU > 70%

# Memory-based scaling (optional)
web_autoscaling_memory_enabled = false
web_autoscaling_memory_target  = 80  # Scale when avg memory > 80%

# Request-based scaling (optional, good for traffic spikes)
web_autoscaling_alb_requests_enabled = false
web_autoscaling_alb_requests_target  = 1000  # Requests per task per minute

# Cooldown periods (prevent rapid scaling)
web_autoscaling_scale_out_cooldown = 60   # Wait 60s after scaling out
web_autoscaling_scale_in_cooldown  = 300  # Wait 5min after scaling in
```

## Scaling Scenarios

### Scenario 1: Normal Load
- CPU: 40%
- Tasks: 1 (minimum)
- Status: No scaling needed

### Scenario 2: High Load
- CPU: 75% (exceeds 70% target)
- Action: Scale out +1 task
- Wait 60s cooldown
- New CPU: 37.5% (load distributed)

### Scenario 3: Very High Load
- CPU: 80% (still exceeds target)
- Action: Scale out +1 task (now 3 total)
- Wait 60s cooldown
- New CPU: 25% (load distributed)

### Scenario 4: Load Decreases
- CPU: 50% (below 70% target)
- Wait 5 minutes (scale-in cooldown)
- Action: Scale in -1 task
- New CPU: 75% (still acceptable)

## Recommended Settings by Environment

### Development
```hcl
web_enable_autoscaling       = false  # Fixed 1 task
web_desired_count            = 1
```

### Staging
```hcl
web_enable_autoscaling       = true
web_autoscaling_min_capacity = 1
web_autoscaling_max_capacity = 3
web_autoscaling_cpu_target   = 70
```

### Production
```hcl
web_enable_autoscaling       = true
web_autoscaling_min_capacity = 2      # Always 2 for HA
web_autoscaling_max_capacity = 10     # Scale up to 10
web_autoscaling_cpu_target   = 60     # More aggressive (60%)
web_autoscaling_memory_enabled = true # Also watch memory
web_autoscaling_memory_target  = 75
```

## Cost Implications

**Without Auto-Scaling:**
- 2 tasks × 24 hours × 30 days = 1,440 task-hours/month
- Fixed cost regardless of traffic

**With Auto-Scaling (min=1, max=10):**
- Low traffic: 1 task × 24 hours = 24 task-hours/day
- High traffic: 5 tasks × 2 hours = 10 task-hours/day
- Average: ~30-40 task-hours/day = 900-1,200 task-hours/month
- **Saves ~30-40% on compute costs**

## Monitoring Auto-Scaling

Check CloudWatch metrics:
- `ECS > Service > CPUUtilization`
- `ECS > Service > MemoryUtilization`
- `ECS > Service > DesiredTaskCount` (see scaling events)
- `ECS > Service > RunningTaskCount`

Check CloudWatch Alarms:
- Auto-scaling creates alarms automatically
- View in CloudWatch > Alarms

Check ECS Service Events:
- ECS Console > Cluster > Service > Events tab
- Shows scaling activities: "service scaled from 1 to 2 tasks"

## Why Sidekiq Doesn't Auto-Scale

Sidekiq workers should NOT auto-scale based on CPU/memory because:

1. **Job queue depth matters more** - CPU might be low but queue is full
2. **Unpredictable scaling** - Jobs come in bursts
3. **Better to scale manually** - Based on queue metrics (Sidekiq Pro feature)

For Sidekiq, use fixed count or scale based on custom metrics:
- Redis queue depth
- Job processing time
- Failed job count
