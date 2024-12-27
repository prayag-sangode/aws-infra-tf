# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.custom_vpc.id

  ingress {
    description      = "Allow SSH from anywhere (Replace 0.0.0.0/0 with your IP range)"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # Replace with your specific IP CIDR block
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = "ami-0e2c8caa4b6378d8c" # Ubuntu24 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_az1.id
  key_name               = "MyKeyPair" 
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-host"
  }
}

# Outputs
output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host instance"
  value       = aws_instance.bastion.public_ip
}
