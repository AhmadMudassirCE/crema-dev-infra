# Custom Network Configuration Example

This example demonstrates how to configure custom VPC and subnet CIDR blocks for scenarios requiring specific IP address ranges or integration with existing network infrastructure.

## Configuration

- **Environment**: Production/Staging
- **Network**: Custom CIDR blocks (172.16.0.0/16)
- **High Availability**: Yes (2 tasks)
- **HTTPS**: No (can be added)
- **Use Case**: Integration with existing networks, VPN connections

## Network Architecture

```
VPC: 172.16.0.0/16 (65,536 IP addresses)
├── Public Subnet: 172.16.1.0/25 (128 IPs, 123 usable)
│   ├── Application Load Balancer
│   └── NAT Gateway
└── Private Subnet: 172.16.2.0/24 (256 IPs, 251 usable)
    └── ECS Tasks (up to 251 tasks)
```

## When to Use Custom Network Configuration

### 1. VPN Integration
If your organization uses a VPN with specific IP ranges, you need to avoid CIDR conflicts:
- Corporate VPN uses 10.0.0.0/8 → Use 172.16.0.0/12 or 192.168.0.0/16
- Existing AWS VPCs use 10.0.0.0/16 → Use different 10.x.0.0/16 range

### 2. VPC Peering
When peering with other VPCs, CIDR blocks must not overlap:
```
VPC A: 10.0.0.0/16  (Your existing VPC)
VPC B: 10.1.0.0/16  (This infrastructure)
```

### 3. Multi-Region Deployment
Use different CIDR blocks per region for clarity:
```
us-east-1: 10.0.0.0/16
us-west-2: 10.1.0.0/16
eu-west-1: 10.2.0.0/16
```

### 4. Subnet Sizing
Adjust subnet sizes based on expected scale:
```
Small deployment (< 10 tasks):
  Public:  /27 (32 IPs, 27 usable)
  Private: /27 (32 IPs, 27 usable)

Medium deployment (< 50 tasks):
  Public:  /26 (64 IPs, 59 usable)
  Private: /25 (128 IPs, 123 usable)

Large deployment (< 200 tasks):
  Public:  /25 (128 IPs, 123 usable)
  Private: /24 (256 IPs, 251 usable)
```

## CIDR Block Planning

### Available Private IP Ranges

1. **10.0.0.0/8** (Class A)
   - Range: 10.0.0.0 - 10.255.255.255
   - Total IPs: 16,777,216
   - Common for large enterprises

2. **172.16.0.0/12** (Class B)
   - Range: 172.16.0.0 - 172.31.255.255
   - Total IPs: 1,048,576
   - Good for medium-sized networks

3. **192.168.0.0/16** (Class C)
   - Range: 192.168.0.0 - 192.168.255.255
   - Total IPs: 65,536
   - Common for home/small office networks

### CIDR Notation Reference

| CIDR | Subnet Mask     | Total IPs | Usable IPs | Use Case                    |
|------|-----------------|-----------|------------|-----------------------------|
| /16  | 255.255.0.0     | 65,536    | 65,531     | Large VPC                   |
| /17  | 255.255.128.0   | 32,768    | 32,763     | Large VPC                   |
| /18  | 255.255.192.0   | 16,384    | 16,379     | Medium VPC                  |
| /19  | 255.255.224.0   | 8,192     | 8,187      | Medium VPC                  |
| /20  | 255.255.240.0   | 4,096     | 4,091      | Small VPC                   |
| /21  | 255.255.248.0   | 2,048     | 2,043      | Small VPC                   |
| /22  | 255.255.252.0   | 1,024     | 1,019      | Very small VPC              |
| /23  | 255.255.254.0   | 512       | 507        | Large subnet                |
| /24  | 255.255.255.0   | 256       | 251        | Standard subnet             |
| /25  | 255.255.255.128 | 128       | 123        | Small subnet                |
| /26  | 255.255.255.192 | 64        | 59         | Very small subnet           |
| /27  | 255.255.255.224 | 32        | 27         | Minimal subnet              |
| /28  | 255.255.255.240 | 16        | 11         | Tiny subnet (not recommended)|

### AWS Reserved IPs

