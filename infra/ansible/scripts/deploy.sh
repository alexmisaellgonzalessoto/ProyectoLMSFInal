#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
ACTION="${2:-deploy}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="$(cd "${ANSIBLE_DIR}/../terraform" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
  log_info "Validando prerrequisitos"

  local commands=("aws" "docker" "terraform" "ansible-playbook")
  for cmd in "${commands[@]}"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      log_error "${cmd} no esta instalado"
      exit 1
    fi
  done

  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    log_error "No hay sesion activa en AWS"
    exit 1
  fi
}

provision_infrastructure() {
  log_info "Provisionando infraestructura con Terraform (${ENVIRONMENT})"
  cd "${TERRAFORM_DIR}"

  terraform init
  terraform validate
  terraform plan -var="environment=${ENVIRONMENT}" -out=tfplan

  read -r -p "Aplicar este plan? (s/n): " reply
  if [[ "${reply}" =~ ^[Ss]$ ]]; then
    terraform apply tfplan
    log_info "Infraestructura aplicada"
  else
    log_warn "Se omitio terraform apply"
  fi
}

configure_systems() {
  log_info "Aplicando configuracion con Ansible (${ENVIRONMENT})"
  cd "${ANSIBLE_DIR}"

  ansible-galaxy collection install -r requirements.yml
  ansible-playbook playbook.yaml \
    -e "env=${ENVIRONMENT}" \
    -e "build_frontend=true" \
    -e "build_backend=true" \
    -e "deploy_frontend=true" \
    -e "deploy_backend=true"
}

init_database() {
  log_info "Inicializando base de datos (${ENVIRONMENT})"
  cd "${ANSIBLE_DIR}"

  ansible-playbook playbook.yaml \
    -e "env=${ENVIRONMENT}" \
    -e "initialize_database=true" \
    --tags "database"
}

build_images() {
  log_info "Construyendo imagenes Docker (${ENVIRONMENT})"
  cd "${ANSIBLE_DIR}"

  ansible-playbook playbook.yaml \
    -e "env=${ENVIRONMENT}" \
    -e "build_frontend=true" \
    -e "build_backend=true" \
    --tags "docker"
}

destroy_infrastructure() {
  log_warn "Destruyendo infraestructura Terraform (${ENVIRONMENT})"
  cd "${TERRAFORM_DIR}"
  terraform destroy -var="environment=${ENVIRONMENT}" -auto-approve
}

print_usage() {
  cat <<EOF
Uso: $0 <environment> <action>

Environments:
  dev | staging | prod

Actions:
  provision   - Terraform init/validate/plan/apply
  configure   - Ansible deployment (build + deploy ECS)
  deploy      - provision + configure
  init-db     - inicializar esquema de base de datos
  build       - construir y publicar imagenes
  destroy     - terraform destroy
EOF
}

case "${ACTION}" in
  provision)
    check_prerequisites
    provision_infrastructure
    ;;
  configure)
    check_prerequisites
    configure_systems
    ;;
  deploy)
    check_prerequisites
    provision_infrastructure
    configure_systems
    ;;
  init-db)
    check_prerequisites
    init_database
    ;;
  build)
    check_prerequisites
    build_images
    ;;
  destroy)
    check_prerequisites
    destroy_infrastructure
    ;;
  *)
    print_usage
    exit 1
    ;;
esac

log_info "Flujo completado"
