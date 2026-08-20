# ------------------------------------------------------------
# Phase 3 - AWS Networking
# ------------------------------------------------------------

# Find available Availability Zones in the configured AWS region.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  phase3_project_name        = "cloud-devops-lab-project"
  phase3_vpc_cidr            = "10.10.0.0/16"
  phase3_public_subnet_cidr  = "10.10.1.0/24"
  phase3_private_subnet_cidr = "10.10.2.0/24"
}

# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = local.phase3_vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${local.phase3_project_name}-vpc"
    Project = local.phase3_project_name
  }
}

# ------------------------------------------------------------
# Public Subnet
# ------------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.phase3_public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${local.phase3_project_name}-public-subnet"
    Project = local.phase3_project_name
    Type    = "public"
  }
}

# ------------------------------------------------------------
# Private Subnet
# ------------------------------------------------------------

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.phase3_private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name    = "${local.phase3_project_name}-private-subnet"
    Project = local.phase3_project_name
    Type    = "private"
  }
}

# ------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.phase3_project_name}-igw"
    Project = local.phase3_project_name
  }
}

# ------------------------------------------------------------
# Elastic IP for NAT Gateway
# ------------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "${local.phase3_project_name}-nat-eip"
    Project = local.phase3_project_name
  }
}

# ------------------------------------------------------------
# NAT Gateway
#
# NAT Gateway MUST live in the public subnet so that it can
# reach the Internet Gateway.
# ------------------------------------------------------------

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name    = "${local.phase3_project_name}-nat-gateway"
    Project = local.phase3_project_name
  }
}

# ------------------------------------------------------------
# Public Route Table
# ------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${local.phase3_project_name}-public-rt"
    Project = local.phase3_project_name
  }
}

# ------------------------------------------------------------
# Private Route Table
# ------------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name    = "${local.phase3_project_name}-private-rt"
    Project = local.phase3_project_name
  }
}

# ------------------------------------------------------------
# Route Table Associations
# ------------------------------------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
