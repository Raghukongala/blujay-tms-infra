resource "aws_db_subnet_group" "postgres" {
  name       = "${var.cluster_name}-postgres-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.cluster_name}-postgres-subnet-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "postgres" {
  name        = "${var.cluster_name}-postgres-sg"
  description = "Allow PostgreSQL from EKS workers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.workers.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-postgres-sg"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier                      = "${var.cluster_name}-postgres"
  engine                          = "postgres"
  engine_version                  = "15.4"
  instance_class                  = var.db_instance_class
  allocated_storage               = 20
  max_allocated_storage           = 100
  storage_type                    = "gp3"
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  db_name                         = "taskdb"
  username                        = var.db_username
  password                        = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.postgres.name
  vpc_security_group_ids          = [aws_security_group.postgres.id]
  multi_az                        = var.db_multi_az
  publicly_accessible             = false
  skip_final_snapshot             = !var.db_deletion_protection
  final_snapshot_identifier       = var.db_deletion_protection ? "${var.cluster_name}-postgres-final" : null
  deletion_protection             = var.db_deletion_protection
  backup_retention_period         = var.db_backup_retention_days
  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.cluster_name}-postgres"
    Environment = var.environment
  }
}

