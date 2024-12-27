# Create a custom VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "custom-vpc"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "custom_igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "custom-igw"
  }
}

# Create a route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Public Subnet 1 (Availability Zone 1)
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az1"
  }
}

# Public Subnet 2 (Availability Zone 2)
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az2"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnet 1 (Availability Zone 1)
resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-az1"
  }
}

# Private Subnet 2 (Availability Zone 2)
resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-az2"
  }
}

# Create NAT Gateway for private subnets
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "nat-gw"
  }
}

# Create a route table for private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-rt"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_rt.id
}

# Outputs
output "vpc_id" {
  description = "ID of the custom VPC"
  value       = aws_vpc.custom_vpc.id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = [aws_subnet.private_subnet_az1.id, aws_subnet.private_subnet_az2.id]
}
