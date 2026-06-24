variable "subnet_ids" {
  description = "Subnet IDs (at least 2 AZs) for the DB subnet group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID attached to the database"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}
