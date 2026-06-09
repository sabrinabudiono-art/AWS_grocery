resource "aws_db_subnet_group" "main" {
  name       = "grocery-shop-db-subnet-group"
  subnet_ids = data.aws_subnets.alb.ids

  tags = {
    Name = "grocery-shop-db-subnet-group"
  }
}

# ── RDS Security Group ─────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "terraform-rds"
  description = "Allow inbound PostgreSQL from EC2 only and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id
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
  referenced_security_group_id = aws_security_group.ssh.id
}

resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_db_instance" "postgres" {
  identifier     = "grocery-shop-db"
  engine         = "postgres"
  engine_version = "16" # latest minor of PG 16; see note below
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  # Dev-friendly: lets you destroy without a final snapshot
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "grocery-shop-db"
  }
}