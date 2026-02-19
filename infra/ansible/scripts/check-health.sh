#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../../terraform" && pwd)"

echo "Health check LMS (${ENVIRONMENT})"

ALB_DNS="$(cd "${TERRAFORM_DIR}" && terraform output -raw alb_dns_name)"
CLUSTER_NAME="$(cd "${TERRAFORM_DIR}" && terraform output -raw ecs_cluster_name)"
DB_HOST="$(cd "${TERRAFORM_DIR}" && terraform output -raw aurora_cluster_endpoint)"
DB_SECRET_ARN="$(cd "${TERRAFORM_DIR}" && terraform output -raw aurora_secret_arn)"

echo -n "ALB /health: "
if curl -sf "http://${ALB_DNS}/health" >/dev/null; then
  echo "OK"
else
  echo "FAIL"
fi

echo -n "Backend /api/health: "
if curl -sf "http://${ALB_DNS}/api/health" >/dev/null; then
  echo "OK"
else
  echo "FAIL"
fi

for SERVICE in "lms-frontend-service-${ENVIRONMENT}" "lms-backend-service-${ENVIRONMENT}"; do
  RUNNING="$(aws ecs describe-services --cluster "${CLUSTER_NAME}" --services "${SERVICE}" --query 'services[0].runningCount' --output text)"
  DESIRED="$(aws ecs describe-services --cluster "${CLUSTER_NAME}" --services "${SERVICE}" --query 'services[0].desiredCount' --output text)"
  echo "${SERVICE}: ${RUNNING}/${DESIRED} running"
done

DB_USER="$(aws secretsmanager get-secret-value --secret-id "${DB_SECRET_ARN}" --query 'SecretString' --output text | jq -r .username)"
DB_PASS="$(aws secretsmanager get-secret-value --secret-id "${DB_SECRET_ARN}" --query 'SecretString' --output text | jq -r .password)"

echo -n "Aurora DB: "
if mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" -e "SELECT 1" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAIL"
fi

echo "URL base: http://${ALB_DNS}"
