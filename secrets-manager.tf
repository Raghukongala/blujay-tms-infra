resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${var.cluster_name}/postgres"
  description             = "PostgreSQL credentials for task-service"
  recovery_window_in_days = 7

  tags = { Name = "${var.cluster_name}-postgres-secret", Environment = var.environment }
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = "taskdb"
    url      = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/taskdb"
  })
}

resource "aws_secretsmanager_secret" "mongo" {
  name                    = "${var.cluster_name}/mongo"
  description             = "DocumentDB credentials for user-service"
  recovery_window_in_days = 7

  tags = { Name = "${var.cluster_name}-mongo-secret", Environment = var.environment }
}

resource "aws_secretsmanager_secret_version" "mongo" {
  secret_id = aws_secretsmanager_secret.mongo.id
  secret_string = jsonencode({
    username = var.mongo_username
    password = var.mongo_password
    host     = aws_docdb_cluster.mongo.endpoint
    port     = 27017
    url      = "mongodb://${var.mongo_username}:${var.mongo_password}@${aws_docdb_cluster.mongo.endpoint}:27017/userdb?tls=true&tlsCAFile=rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  })
}

resource "aws_secretsmanager_secret" "redis" {
  name                    = "${var.cluster_name}/redis"
  description             = "Redis connection for notification-service"
  recovery_window_in_days = 7

  tags = { Name = "${var.cluster_name}-redis-secret", Environment = var.environment }
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host = aws_elasticache_replication_group.redis.primary_endpoint_address
    port = 6379
    url  = "rediss://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
  })
}

# ── IAM policy for EKS pods to read secrets ─────────────────────

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.cluster_name}-secrets-read-policy"
  description = "Allow EKS pods to read app secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        aws_secretsmanager_secret.postgres.arn,
        aws_secretsmanager_secret.mongo.arn,
        aws_secretsmanager_secret.redis.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_secrets_read" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = aws_iam_policy.secrets_read.arn
}
