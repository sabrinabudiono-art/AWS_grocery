variable "vpc_id" {
  description = "ID of the VPC where the load balancer lives"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs (at least 2 AZs) for the load balancer"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID to attach to the load balancer"
  type        = string
}
