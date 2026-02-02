# VPC Module - Network foundation with public and private subnets across multiple AZs

# VPC with DNS support enabled
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "${var.project_name}-vpc"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "vpc"
  }
}

# Public subnets with auto-assign public IP enabled (one per AZ)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.project_name}-public-subnet-${count.index + 1}"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "vpc"
    Type      = "public"
    AZ        = var.availability_zones[count.index]
  }
}

# Private subnets (one per AZ)
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name      = "${var.project_name}-private-subnet-${count.index + 1}"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "vpc"
    Type      = "private"
    AZ        = var.availability_zones[count.index]
  }
}

# Internet Gateway attached to VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.project_name}-igw"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "vpc"
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.project_name}-public-rt"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "vpc"
    Type      = "public"
  }
}

# Route in public route table to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Route table for private subnets (NAT route will be added by NAT module)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.project_name}-private-rt"
    Project   = var.project_name
    ManagedBy = "Terraform"
    Module    = "vpc"
    Type      = "private"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
