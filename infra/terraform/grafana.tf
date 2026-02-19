resource "aws_grafana_workspace" "lms" {
  count = var.enable_grafana ? 1 : 0

  name                     = "lms-grafana-${var.environment}"
  description              = "Workspace de Grafana para monitoreo del LMS"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = var.grafana_authentication_providers
  permission_type          = "SERVICE_MANAGED"
  data_sources             = var.grafana_data_sources

  tags = {
    Name        = "lms-grafana"
    Environment = var.environment
  }
}
