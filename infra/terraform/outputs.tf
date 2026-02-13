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

output "auth_target_group_arn" {
  description = "ARN del Target Group Auth"
  value       = aws_lb_target_group.auth.arn
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

#OUTPUTS ECS
output "ecs_cluster_name" {
  description = "Cluster ECS"
  value       = aws_ecs_cluster.lms_cluster.name
}
output "frontend_service_name" {
  description = "ECS front"
  value       = aws_ecs_service.frontend_service.name
}
output "backend_service_name" {
  description = "ECS Back"
  value       = aws_ecs_service.backend_service.name
}

output "auth_service_name" {
  description = "ECS Auth"
  value       = aws_ecs_service.auth_service.name
}

output "image_worker_service_name" {
  description = "ECS Image Worker"
  value       = aws_ecs_service.image_worker_service.name
}

#OUTPUTS SQS Y SNS

output "notifications_queue_url" {
  description = "URL de la cola de notificaciones"
  value       = aws_sqs_queue.notifications.url
}

output "notifications_queue_arn" {
  description = "ARN de la cola de notificaciones"
  value       = aws_sqs_queue.notifications.arn
}

output "emails_queue_url" {
  description = "URL de la cola de emails"
  value       = aws_sqs_queue.emails.url
}

output "image_processing_queue_url" {
  description = "URL de la cola de procesamiento de imagenes"
  value       = aws_sqs_queue.image_processing.url
}

output "dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.notifications_dlq.url
}

output "sns_topic_arn" {
  description = "ARN del topic SNS de notificaciones"
  value       = aws_sns_topic.notifications.arn
}

#OUTPUTS PARA CLW MONITOREO
output "dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.myregion}#dashboards:name=${aws_cloudwatch_dashboard.lms_main.dashboard_name}"
}

output "alarm_names" {
  description = "Nombres de todas las alarmas creadas"
  value = [
    aws_cloudwatch_metric_alarm.frontend_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.backend_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.aurora_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name
  ]
}

output "http_api_vpc_link_url" {
  description = "URL de API Gateway HTTP API con VPC Link hacia ALB"
  value       = var.enable_http_api_vpc_link ? aws_apigatewayv2_api.lms_http_api[0].api_endpoint : null
}
