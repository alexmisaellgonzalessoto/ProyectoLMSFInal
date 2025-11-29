#FUNCIONES LAMBDA Y LAMBDA ROLE
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid    = "AllowLambdaAssumeRole"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lms_lambda_role" {
  name               = "lms-lambda-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name        = "lms-lambda-role"
    Environment = var.environment
    Service     = "Lambda"
  }
}

#POLITICA PARA CLOUDWACTH LOGS
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lms_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#POLITICA PARA EL EVENTBRIDGE
data "aws_iam_policy_document" "lms_eventbridge_policy" {
  statement {
    sid    = "AllowPutEventsToLMSBus"
    effect = "Allow"
    
    actions = [
      "events:PutEvents"
    ]
    
    resources = [
      "arn:aws:events:${var.myregion}:${var.accountId}:event-bus/lms-events-bus"
    ]
  }
}

resource "aws_iam_role_policy" "lms_lambda_eventbridge" {
  name   = "lms-lambda-eventbridge-policy"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lms_eventbridge_policy.json
}

#POLITICA PARA MI QUERIDO S3
data "aws_iam_policy_document" "lms_s3_policy" {
  # Listar todos los buckets
  statement {
    sid    = "ListAllBuckets"
    effect = "Allow"
    
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]
    
    resources = [
      "arn:aws:s3:::*",
    ]
  }
# Listar contenido del bucket de certificados
  statement {
    sid    = "ListCertificatesBucket"
    effect = "Allow"
    
    actions = [
      "s3:ListBucket",
    ]
    
    resources = [
      "arn:aws:s3:::${var.lms_certificates_bucket}",
    ]
  }

  # Operaciones completas en el bucket de certificados
  statement {
    sid    = "ManageCertificates"
    effect = "Allow"
    
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    
    resources = [
      "arn:aws:s3:::${var.lms_certificates_bucket}/*",
    ]
  }

  # Acceso al bucket de recursos educativos (videos, PDFs, etc)
  statement {
    sid    = "AccessEducationalResources"
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    
    resources = [
      "arn:aws:s3:::${var.lms_resources_bucket}/*",
    ]
  }

  # Acceso a carpetas de usuarios (tareas enviadas por estudiantes)
  statement {
    sid    = "AccessStudentSubmissions"
    effect = "Allow"
    
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    
    resources = [
      "arn:aws:s3:::${var.lms_submissions_bucket}/students/*",
    ]
  }
}

resource "aws_iam_policy" "lms_s3_policy" {
  name        = "lms-s3-access-policy-${var.environment}"
  path        = "/"
  description = "Política para acceso a buckets S3 del LMS"
  policy      = data.aws_iam_policy_document.lms_s3_policy.json

  tags = {
    Name        = "lms-s3-policy"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lms_lambda_role.name
  policy_arn = aws_iam_policy.lms_s3_policy.arn
}

#POLITICA PARA SNS
data "aws_iam_policy_document" "lms_sns_policy" {
  statement {
    sid    = "AllowPublishToSNS"
    effect = "Allow"
    
    actions = [
      "sns:Publish",
    ]
    
    resources = [
      "arn:aws:sns:${var.myregion}:${var.accountId}:lms-notifications-topic"
    ]
  }
}

resource "aws_iam_role_policy" "lms_lambda_sns" {
  name   = "lms-lambda-sns-policy"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lms_sns_policy.json
}

#POLITICA PARA SQS
data "aws_iam_policy_document" "lms_sqs_policy" {
  statement {
    sid    = "AllowSQSOperations"
    effect = "Allow"
    
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    
    resources = [
      "arn:aws:sqs:${var.myregion}:${var.accountId}:lms-notifications-queue",
      "arn:aws:sqs:${var.myregion}:${var.accountId}:lms-notifications-dlq",
    ]
  }
}

resource "aws_iam_role_policy" "lms_lambda_sqs" {
  name   = "lms-lambda-sqs-policy"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lms_sqs_policy.json
}

#POLITICA PARA SES
data "aws_iam_policy_document" "lms_ses_policy" {
  statement {
    sid    = "AllowSendEmail"
    effect = "Allow"
    
    actions = [
      "ses:SendEmail",
      "ses:SendTemplatedEmail",
    ]
    
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lms_lambda_ses" {
  name   = "lms-lambda-ses-policy"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lms_ses_policy.json
}

#SECRET MANAGER PARA AURORA
data "aws_iam_policy_document" "lms_secrets_manager_policy" {
  statement {
    sid    = "AllowGetDatabaseCredentials"
    effect = "Allow"
    
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    
    resources = [
      "arn:aws:secretsmanager:${var.myregion}:${var.accountId}:secret:lms/aurora/credentials-*"
    ]
  }
}

resource "aws_iam_role_policy" "lms_lambda_secrets" {
  name   = "lms-lambda-secrets-manager-policy"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lms_secrets_manager_policy.json
}

#POLITICA PARA VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lms_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#TAREAS PARA ECS FARGATE
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    sid    = "AllowECSAssumeRole"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lms_ecs_task_role" {
  name               = "lms-ecs-task-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = {
    Name        = "lms-ecs-task-role"
    Environment = var.environment
    Service     = "ECS"
  }
}

