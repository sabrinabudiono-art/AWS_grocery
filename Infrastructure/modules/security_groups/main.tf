# ── ALB Security Group ─────────────────────────────────────────────────────────
# The firewall for the load balancer: open to the internet on port 80.

resource "aws_security_group" "alb" {
  name        = "terraform-alb"
  description = "Allow inbound HTTP from the internet and all outbound traffic"
  vpc_id      = var.vpc_id
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

# ── App (EC2) Security Group ───────────────────────────────────────────────────
# The firewall for the app servers. Named "app" rather than "ssh" because it
# governs all instance traffic — SSH from your IP AND HTTP from the ALB.

resource "aws_security_group" "app" {
  name        = "terraform-app"
  description = "Allow SSH from your IP and HTTP from the ALB only"
  vpc_id      = var.vpc_id
  tags = {
    Name = "terraform-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.app.id
  description       = "SSH from my IP"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "HTTP from the ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_out" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── RDS Security Group ─────────────────────────────────────────────────────────
# The firewall for the database: PostgreSQL only from the EC2 servers.

resource "aws_security_group" "rds" {
  name        = "terraform-rds"
  description = "Allow inbound PostgreSQL from EC2 only and all outbound traffic"
  vpc_id      = var.vpc_id
  tags = {
    Name = "terraform-rds"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from EC2 instances"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
