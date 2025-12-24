# Variables for AWS Free Tier Linux EC2 Instance

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
  default     = "Linux-Free-Tier"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro"], var.instance_type)
    error_message = "Instance type must be t2.micro for free tier."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change to your IP for better security
}

variable "public_key_path" {
  description = "Path to your public SSH key file (optional)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 30
    error_message = "Root volume size must be between 8 and 30 GB for free tier."
  }
}

variable "custom_port" {
  description = "Custom application port to open"
  type        = number
  default     = 8080
}

variable "enable_termination_protection" {
  description = "Enable termination protection for the instance"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}