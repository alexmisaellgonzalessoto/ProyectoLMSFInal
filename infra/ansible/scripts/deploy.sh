#!/bin/bash
set -e
ENVIRONMENT =${1:-dev}
ACTION =${2:-deploy}

echo "Script para tu lms hijito"
echo "Ambiente: $ENVIRONMENT"
echo "Accion: $ACTION"

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

# Validar prerequisitos
check_prerequisites() {
    log_info "Verificando prerequisitos..."
    
    commands=("aws" "docker" "terraform" "ansible-playbook" "jq")
    for cmd in "${commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            log_error "$cmd no está instalado"
            exit 1
        fi
    done
    
    # Verificar credenciales AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Credenciales AWS no configuradas"
        exit 1
    fi
    
    log_info "Prerrequisitos verificados amigo"
}

#despelgar iac con terraform
provision_infrastructure() {
    log_info "Provisionando infraestructura con Terraform..."
    
    cd terraform
    terraform init 
    terraform validate
    terraform plan -var="environment=$ENVIRONMENT" -out=tfplan

    read -p "¿Deseas aplicar cambios de terraform? (s/n)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        terraform apply tfplan
        log_info "Infraestructura aprovisionada"
    else
        log_warn "Aplicación de terraform canceladaw xD, arreglalo"
        exit 0
    fi
    cd ..
}

# Desplegar con ansible