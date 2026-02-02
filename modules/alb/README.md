# ALB Module

This module creates an Application Load Balancer (ALB) with security groups, target groups, and listeners for HTTP and HTTPS traffic.

## Resources Created

- **Security Group**: Allows inbound HTTP (80) and HTTPS (443) traffic from the internet
- **Application Load Balancer**: Internet-facing ALB in the public subnet
- **Target Group**: IP-based target group for ECS tasks with configurable health checks
- **HTTP Listener**: Always created on port 80, forwards traffic to the target group
- **HTTPS Listener**: Conditionally created on port 443 when a certificate ARN is provided

## Listeners

### HTTP Listener (Port 80)
- Always created
- Forwards all traffic to the target group
- No SSL/TLS termination

### HTTPS Listener (Port 443)
- Only created when `certificate_arn` variable is provided
- Performs SSL/TLS termination using the provided certificate
- Uses TLS 1.3 security policy: `ELBSecurityPolicy-TLS13-1-2-2021-06`
- Forwards decrypted traffic to the target group

## Usage

### Without HTTPS
```hcl
module "alb" {
  source = "./modules/alb"

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  project_name     = "myapp"
  container_port   = 80
  certificate_arn  = null  # No HTTPS listener
}
```

### With HTTPS
```hcl
module "alb" {
  source = "./modules/alb"

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  project_name     = "myapp"
  container_port   = 80
  certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | ID of the VPC | string | - | yes |
| public_subnet_id | ID of the public subnet | string | - | yes |
| project_name | Project name for resource tagging | string | - | yes |
| container_port | Port on which the container listens | number | 80 | no |
| health_check_path | Path for ALB health checks | string | "/" | no |
| health_check_interval | Interval between health checks (seconds) | number | 30 | no |
| health_check_timeout | Health check timeout (seconds) | number | 5 | no |
| healthy_threshold | Number of consecutive successful health checks | number | 2 | no |
| unhealthy_threshold | Number of consecutive failed health checks | number | 2 | no |
| certificate_arn | ARN of SSL certificate for HTTPS listener (optional) | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS name of the Application Load Balancer |
| alb_arn | ARN of the Application Load Balancer |
| target_group_arn | ARN of the target group |
| alb_security_group_id | ID of the ALB security group |

## Requirements

- **Requirement 6.6**: HTTP listener on port 80 forwarding to target group
- **Requirement 6.7**: HTTPS listener on port 443 with SSL termination (when certificate provided)
- **Requirement 6.8**: Outputs for ALB DNS name, ARN, target group ARN, and security group ID

## Notes

- The ALB is configured as internet-facing and must be placed in a public subnet
- AWS requires ALBs to span at least 2 availability zones (2 subnets) for production use
- The current single-subnet configuration is a known limitation of the single-AZ architecture design
- Health checks are performed on the target group to ensure only healthy tasks receive traffic
