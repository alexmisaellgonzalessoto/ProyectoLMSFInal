resource "aws_security_group" "redis_sg" {
  name        = "lms-redis-sg-${var.environment}"
  description = "Security group para ElastiCache Redis"
  vpc_id      = aws_vpc.lms_vpc.id

  ingress {
    description     = "Redis desde ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "lms-redis-sg"
    Environment = var.environment
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "lms-redis-subnet-group-${var.environment}"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name        = "lms-redis-subnet-group"
    Environment = var.environment
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "lms-redis-${var.environment}"
  description                = "Redis para plataforma LMS"
  engine                     = "redis"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  automatic_failover_enabled = true
  multi_az_enabled           = true
  num_cache_clusters         = 2

  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids = [aws_security_group.redis_sg.id]

  at_rest_encryption_enabled = true
  apply_immediately          = true

  tags = {
    Name        = "lms-redis"
    Environment = var.environment
  }
}
