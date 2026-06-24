# Subnet group — the set of subnets (across AZs) where RDS can place the database.
resource "aws_db_subnet_group" "main" {
  name       = "grocery-shop-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "grocery-shop-db-subnet-group"
  }
}

# The PostgreSQL database instance.
resource "aws_db_instance" "postgres" {
  identifier     = "grocery-shop-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  publicly_accessible = false
  multi_az            = false

  # Dev-friendly: lets you destroy without a final snapshot.
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "grocery-shop-db"
  }
}
