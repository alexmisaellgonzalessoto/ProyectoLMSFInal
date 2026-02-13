resource "aws_cloudwatch_event_bus" "lms_events_bus" {
  name = "lms-events-bus"

  tags = {
    Name        = "lms-events-bus"
    Environment = var.environment
  }
}
