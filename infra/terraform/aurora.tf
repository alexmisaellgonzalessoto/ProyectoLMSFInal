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

#Guardar credenciales en Secrets Manager
resource "aws_secretsmanager_secret" "aurora_credentials" {
  name        = "lms/aurora/credentials-${var.environment}"
  description = "Credenciales de Aurora MySQL para LMS"

  tags = {
    Name        = "lms-aurora-credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "aurora_credentials_version" {
  secret_id = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username = var.aurora_master_username
    password = random_password.aurora_master_password.result
    engine   = "mysql"
    host     = aws_rds_cluster.aurora_cluster.endpoint
    port     = 3306
    dbname   = var.aurora_database_name
  })
}

# AURORA CLUSTER, CONFIGURACION PRINCIPAL
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "lms-aurora-cluster-${var.environment}"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.04.0"  # Aurora MySQL 3.x (compatible con MySQL 8.0)
  database_name           = var.aurora_database_name
  master_username         = var.aurora_master_username
  master_password         = random_password.aurora_master_password.result
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  
# Backups automáticos
  backup_retention_period = var.environment == "prod" ? 7 : 1
  preferred_backup_window = "03:00-04:00" 

  # Protección contra eliminación accidental (solo prod)
  deletion_protection = var.environment == "prod" ? true : false

  # Habilitar logs
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = {
    Name        = "lms-aurora-cluster"
    Environment = var.environment
  }
}

# IAM Role para Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "lms-rds-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "lms-rds-monitoring-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms para Aurora
resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "lms-aurora-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU de Aurora superó 80%"
  alarm_actions       = []  #No olvidar agregar sns topic para notificaciones ps amiguito

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster.cluster_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections_high" {
  alarm_name          = "lms-aurora-connections-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "500"
  alarm_description   = "Conexiones de Aurora superaron 500"
  alarm_actions       = []  # lo mismo de arriba en la 142 xD

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster.cluster_identifier
  }
}