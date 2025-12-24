# AWS Free Tier Linux EC2 Instance Terraform Configuration
# Created by Adps AI for automated infrastructure deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "AWS Free Tier Linux"
      Environment = var.environment
      CreatedBy   = "Adps-AI"
      Owner       = "Admin-Syam"
    }
  }
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Security Group for EC2 Instance
resource "aws_security_group" "linux_sg" {
  name_prefix = "${var.instance_name}-sg-"
  description = "Security group for ${var.instance_name} instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom port for applications (optional)
  ingress {
    description = "Custom App Port"
    from_port   = var.custom_port
    to_port     = var.custom_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-security-group"
  }
}

# Create Key Pair (optional - only if key is provided)
resource "aws_key_pair" "linux_key" {
  count      = var.public_key_path != "" ? 1 : 0
  key_name   = "${var.instance_name}-key"
  public_key = file(var.public_key_path)
  
  tags = {
    Name = "${var.instance_name}-key-pair"
  }
}

# EC2 Instance - Free Tier Linux
resource "aws_instance" "linux_free_tier" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.public_key_path != "" ? aws_key_pair.linux_key[0].key_name : null
  vpc_security_group_ids      = [aws_security_group.linux_sg.id]
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
    
    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    instance_name = var.instance_name
    environment   = var.environment
    custom_port   = var.custom_port
  }))

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Purpose     = "Free-Tier-Development"
  }

  # Prevent accidental termination
  disable_api_termination = var.enable_termination_protection
  
  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for instance logs
resource "aws_cloudwatch_log_group" "instance_logs" {
  name              = "/aws/ec2/${var.instance_name}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${var.instance_name}-logs"
  }
}

# CloudWatch Alarm for CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.instance_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.linux_free_tier.id
  }
  
  tags = {
    Name = "${var.instance_name}-cpu-alarm"
  }
}

# CloudWatch Alarm for Status Check
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "${var.instance_name}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors instance status check"
  
  dimensions = {
    InstanceId = aws_instance.linux_free_tier.id
  }
  
  tags = {
    Name = "${var.instance_name}-status-alarm"
  }
}