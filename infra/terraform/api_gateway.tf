resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Gateway para LMS - Integración Lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name        = "lms-api"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "learning-events"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}
#Metodo post para publicar eventos chi cheñol
resource "aws_api_gateway_method" "post_learning_event" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "AWS_IAM"
  api_key_required = true
}

#integracion con lambda jejeje
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.post_learning_event.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.learning_events_lambda.invoke_arn
}

#Api deploymet omgg
resource "aws_api_gateway_deployment" "lms_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource.id,
      aws_api_gateway_method.post_learning_event.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/lms-${var.environment}"
  retention_in_days = 365

  tags = {
    Name        = "lms-apigw-access-logs"
    Environment = var.environment
  }
}


resource "aws_api_gateway_stage" "lms_stage" {
  deployment_id         = aws_api_gateway_deployment.lms_deployment.id
  rest_api_id           = aws_api_gateway_rest_api.api.id
  stage_name            = var.environment
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"
  # Security baseline: mandatory for CKV_AWS_73
  xray_tracing_enabled  = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      userAgent      = "$context.identity.userAgent"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  tags = {
    Name        = "lms-api-${var.environment}"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_cloudwatch_log_group.api_gateway_access_logs]
}

resource "aws_api_gateway_method_settings" "lms_all_methods" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.lms_stage.stage_name
  method_path = "*/*"

  settings {
    caching_enabled      = true
    cache_ttl_in_seconds = 300
  }
}
#Ess necesario poner esto para la autenticacion con cognito profe?
#resource "aws_api_gateway_authorizer" "jwt_auth" {
# name            = "lms-jwt-authorizer"
#rest_api_id     = aws_api_gateway_rest_api.lms_api.id
#type            = "COGNITO_USER_POOLS"
#provider_arns   = [aws_cognito_user_pool.lms_users.arn]
