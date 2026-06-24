variable "vpc_id" {
  description = "ID of the VPC where the security groups are created"
  type        = string
}

variable "my_ip" {
  description = "Your public IP in CIDR notation — restricts SSH access to your machine only"
  type        = string
}
