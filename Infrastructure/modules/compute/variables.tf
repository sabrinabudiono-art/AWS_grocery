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
