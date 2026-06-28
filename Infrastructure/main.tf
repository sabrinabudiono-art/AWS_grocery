# ── Shared lookups ─────────────────────────────────────────────────────────────
# These read existing AWS info and are shared by several modules, so they live
# in the root and get passed into modules as plain values.

# Default VPC for the account
data "aws_vpc" "default" {
  default = true
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# All subnets in the default VPC (used by ALB, compute, and RDS)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Our own AWS account ID (used to make the S3 bucket name unique)
data "aws_caller_identity" "current" {}

# SSH key pair shared by the compute instances
resource "aws_key_pair" "main" {
  key_name   = "terraform-key"
  public_key = file(var.public_key_path)
}

# ── Modules ──────────────────────────────────────────────────────────────────────

# Firewalls for the ALB, EC2 instances, and database
module "security_groups" {
  source = "./modules/security_groups"

  vpc_id = data.aws_vpc.default.id
  my_ip  = var.my_ip
}

# Public load balancer that fronts the app servers
module "alb" {
  source = "./modules/alb"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids
  alb_sg_id  = module.security_groups.alb_sg_id
}

# Container registry that stores the backend Docker image
module "ecr" {
  source = "./modules/ecr"

  repository_name = "grocery-backend"
}

# Auto Scaling Group of EC2 instances behind the ALB
module "compute" {
  source = "./modules/compute"

  ami_id           = data.aws_ami.amazon_linux_2023.id
  instance_type    = var.ec2_instance_type
  key_name         = aws_key_pair.main.key_name
  ec2_sg_id        = module.security_groups.ec2_sg_id
  subnet_ids       = data.aws_subnets.default.ids
  target_group_arn = module.alb.target_group_arn
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  # Container settings — where to pull the image from and how to log in.
  aws_region   = var.aws_region
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  image_url    = "${module.ecr.repository_url}:latest"

  # Database connection + app secret, passed into the container as env vars.
  db_endpoint = module.rds.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  jwt_secret  = var.jwt_secret
}

# PostgreSQL database
module "rds" {
  source = "./modules/rds"

  subnet_ids     = data.aws_subnets.default.ids
  rds_sg_id      = module.security_groups.rds_sg_id
  instance_class = var.db_instance_class
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = var.db_password
}

# S3 bucket for user avatars
module "s3" {
  source = "./modules/s3"

  account_id = data.aws_caller_identity.current.account_id
}