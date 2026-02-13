resource "aws_security_group" "apigw_vpc_link_sg" {
  count       = var.enable_http_api_vpc_link ? 1 : 0
  name        = "lms-apigw-vpclink-sg-${var.environment}"
  description = "Security group para ENIs de API Gateway VPC Link"
  vpc_id      = aws_vpc.lms_vpc.id

  egress {
    description = "Allow HTTP only within VPC CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lms_vpc.cidr_block]
  }

  egress {
    description = "Allow HTTPS only within VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lms_vpc.cidr_block]
  }

  tags = {
    Name        = "lms-apigw-vpclink-sg"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_vpc_link" "lms_vpc_link" {
  count              = var.enable_http_api_vpc_link ? 1 : 0
  name               = "lms-vpc-link-${var.environment}"
  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.apigw_vpc_link_sg[0].id]

  tags = {
    Name        = "lms-vpc-link"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_api" "lms_http_api" {
  count         = var.enable_http_api_vpc_link ? 1 : 0
  name          = "lms-http-api-${var.environment}"
  protocol_type = "HTTP"

  tags = {
    Name        = "lms-http-api"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_integration" "alb_integration" {
  count                  = var.enable_http_api_vpc_link ? 1 : 0
  api_id                 = aws_apigatewayv2_api.lms_http_api[0].id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = local.alb_listener_arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.lms_vpc_link[0].id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "default_route" {
  count              = var.enable_http_api_vpc_link ? 1 : 0
  api_id             = aws_apigatewayv2_api.lms_http_api[0].id
  route_key          = "$default"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.alb_integration[0].id}"
}

resource "aws_cloudwatch_log_group" "http_api_access_logs" {
  count             = var.enable_http_api_vpc_link ? 1 : 0
  name              = "/aws/apigatewayv2/lms-http-${var.environment}"
  retention_in_days = 365

  tags = {
    Name        = "lms-http-api-access-logs"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_stage" "default_stage" {
  count       = var.enable_http_api_vpc_link ? 1 : 0
  api_id      = aws_apigatewayv2_api.lms_http_api[0].id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.http_api_access_logs[0].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "lms-http-api-stage"
    Environment = var.environment
  }
}
