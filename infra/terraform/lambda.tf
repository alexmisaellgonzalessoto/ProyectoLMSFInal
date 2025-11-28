# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # CAMBIAR ESTO POR TU VAR.MYREGION source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "aws_lambda_function" "learning_events_lambda" {
  filename      = "lambda.zip"
  function_name = "lms-learning-events-publisher"
  role          = aws_iam_role.lms_lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256
  
  # VPC Configuration para conectarse a Aurora
  vpc_config {
    subnet_ids         = local.private_subnet_ids  # Mismas subnets que Aurora
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  
  environment {
    variables = {
      ENVIRONMENT       = var.environment
      EVENT_BUS_NAME    = "lms-events-bus"
      DB_SECRET_ARN     = aws_secretsmanager_secret.aurora_credentials.arn
      DB_HOST           = aws_rds_cluster.aurora_cluster.endpoint
      DB_NAME           = "lms_database"
    }
  }
}

#funcion lambda para procesar archivos subidos del s3
resource "aws_lambda_function" "process_submission" {
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

# Permiso para que S3 invoque Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_submission.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.student_submissions.arn
}

#PROCESAR NOTIFICACIONES
resource "aws_lambda_function" "notification_processor" {
  filename         = "notification_processor.zip"
  function_name    = "lms-notification-processor-${var.environment}"
  role             = aws_iam_role.lms_lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 50
  memory_size      = 256
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

#SQS + Lambda
resource "aws_lambda_event_source_mapping" "notifications_trigger" {
  event_source_arn                   = aws_sqs_queue.notifications.arn
  function_name                      = aws_lambda_function.notification_processor.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  
  function_response_types = ["ReportBatchItemFailures"]
}

#PROCESAR EMAILS
resource "aws_lambda_function" "email_processor" {
  filename         = "email_processor.zip"
  function_name    = "lms-email-processor-${var.environment}"
  role             = aws_iam_role.lms_lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 50
  memory_size      = 256
  reserved_concurrent_executions = 5

  environment {
    variables = {
      ENVIRONMENT   = var.environment
      SES_FROM_EMAIL   = var.ses_from_email
    }
  }

  tags = {
    Name        = "lms-email-processor"
    Environment = var.environment
  }
}

#TRIGGER PARA EMAILS
resource "aws_lambda_event_source_mapping" "emails_trigger" {
  event_source_arn                   = aws_sqs_queue.emails.arn
  function_name                      = aws_lambda_function.email_processor.arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 3
  
  function_response_types = ["ReportBatchItemFailures"]
}
#SNS TOPIC PARA NOTIFICAIONES 
resource "aws_sns_topic" "notifications" {
  name = "lms-notifications-topic-${var.environment}"

  tags = {
    Name        = "lms-notifications-topic"
    Environment = var.environment
    Purpose     = "SNS Topic for notifications"
  }
}