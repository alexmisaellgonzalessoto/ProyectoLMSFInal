data "aws_iam_policy_document" "grafana_assume_role" {
  count = var.enable_grafana ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "grafana_workspace_role" {
  count = var.enable_grafana ? 1 : 0

  name               = "lms-grafana-workspace-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role[0].json

  tags = {
    Name        = "lms-grafana-workspace-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch_access" {
  count = var.enable_grafana ? 1 : 0

  role       = aws_iam_role.grafana_workspace_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonGrafanaCloudWatchAccess"
}

resource "aws_iam_role_policy_attachment" "grafana_xray_access" {
  count = var.enable_grafana ? 1 : 0

  role       = aws_iam_role.grafana_workspace_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
}

resource "aws_grafana_workspace" "lms" {
  count = var.enable_grafana ? 1 : 0

  name                     = "lms-grafana-${var.environment}"
  description              = "Workspace de Grafana para monitoreo del LMS"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = var.grafana_authentication_providers
  permission_type          = "CUSTOMER_MANAGED"
  role_arn                 = aws_iam_role.grafana_workspace_role[0].arn
  data_sources             = var.grafana_data_sources

  tags = {
    Name        = "lms-grafana"
    Environment = var.environment
  }
}
