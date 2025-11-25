resource "aws_security_group" "aurora_sg" {
  name        = "lms-aurora-sg"
  description = "Security group for Aurora cluster"
  vpc_id      = local.vpc_id

#Fargate
  ingress {
    description      = "MySQL para el ECS"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
  #MySQL desde Lambda
    ingress {
        description = "MySQL para Lambda"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.lambda_sg.id]
    }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "lms-aurora-sg"
        Environment = var.environment
    }
}

#Subnet group para Aurora
resource "aws_bd_subnet_group" "aurora_subnet_group" {
    name       = "lms-aurora-subnet-group- ${var.environment}"
    subnet_ids = local.private_subnet_ids
    tags = {
        Name = "lms-aurora-subnet-group"
        Environment = var.environment
    }
}

#generar contraseñas para aurora asi todas insanas
resource "random_password" "aurora_password" {
  length           = 32
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}
