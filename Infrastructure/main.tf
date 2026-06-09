# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "grocery-shop"
      Environment = "development"
      ManagedBy   = "terraform"
    }
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# Import your public key
resource "aws_key_pair" "main" {
  key_name   = "terraform-key"
  public_key = file(var.public_key_path)
}

# ── ALB Security Group ─────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "terraform-alb"
  description = "Allow inbound HTTP from the internet and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags = {
    Name = "terraform-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── EC2 Security Group ─────────────────────────────────────────────────────────

resource "aws_security_group" "ssh" {
  name        = "terraform-ssh"
  description = "Allow SSH from your IP and HTTP from the ALB only"
  vpc_id      = data.aws_vpc.default.id
  tags = {
    Name = "terraform-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.ssh.id
  description       = "SSH from my IP"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id            = aws_security_group.ssh.id
  description                  = "HTTP from the ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_out" {
  security_group_id = aws_security_group.ssh.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
