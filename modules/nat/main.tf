# NAT Module - Network Address Translation for private subnet internet access

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "${var.project_name}-nat-eip"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "nat"
  }
}

# NAT Gateway in public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name      = "${var.project_name}-nat-gateway"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "nat"
  }

  # Ensure proper ordering - NAT Gateway depends on Internet Gateway
  # The Internet Gateway is created by the VPC module and attached to the VPC
  # Since the public subnet is in that VPC, this dependency is implicit
}

# Route for private subnet to NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
