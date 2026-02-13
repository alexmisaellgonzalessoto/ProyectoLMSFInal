#DEAD LETTER QUEUE
resource "aws_sqs_queue" "notifications_dlq" {
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

#COLA PARA LOS EMAILS
resource "aws_sqs_queue" "emails" {
  name                       = "lms-email-queue-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144  
  message_retention_seconds  = 345600  
  receive_wait_time_seconds  = 10      
  visibility_timeout_seconds = 300    

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 5 
  })

  tags = {
    Name        = "lms-email-queue"
    Environment = var.environment
    Purpose     = "Queue for email notifications"
  }
}

#POLITICA PARA ECS PUEDA ENVIAR MENSAJES
data "aws_iam_policy_document" "sqs_send_policy" {
  statement {
    sid    = "AllowECSSendMessages"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task_role.arn]
    }

    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]

    resources = [aws_sqs_queue.notifications.arn]
  }
}

data "aws_iam_policy_document" "sqs_send_policy_emails" {
  statement {
    sid    = "AllowECSSendMessages"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task_role.arn]
    }

    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]

    resources = [aws_sqs_queue.emails.arn]
  }
}

resource "aws_sqs_queue_policy" "notifications_policy" {
  queue_url = aws_sqs_queue.notifications.url
  policy    = data.aws_iam_policy_document.sqs_send_policy.json
}

resource "aws_sqs_queue_policy" "emails_policy" {
  queue_url = aws_sqs_queue.emails.url
  policy    = data.aws_iam_policy_document.sqs_send_policy_emails.json
}
