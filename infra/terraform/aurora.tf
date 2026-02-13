resource "aws_security_group" "aurora_sg" {
  name        = "lms-aurora-sg"
  description = "Security group for Aurora cluster"
  vpc_id      = local.vpc_id

  #MySQL desde Lambda
  ingress {
    description     = "MySQL para Lambda"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    description = "Allow HTTPS only within VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lms_vpc.cidr_block]
  }
  tags = {
    Name        = "lms-aurora-sg"
    Environment = var.environment
  }
}

#Subnet group para Aurora
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "lms-aurora-subnet-group- ${var.environment}"
  subnet_ids = local.private_subnet_ids
  tags = {
    Name        = "lms-aurora-subnet-group"
    Environment = var.environment
  }
}

#generar contraseñas para aurora asi todas insanas
resource "random_password" "aurora_password" {
  length  = 32
  special = true
  # RDS no permite '/', '@', '"' ni espacios en MasterUserPassword.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_kms_key" "aurora_kms" {
  description             = "KMS key para Aurora Performance Insights"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "lms-aurora-kms"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "aurora_kms_alias" {
  name          = "alias/lms-aurora-${var.environment}"
  target_key_id = aws_kms_key.aurora_kms.key_id
}

#Guardar credenciales en Secrets Manager
resource "aws_secretsmanager_secret" "aurora_credentials" {
  name        = "lms/aurora/credentials-${var.environment}-${var.accountId}"
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
    password = random_password.aurora_password.result
    engine   = "mysql"
    host     = aws_rds_cluster.aurora_cluster.endpoint
    port     = 3306
    dbname   = var.aurora_database_name
  })
}

# AURORA CLUSTER, CONFIGURACION PRINCIPAL
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier     = "lms-aurora-cluster-${var.environment}"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.04.0" # Aurora MySQL 3.x (compatible con MySQL 8.0)
  database_name          = var.aurora_database_name
  master_username        = var.aurora_master_username
  master_password        = random_password.aurora_password.result
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  # Backups automáticos
  backup_retention_period = var.environment == "prod" ? 7 : 1
  preferred_backup_window = "03:00-04:00"

  # Protección contra eliminación accidental (solo prod)
  deletion_protection       = var.environment == "prod" ? true : false
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "lms-aurora-final-${var.environment}-${formatdate("YYYYMMDDhhmmss", timestamp())}" : null

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
  alarm_actions       = [] #No olvidar agregar sns topic para notificaciones ps amiguito

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
  alarm_actions       = [] # lo mismo de arriba en la 142 xD

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster.cluster_identifier
  }
}

#Instancias aurora
#Escritura primero uwu
resource "aws_rds_cluster_instance" "aurora_writer" {
  identifier           = "lms-aurora-writer-${var.environment}"
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = var.aurora_instance_class
  engine               = aws_rds_cluster.aurora_cluster.engine
  engine_version       = aws_rds_cluster.aurora_cluster.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Performance Insights solo en prod para evitar incompatibilidades/costo en dev.
  performance_insights_enabled          = var.environment == "prod"
  performance_insights_kms_key_id       = var.environment == "prod" ? aws_kms_key.aurora_kms.arn : null
  performance_insights_retention_period = var.environment == "prod" ? 7 : null

  # Monitoreo avanzado
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  tags = {
    Name        = "lms-aurora-writer"
    Environment = var.environment
    Role        = "Writer"
  }
}

# Instancia de lectura
resource "aws_rds_cluster_instance" "aurora_reader" {
  count                = var.environment == "prod" ? 1 : 0
  identifier           = "lms-aurora-reader-${var.environment}-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = var.aurora_instance_class
  engine               = aws_rds_cluster.aurora_cluster.engine
  engine_version       = aws_rds_cluster.aurora_cluster.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Performance Insights solo en prod para evitar incompatibilidades/costo en dev.
  performance_insights_enabled          = var.environment == "prod"
  performance_insights_kms_key_id       = var.environment == "prod" ? aws_kms_key.aurora_kms.arn : null
  performance_insights_retention_period = var.environment == "prod" ? 7 : null

  # Monitoreo avanzado
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  tags = {
    Name        = "lms-aurora-reader-${count.index + 1}"
    Environment = var.environment
    Role        = "Reader"
  }
}
