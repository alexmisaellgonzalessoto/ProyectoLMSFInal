output "alb_dns_name" {
  description = "DNS name del ALB"
  value       = aws_lb.lms_alb.dns_name
}

output "alb_arn" {
  description = "ARN del ALB"
  value       = aws_lb.lms_alb.arn
}

output "frontend_target_group_arn" {
  description = "ARN del Target Group Frontend"
  value       = aws_lb_target_group.frontend.arn
}

output "backend_target_group_arn" {
  description = "ARN del Target Group Backend"
  value       = aws_lb_target_group.backend.arn
}

#OUTPUTS AURORA
output "aurora_cluster_endpoint" {
  description = "Endpoint del cluster Aurora (escritura)"
  value       = aws_rds_cluster.aurora_cluster.endpoint
  sensitive   = true
}

output "aurora_reader_endpoint" {
  description = "Endpoint de lectura de Aurora"
  value       = aws_rds_cluster.aurora_cluster.reader_endpoint
  sensitive   = true
}

output "aurora_database_name" {
  description = "Nombre de la base de datos"
  value       = aws_rds_cluster.aurora_cluster.database_name
}

output "aurora_secret_arn" {
  description = "ARN del secret con credenciales de Aurora"
  value       = aws_secretsmanager_secret.aurora_credentials.arn
  sensitive   = true
}

#OUTPUTS S3
output "certificates_bucket_name" {
  description = "Nombre del bucket de certificados"
  value       = aws_s3_bucket.certificates.id
}

output "educational_resources_bucket_name" {
  description = "Nombre del bucket de recursos educativos"
  value       = aws_s3_bucket.educational_resources.id
}

output "student_submissions_bucket_name" {
  description = "Nombre del bucket de tareas de estudiantes"
  value       = aws_s3_bucket.student_submissions.id
}

output "backups_bucket_name" {
  description = "Nombre del bucket de backups"
  value       = aws_s3_bucket.backups.id
}