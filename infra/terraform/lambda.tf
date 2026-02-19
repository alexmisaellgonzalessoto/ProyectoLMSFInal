resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.learning_events_lambda.function_name
  principal     = "apigateway.amazonaws.com"

}

resource "aws_security_group" "lambda_sg" {
  name        = "lms-lambda-sg-${var.environment}"
  description = "Security group para Lambda dentro de la VPC"
  vpc_id      = aws_vpc.lms_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "lms-lambda-sg"
    Environment = var.environment
  }
}

resource "aws_lambda_function" "learning_events_lambda" {
  filename      = "lambda.zip"
  function_name = "lms-learning-events-publisher"
  role          = aws_iam_role.lms_lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  vpc_config {
    subnet_ids         = local.private_subnet_ids 
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.lms_events_bus.name
      DB_SECRET_ARN  = aws_secretsmanager_secret.aurora_credentials.arn
      DB_HOST        = aws_rds_cluster.aurora_cluster.endpoint
      DB_NAME        = "lms_database"
    }
  }
}

resource "aws_lambda_function" "process_submission" {
  count         = var.enable_optional_lambdas ? 1 : 0
  filename      = "process_submission.zip"
  function_name = "lms-process-submission-${var.environment}"
  role          = aws_iam_role.lms_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 60

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name        = "lms-process-submission"
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  count         = var.enable_optional_lambdas ? 1 : 0
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_submission[0].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.student_submissions.arn
}

resource "aws_lambda_function" "notification_processor" {
  count                          = var.enable_optional_lambdas ? 1 : 0
  filename                       = "notification_processor.zip"
  function_name                  = "lms-notification-processor-${var.environment}"
  role                           = aws_iam_role.lms_lambda_role.arn
  handler                        = "index.handler"
  runtime                        = "python3.12"
  timeout                        = 50
  memory_size                    = 256
  reserved_concurrent_executions = 10

  environment {
    variables = {
      ENVIRONMENT   = var.environment
      SNS_TOPIC_ARN = aws_sns_topic.notifications.arn
    }
  }

  tags = {
    Name        = "lms-notification-processor"
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "trigger_notificaciones" {
  count                              = var.enable_optional_lambdas ? 1 : 0
  event_source_arn                   = aws_sqs_queue.notifications.arn
  function_name                      = aws_lambda_function.notification_processor[0].arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_function" "email_processor" {
  count                          = var.enable_optional_lambdas ? 1 : 0
  filename                       = "email_processor.zip"
  function_name                  = "lms-email-processor-${var.environment}"
  role                           = aws_iam_role.lms_lambda_role.arn
  handler                        = "index.handler"
  runtime                        = "python3.12"
  timeout                        = 50
  memory_size                    = 256
  reserved_concurrent_executions = 5

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      SES_FROM_EMAIL = var.ses_from_email
    }
  }

  tags = {
    Name        = "lms-email-processor"
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "emails_trigger" {
  count                              = var.enable_optional_lambdas ? 1 : 0
  event_source_arn                   = aws_sqs_queue.emails.arn
  function_name                      = aws_lambda_function.email_processor[0].arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 3

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_sns_topic" "notifications" {
  name = "lms-notifications-topic-${var.environment}"

  tags = {
    Name        = "lms-notifications-topic"
    Environment = var.environment
    Purpose     = "SNS Topic for notifications"
  }
}
