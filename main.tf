# AWS Free Tier Linux EC2 Instance - Terraform Configuration
# Automated Infrastructure Deployment by Adps AI

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# Data: Default VPC
data "aws_vpc" "default" {
  default = true
}

# Data: Default Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data: Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group for EC2
resource "aws_security_group" "linux_sg" {
  name_prefix = "linux-free-tier-"
  description = "Security group for Linux free tier instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "linux-free-tier-sg"
  }
}

# EC2 Instance - Free Tier
resource "aws_instance" "linux_free_tier" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.linux_sg.id]
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y htop git curl wget docker
              
              # Start Docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              
              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              
              # Create welcome message
              cat > /home/ec2-user/welcome.txt << 'EOL'
              Welcome to your Free Tier Linux Instance!
              
              Instance Details:
              - Instance Type: t2.micro (Free Tier)
              - AMI: Amazon Linux 2
              - Created: $(date)
              
              Pre-installed Software:
              - Docker
              - AWS CLI v2
              - Git, curl, wget, htop
              
              Quick Commands:
              - docker --version
              - aws --version
              - htop (system monitor)
              
              Happy coding!
EOL
              
              chown ec2-user:ec2-user /home/ec2-user/welcome.txt
              EOF

  tags = {
    Name        = "Linux-Free-Tier-Instance"
    Environment = "Development"
    CreatedBy   = "Adps-AI"
  }
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.linux_free_tier.id
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.linux_free_tier.public_ip
}

output "public_dns" {
  description = "Public DNS of the instance"
  value       = aws_instance.linux_free_tier.public_dns
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i your-key.pem ec2-user@${aws_instance.linux_free_tier.public_ip}"
}