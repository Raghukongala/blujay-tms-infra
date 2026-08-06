resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.cluster_name}-redis-subnet-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.cluster_name}-redis-sg"
  description = "Allow Redis from EKS workers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
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
    Name        = "${var.cluster_name}-redis-sg"
    Environment = var.environment
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.cluster_name}-redis"
  description                = "Redis for notification-service"
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_ha_enabled ? 2 : 1
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = var.redis_ha_enabled

  tags = {
    Name        = "${var.cluster_name}-redis"
    Environment = var.environment
  }
}