AWS reserves 5 IP addresses in each subnet:
- **x.x.x.0**: Network address
- **x.x.x.1**: VPC router
- **x.x.x.2**: DNS server (Amazon-provided DNS)
- **x.x.x.3**: Reserved for future use
- **x.x.x.255**: Network broadcast address

Example for 172.16.1.0/25:
- Reserved: 172.16.1.0, 172.16.1.1, 172.16.1.2, 172.16.1.3, 172.16.1.127
- Usable: 172.16.1.4 - 172.16.1.126 (123 addresses)

## Subnet Planning Calculator

### Formula
```
Usable IPs = (2^(32 - CIDR)) - 5
```

### Examples
```
/24: 2^(32-24) - 5 = 256 - 5 = 251 usable IPs
/25: 2^(32-25) - 5 = 128 - 5 = 123 usable IPs
/26: 2^(32-26) - 5 = 64 - 5 = 59 usable IPs
```

### Sizing Recommendations

**Public Subnet** (ALB + NAT Gateway):
- Minimum: /28 (11 usable IPs)
- Recommended: /26 or /25 (59-123 usable IPs)
- Rationale: Few resources, but room for growth

**Private Subnet** (ECS Tasks):
- Calculate: (Max tasks × 1.5) + 5 reserved
- Example: 50 tasks → 75 + 5 = 80 IPs needed → Use /25 (123 usable)
- Add 50% buffer for deployments and scaling

## Validation

### Check for CIDR Conflicts

```bash
# List all VPCs in your account
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

# Check VPN CIDR blocks
aws ec2 describe-vpn-connections --query 'VpnConnections[*].[VpnConnectionId,CustomerGatewayConfiguration]'

# Verify subnet doesn't overlap
# Use online CIDR calculator or:
python3 << EOF
import ipaddress
vpc = ipaddress.ip_network('172.16.0.0/16')
public = ipaddress.ip_network('172.16.1.0/25')
private = ipaddress.ip_network('172.16.2.0/24')

print(f"Public subnet in VPC: {public.subnet_of(vpc)}")
print(f"Private subnet in VPC: {private.subnet_of(vpc)}")
print(f"Subnets overlap: {public.overlaps(private)}")
EOF
```

### Validate Configuration

```bash
# Terraform will validate CIDR blocks
terraform init
terraform validate

# Plan will show the network configuration
terraform plan
```

## Deployment

```bash
# Standard deployment process
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Common Network Scenarios

### Scenario 1: VPC Peering with Existing VPC

```hcl
# Existing VPC: 10.0.0.0/16
# New VPC: 10.1.0.0/16 (no overlap)

vpc_cidr            = "10.1.0.0/16"
public_subnet_cidr  = "10.1.1.0/24"
private_subnet_cidr = "10.1.2.0/24"
```

### Scenario 2: Site-to-Site VPN

```hcl
# Corporate network: 192.168.0.0/16
# AWS VPC: 10.0.0.0/16 (no overlap)

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
```

### Scenario 3: Multi-Region with Transit Gateway

```hcl
# Region 1 (us-east-1): 10.0.0.0/16
# Region 2 (us-west-2): 10.1.0.0/16
# Region 3 (eu-west-1): 10.2.0.0/16

# For us-west-2:
vpc_cidr            = "10.1.0.0/16"
public_subnet_cidr  = "10.1.1.0/24"
private_subnet_cidr = "10.1.2.0/24"
```

### Scenario 4: Large-Scale Deployment

```hcl
# Need to support 500+ tasks
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"   # 251 usable
private_subnet_cidr = "10.0.2.0/23"   # 507 usable (larger subnet)
```

## Troubleshooting

### CIDR Overlap Error

```
Error: InvalidVpcRange: The CIDR '10.0.0.0/16' conflicts with another network
```

**Solution**: Choose a different CIDR block that doesn't overlap.

### Subnet Too Small

```
Error: No available IP addresses in subnet
```

**Solution**: Use a larger CIDR block (smaller number after /).

### Invalid CIDR Format

```
Error: Invalid CIDR block format
```

**Solution**: Ensure CIDR is in format `x.x.x.x/y` where y is between 16-28 for VPC.

## Additional Resources

- [AWS VPC CIDR Blocks](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
- [CIDR Calculator](https://www.ipaddressguide.com/cidr)
- [RFC 1918 - Private Address Space](https://tools.ietf.org/html/rfc1918)
- [AWS VPC Peering](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)
