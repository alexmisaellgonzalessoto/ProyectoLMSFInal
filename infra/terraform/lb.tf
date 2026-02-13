resource "aws_security_group" "alb_sg" {
  name        = "lms-alb-sg"
  description = "Security group para ALB del LMS"
  vpc_id      = local.vpc_id

  # HTTP desde la VPC (API Gateway VPC Link / servicios internos)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lms_vpc.cidr_block]
  }

  # HTTPS desde la VPC (opcional)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lms_vpc.cidr_block]
  }

  # Salida a ECS Fargate
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lms-alb-sg"
  }
}

# ALB
resource "aws_lb" "lms_alb" {
  name               = "lms-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.private_subnet_ids

  enable_deletion_protection = false #Cambiar a true en producción

  tags = {
    Name        = "lms-alb"
    Environment = var.environment
  }
}

# Frontend
resource "aws_lb_target_group" "frontend" {
  name        = "lms-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip" # Para Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "lms-frontend-tg"
  }
}

#Backend API
resource "aws_lb_target_group" "backend" {
  name        = "lms-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip" # Para Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "lms-backend-tg"
  }
}

# Listener HTTP cuando HTTPS no está habilitado
resource "aws_lb_listener" "http_forward" {
  count             = var.enable_https_listener ? 0 : 1
  load_balancer_arn = aws_lb.lms_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Listener HTTP redirigiendo a HTTPS cuando está habilitado
resource "aws_lb_listener" "http_redirect" {
  count             = var.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.lms_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener HTTPS opcional
resource "aws_lb_listener" "https" {
  count             = var.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.lms_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Listener Rule - Rutas /api/* al Backend
resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = local.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# Listener Rule - WebSocket para notificaciones en tiempo real
resource "aws_lb_listener_rule" "websocket" {
  listener_arn = local.alb_listener_arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/ws/*"]
    }
  }
}

locals {
  vpc_id = aws_vpc.lms_vpc.id # En lugar de var.vpc_id

  subnets = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  alb_listener_arn = var.enable_https_listener ? aws_lb_listener.https[0].arn : aws_lb_listener.http_forward[0].arn
}
