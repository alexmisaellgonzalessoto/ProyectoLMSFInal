resource "aws_wafv2_web_acl" "lms_waf" {
  count = var.enable_waf ? 1 : 0

  name  = "lms-waf-${var.environment}"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "lms-waf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "lms-waf-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "lms-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "lms-waf"
    Environment = var.environment
  }
}

resource "aws_wafv2_web_acl_association" "lms_alb_waf_assoc" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.lms_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.lms_waf[0].arn
}
