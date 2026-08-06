resource "aws_docdb_subnet_group" "mongo" {
  name       = "${var.cluster_name}-docdb-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.cluster_name}-docdb-subnet-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "mongo" {
  name        = "${var.cluster_name}-mongo-sg"
  description = "Allow DocumentDB from EKS workers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 27017
    to_port         = 27017
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
    Name        = "${var.cluster_name}-mongo-sg"
    Environment = var.environment
  }
}

resource "aws_docdb_cluster" "mongo" {
  cluster_identifier              = "${var.cluster_name}-docdb"
  engine                          = "docdb"
  master_username                 = var.mongo_username
  master_password                 = var.mongo_password
  db_subnet_group_name            = aws_docdb_subnet_group.mongo.name
  vpc_security_group_ids          = [aws_security_group.mongo.id]
  skip_final_snapshot             = !var.docdb_deletion_protection
  final_snapshot_identifier       = var.docdb_deletion_protection ? "${var.cluster_name}-docdb-final" : null
  deletion_protection             = var.docdb_deletion_protection
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.docdb.arn
  backup_retention_period         = var.docdb_backup_retention_days
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  tags = {
    Name        = "${var.cluster_name}-docdb"
    Environment = var.environment
  }
}

resource "aws_docdb_cluster_instance" "mongo" {
  count              = 1
  identifier         = "${var.cluster_name}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.mongo.id
  instance_class     = var.docdb_instance_class

  tags = {
    Name        = "${var.cluster_name}-docdb-${count.index}"
    Environment = var.environment
  }
}
