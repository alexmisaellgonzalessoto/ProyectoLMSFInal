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
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "learning-events"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}
#Metodo post para publicar eventos chi cheñol
resource "aws_api_gateway_method" "post_learning_event" {
  rest_api_id   = aws_api_gateway_rest_api.lms_api.id
  resource_id   = aws_api_gateway_resource.learning_events.id
  http_method   = "POST"
  authorization = "NONE"
  authorizer_id = aws_api_gateway_authorizer.lms_jwt_auth.id
}

resource "aws_api_gateway_integration" "MyDemoIntegration" {
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id
  resource_id = aws_api_gateway_resource.MyDemoResource.id
  http_method = aws_api_gateway_method.MyDemoMethod.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  
  depends_on = [
    aws_api_gateway_integration.integration
  ]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}
resource "aws_api_gateway_authorizer" "jwt_auth" {
  name            = "lms-jwt-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.lms_api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.lms_users.arn]
}