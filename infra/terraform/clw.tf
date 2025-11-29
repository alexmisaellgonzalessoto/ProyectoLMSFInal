resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/lms-frontend-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "lms-frontend-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/lms-backend-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "lms-backend-logs"
    Environment = var.environment
  }
}

## Alarma para saber que algo falla
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "lms-dlq-messages-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Hay mensajes en la Dead Letter Queue"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.notifications_dlq.name
  }
}

# Alarma para cola de notificaiones llena 
resource "aws_cloudwatch_metric_alarm" "queue_too_full" {
  alarm_name          = "lms-queue-backlog-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "La cola de notificaciones tiene más de 1000 mensajes pendientes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.notifications.name
  }
}
