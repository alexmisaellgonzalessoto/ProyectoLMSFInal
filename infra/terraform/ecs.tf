resource "aws_ecs_cluster" "lms_cluster" {
  name = "lms-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "lms-cluster"
    Environment = var.environment
  }
}

resource "aws_ecs_cluster_capacity_providers" "lms_capacity" {
  cluster_name = aws_ecs_cluster.lms_cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

#Security Group para ECS Fargate Tasks
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "lms-ecs-tasks-sg-${var.environment}"
  description = "Security group para ECS Fargate tasks"
  vpc_id      = local.vpc_id

ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Backend API from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Salida a internet (para descargar imágenes Docker, APIs externas)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "lms-ecs-tasks-sg"
    Environment = var.environment
  }
}

# Actualizar Security Group de Aurora para permitir ECS
resource "aws_security_group_rule" "aurora_from_ecs" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora_sg.id
  source_security_group_id = aws_security_group.ecs_tasks_sg.id
  description              = "MySQL from ECS Tasks"
}
