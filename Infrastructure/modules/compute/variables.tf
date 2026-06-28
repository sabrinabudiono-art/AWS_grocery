variable "ami_id" {
  description = "AMI ID used for each EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to attach to instances"
  type        = string
}

variable "ec2_sg_id" {
  description = "Security group ID attached to each instance"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs the Auto Scaling Group launches instances into"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN the instances register with"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

# ── Container / ECR ────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region — needed to log in to ECR from the boot script"
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry host, e.g. <account>.dkr.ecr.<region>.amazonaws.com"
  type        = string
}

variable "image_url" {
  description = "Full image URL with tag, e.g. <repo-url>:latest"
  type        = string
}

# ── Database connection (passed into the container as env vars) ─────────────────

variable "db_endpoint" {
  description = "RDS endpoint (host:port) the app connects to"
  type        = string
}

variable "db_name" {
  description = "Database name the app connects to"
  type        = string
}

variable "db_username" {
  description = "Database username the app connects with"
  type        = string
}

variable "db_password" {
  description = "Database password the app connects with"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Secret key used by the app to sign JWT tokens"
  type        = string
  sensitive   = true
}
