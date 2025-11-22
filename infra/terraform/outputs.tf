output "alb_dns_name" {
  description = "DNS name del ALB"
  value       = aws_lb.lms_alb.dns_name
}

output "alb_arn" {
  description = "ARN del ALB"
  value       = aws_lb.lms_alb.arn
}

output "frontend_target_group_arn" {
  description = "ARN del Target Group Frontend"
  value       = aws_lb_target_group.frontend.arn
}

output "backend_target_group_arn" {
  description = "ARN del Target Group Backend"
  value       = aws_lb_target_group.backend.arn
}