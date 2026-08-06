data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS PostgreSQL encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${var.cluster_name}-rds-kms", Environment = var.environment }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.cluster_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_kms_key" "docdb" {
  description             = "KMS key for DocumentDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${var.cluster_name}-docdb-kms", Environment = var.environment }
}

resource "aws_kms_alias" "docdb" {
  name          = "alias/${var.cluster_name}-docdb"
  target_key_id = aws_kms_key.docdb.key_id
}

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${var.cluster_name}-eks-kms", Environment = var.environment }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch log encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudWatch Logs"
        Effect    = "Allow"
        Principal = { Service = "logs.${var.aws_region}.amazonaws.com" }
        Action    = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
        Resource  = "*"
      }
    ]
  })

  tags = { Name = "${var.cluster_name}-cloudwatch-kms", Environment = var.environment }
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.cluster_name}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}
