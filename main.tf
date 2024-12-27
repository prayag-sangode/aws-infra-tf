#  Create a custom VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}

# Internet Gateway for the VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Private Route Table (No Internet Access)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "private-rt"
  }
}

# Public Subnets
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-az2"
  }
}

# Private Subnets
resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-az1"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-az2"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_az1_assoc" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_az2_assoc" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}

# Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# EKS Node Security Group
resource "aws_security_group" "eks_node_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-sg"
  }
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                         = "ami-005fc0f236362e99f" # Ubuntu22 AMI
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_az1.id
  key_name                    = "MyKeyPair" # Replace with the key name you used in AWS
  associate_public_ip_address = true
  security_groups             = [aws_security_group.bastion_sg.name]
  tags = {
    Name = "bastion-host"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy Attachments for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy Attachments for EKS Node Group
resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

# EKS Cluster
resource "aws_eks_cluster" "my_cluster" {
  name     = "my-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
    security_group_ids = [aws_security_group.eks_node_sg.id]
  }
}

# Node Group
resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  security_groups = [aws_security_group.eks_node_sg.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  tags = {
    Name = "eks-node-group"
  }

  remote_access {
    ec2_ssh_key = "MyKeyPair"  # Optional: to SSH into the nodes
  }
}

# Outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.my_cluster.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.my_cluster.name
}
