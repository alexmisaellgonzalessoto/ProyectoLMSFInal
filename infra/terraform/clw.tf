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
