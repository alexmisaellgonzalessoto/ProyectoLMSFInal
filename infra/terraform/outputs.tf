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
  description = "LMSDB"
  value       = aws_rds_cluster.aurora_cluster.database_name
}

output "aurora_secret_arn" {
  description = "ARN del secret con credenciales de Aurora"
  value       = aws_secretsmanager_secret.aurora_credentials.arn
  sensitive   = true
}

#OUTPUTS S3
output "certificates_bucket_name" {
  description = "Bucket certificados"
  value       = aws_s3_bucket.certificates.id
}

output "educational_resources_bucket_name" {
  description = "Bucket recursos educativos"
  value       = aws_s3_bucket.educational_resources.id
}

output "student_submissions_bucket_name" {
  description = "Bucket tareas de los estudiantes"
  value       = aws_s3_bucket.student_submissions.id
}

output "backups_bucket_name" {
  description = "Bucket de backups"
  value       = aws_s3_bucket.backups.id
}

#output "s3_kms_key_arn" {
  #description = "ARN de la KMS key para S3"
  #value       = aws_kms_key.s3_kms.arn
#}