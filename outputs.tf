output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_ca" {
  description = "EKS cluster CA certificate (base64)"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for all services"
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/taskdb"
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_connection_string" {
  description = "Redis TLS connection string"
  value       = "rediss://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
}

output "mongo_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.mongo.endpoint
}

output "mongo_connection_string" {
  description = "DocumentDB connection string"
  value       = "mongodb://${var.mongo_username}:${var.mongo_password}@${aws_docdb_cluster.mongo.endpoint}:27017/userdb?tls=true&tlsCAFile=rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  sensitive   = true
}
