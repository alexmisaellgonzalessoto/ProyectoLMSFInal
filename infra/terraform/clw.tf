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

#Dashboard para monitoreo
resource "aws_cloudwatch_dashboard" "lms_main" {
  dashboard_name = "LMS-Main-Dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      #ECS Métricas
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average", label = "Frontend CPU" }],
            ["AWS/ECS", "MemoryUtilization", { stat = "Average", label = "Frontend Memory" }]
          ]
          period = 300
          stat   = "Average"
          region = var.myregion
          title  = "Frontend - CPU y Memoria"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average", label = "Backend CPU" }],
            ["AWS/ECS", "MemoryUtilization", { stat = "Average", label = "Backend Memory" }]
          ]
          period = 300
          stat   = "Average"
          region = var.myregion
          title  = "Backend - CPU y Memoria"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      },

      #ALB Métricas
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", label = "Total Requests" }],
            [".", "HTTPCode_Target_2XX_Count", { stat = "Sum", label = "Success (2xx)" }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum", label = "Client Errors (4xx)" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "Server Errors (5xx)" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.myregion
          title  = "ALB - Requests y Status Codes"
        }
        width  = 12
        height = 6
        x      = 0
        y      = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", label = "Response Time (avg)" }],
            ["...", { stat = "p99", label = "Response Time (p99)" }]
          ]
          period = 300
          region = var.myregion
          title  = "ALB - Response Time"
          yAxis = {
            left = {
              label = "Seconds"
            }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 6
      },

      #Aurora Database
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "CPU" }],
            [".", "DatabaseConnections", { stat = "Average", label = "Connections" }]
          ]
          period = 300
          stat   = "Average"
          region = var.myregion
          title  = "Aurora - CPU y Conexiones"
        }
        width  = 12
        height = 6
        x      = 0
        y      = 12
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "ReadLatency", { stat = "Average", label = "Read Latency" }],
            [".", "WriteLatency", { stat = "Average", label = "Write Latency" }]
          ]
          period = 300
          region = var.myregion
          title  = "Aurora - Latency"
          yAxis = {
            left = {
              label = "Milliseconds"
            }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 12
      },

      #Lambda y SQS
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Throttles", { stat = "Sum", label = "Throttles" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.myregion
          title  = "Lambda - Invocations y Errores"
        }
        width  = 12
        height = 6
        x      = 0
        y      = 18
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Average", label = "Messages in Queue" }],
            [".", "NumberOfMessagesSent", { stat = "Sum", label = "Messages Sent" }],
            [".", "NumberOfMessagesReceived", { stat = "Sum", label = "Messages Received" }]
          ]
          period = 300
          region = var.myregion
          title  = "SQS - Cola de Notificaciones"
        }
        width  = 12
        height = 6
        x      = 12
        y      = 18
      }
    ]
  })
}