#Política para que ECS pueda invocar Lambda
data "aws_iam_policy_document" "ecs_lambda_invoke" {
  statement {
    sid    = "AllowInvokeLambda"
    effect = "Allow"
    
    actions = [
      "lambda:InvokeFunction",
    ]
    
    resources = [
      "arn:aws:lambda:${var.myregion}:${var.accountId}:function:lms-*"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_lambda" {
  name   = "lms-ecs-lambda-invoke-policy"
  role   = aws_iam_role.lms_ecs_task_role.id
  policy = data.aws_iam_policy_document.ecs_lambda_invoke.json
}

#IAM ROLE PARA ECS task ajsjas yo soy rol
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "lms-ecs-task-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name        = "lms-ecs-task-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Política adicional para acceder a Secrets Manager
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "lms-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.aurora_credentials.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          aws_kms_key.aurora_kms.arn
        ]
      }
    ]
  })
}

# IAM Role para ECS Task (permisos de la aplicación en runtime)
resource "aws_iam_role" "ecs_task_role" {
  name               = "lms-ecs-task-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name        = "lms-ecs-task-role"
    Environment = var.environment
  }
}

# Políticas para el task role (acceso a S3, SQS, SNS, Lambda)
resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  name = "lms-ecs-s3-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.certificates.arn}/*",
          "${aws_s3_bucket.educational_resources.arn}/*",
          "${aws_s3_bucket.student_submissions.arn}/*",
          aws_s3_bucket.certificates.arn,
          aws_s3_bucket.educational_resources.arn,
          aws_s3_bucket.student_submissions.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_lambda_invoke" {
  name = "lms-ecs-lambda-invoke"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.learning_events_lambda.arn
        ]
      }
    ]
  })
}

#PERMISOS PARA LAMBDA
# Permiso para recibir mensajes de SQS
data "aws_iam_policy_document" "lambda_sqs_policy" {
  statement {
    sid    = "AllowSQSOperations"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]

    resources = [
      aws_sqs_queue.notifications.arn,
      aws_sqs_queue.emails.arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_sqs_access" {
  name   = "lms-lambda-sqs-access"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lambda_sqs_policy.json
}

# Permiso para publicar en SNS
data "aws_iam_policy_document" "lambda_sns_policy" {
  statement {
    sid    = "AllowSNSPublish"
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.notifications.arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_sns_access" {
  name   = "lms-lambda-sns-access"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lambda_sns_policy.json
}

# Permiso para enviar emails con SES
data "aws_iam_policy_document" "lambda_ses_policy" {
  statement {
    sid    = "AllowSESSend"
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
      "ses:SendTemplatedEmail"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_ses_access" {
  name   = "lms-lambda-ses-access"
  role   = aws_iam_role.lms_lambda_role.id
  policy = data.aws_iam_policy_document.lambda_ses_policy.json
}
