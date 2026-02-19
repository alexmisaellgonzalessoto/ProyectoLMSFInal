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

  ingress {
    description     = "Auth API from ALB"
    from_port       = 3001
    to_port         = 3001
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

#TAREA FRONTEND
resource "aws_ecs_task_definition" "frontend" {
  family                   = "lms-frontend-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "REACT_APP_API_URL"
          value = "https://${var.domain_name}/api"
        },
        {
          name  = "REACT_APP_ENVIRONMENT"
          value = var.environment
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_logs.name
          "awslogs-region"        = var.myregion
          "awslogs-stream-prefix" = "frontend"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "lms-frontend-task"
    Environment = var.environment
  }
}

#TAREA BACKEND
resource "aws_ecs_task_definition" "backend" {
  family                   = "lms-backend-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      command   = ["sh", "-c", "node -e 'require(\"http\").createServer((req,res)=>{if(req.url===\"/health\"){res.statusCode=200;res.end(\"ok\");return;}res.statusCode=200;res.setHeader(\"Content-Type\",\"application/json\");res.end(JSON.stringify({service:\"backend\",status:\"running\"}));}).listen(8000,\"0.0.0.0\")'"]

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "8000"
        },
        {
          name  = "DB_HOST"
          value = aws_rds_cluster.aurora_cluster.endpoint
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = var.aurora_database_name
        },
        {
          name  = "S3_CERTIFICATES_BUCKET"
          value = aws_s3_bucket.certificates.id
        },
        {
          name  = "S3_RESOURCES_BUCKET"
          value = aws_s3_bucket.educational_resources.id
        },
        {
          name  = "S3_SUBMISSIONS_BUCKET"
          value = aws_s3_bucket.student_submissions.id
        },
        {
          name  = "AWS_REGION"
          value = var.myregion
        },
        {
          name  = "SNS_TOPIC_ARN"
          value = aws_sns_topic.notifications.arn
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_replication_group.redis.primary_endpoint_address
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.aurora_credentials.arn}:password::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.aurora_credentials.arn}:username::"
        },
        {
          name      = "DB_PASS"
          valueFrom = "${aws_secretsmanager_secret.aurora_credentials.arn}:password::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.aurora_credentials.arn}:username::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
          "awslogs-region"        = var.myregion
          "awslogs-stream-prefix" = "backend"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "lms-backend-task"
    Environment = var.environment
  }
}

#TAREA AUTH
resource "aws_ecs_task_definition" "auth" {
  family                   = "lms-auth-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.auth_cpu
  memory                   = var.auth_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "auth"
      image     = var.auth_image
      essential = true

      portMappings = [
        {
          containerPort = 3001
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "3001"
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_replication_group.redis.primary_endpoint_address
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
          "awslogs-region"        = var.myregion
          "awslogs-stream-prefix" = "auth"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3001/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "lms-auth-task"
    Environment = var.environment
  }
}

#ECS SERVICE FRONTED
resource "aws_ecs_service" "frontend_service" {
  name            = "lms-frontend-service-${var.environment}"
  cluster         = aws_ecs_cluster.lms_cluster.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  tags = {
    Name        = "lms-frontend-service"
    Environment = var.environment
  }
}
#ECS SERVICE BACKEND
resource "aws_ecs_service" "backend_service" {
  name            = "lms-backend-service-${var.environment}"
  cluster         = aws_ecs_cluster.lms_cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  tags = {
    Name        = "lms-backend-service"
    Environment = var.environment
  }
}

#ECS SERVICE AUTH
resource "aws_ecs_service" "auth_service" {
  name            = "lms-auth-service-${var.environment}"
  cluster         = aws_ecs_cluster.lms_cluster.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = var.auth_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth.arn
    container_name   = "auth"
    container_port   = 3001
  }

  tags = {
    Name        = "lms-auth-service"
    Environment = var.environment
  }
}

#TAREA WORKER
resource "aws_ecs_task_definition" "image_worker" {
  family                   = "lms-image-worker-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "image-worker"
      image     = var.worker_image
      essential = true

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.myregion
        },
        {
          name  = "IMAGE_QUEUE_URL"
          value = aws_sqs_queue.image_processing.url
        },
        {
          name  = "SUBMISSIONS_BUCKET"
          value = aws_s3_bucket.student_submissions.id
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
          "awslogs-region"        = var.myregion
          "awslogs-stream-prefix" = "image-worker"
        }
      }
    }
  ])

  tags = {
    Name        = "lms-image-worker-task"
    Environment = var.environment
  }
}

#ECS SERVICE WORKER
resource "aws_ecs_service" "image_worker_service" {
  name            = "lms-image-worker-service-${var.environment}"
  cluster         = aws_ecs_cluster.lms_cluster.id
  task_definition = aws_ecs_task_definition.image_worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  tags = {
    Name        = "lms-image-worker-service"
    Environment = var.environment
  }
}

#AUTOSCALING FRONTEND
resource "aws_appautoscaling_policy" "frontend_cpu_scaling" {
  name               = "lms-frontend-cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_target" "frontend_target" {
  max_capacity       = var.frontend_max_capacity
  min_capacity       = var.frontend_min_capacity
  resource_id        = "service/${aws_ecs_cluster.lms_cluster.name}/${aws_ecs_service.frontend_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


#AUTOSCALING BACKEND
resource "aws_appautoscaling_policy" "backend_cpu_scaling" {
  name               = "lms-backend-cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_target" "backend_target" {
  max_capacity       = var.backend_max_capacity
  min_capacity       = var.backend_min_capacity
  resource_id        = "service/${aws_ecs_cluster.lms_cluster.name}/${aws_ecs_service.backend_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

#AUTOSCALING WORKER POR COLA SQS
resource "aws_appautoscaling_target" "worker_target" {
  max_capacity       = var.worker_max_capacity
  min_capacity       = var.worker_min_capacity
  resource_id        = "service/${aws_ecs_cluster.lms_cluster.name}/${aws_ecs_service.image_worker_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "worker_sqs_scaling" {
  name               = "lms-worker-sqs-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.worker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker_target.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Average"

      dimensions {
        name  = "QueueName"
        value = aws_sqs_queue.image_processing.name
      }
    }

    target_value       = 5
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}
