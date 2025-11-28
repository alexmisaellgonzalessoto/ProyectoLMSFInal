#DEAD LETTER QUEUE
resource "aws_sqs_queue" "notification_dlq" {
  name                      = "lms-notification-dlq-${var.environment}"
  message_retention_seconds = 1209600  # 14 days
}
#COLA PRINCIPAL PARA LAS NOTIFICACIONES
resource "aws_sqs_queue" "notifications" {
  name                       = "lms-notifications-queue-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144  
  message_retention_seconds  = 345600  
  receive_wait_time_seconds  = 10      
  visibility_timeout_seconds = 300    

  # Dead Letter Queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 3 
  })

  tags = {
    Name        = "lms-notifications-queue"
    Environment = var.environment
    Purpose     = "Main notification queue"
  }
}