variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "eu-central-1"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the Auto Scaling Group"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "./terraform-key.pem.pub"
}

variable "my_ip" {
  description = "Your public IP in CIDR notation — restricts SSH access to your machine only"
  type        = string
}

# ── RDS ────────────────────────────────────────────────────────────────────────

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "AWSgrocery"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password for the RDS instance — set this in terraform.tfvars"
  type        = string
  sensitive   = true
}

# ── Auto Scaling Group ─────────────────────────────────────────────────────────

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}
