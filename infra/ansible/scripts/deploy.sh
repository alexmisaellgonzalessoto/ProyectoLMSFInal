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
configure_systems() {
    log_info "Desplegando configuración con Ansible..."
    cd ansible

    ansible-galaxy collection install -r requirements.yml
    #playbook
    ansible-playbook playbook.yml \
        -e "environment=$ENVIRONMENT" \
        -e "build_frontend=true" \
        -e "build_backend=true" \
        -e "deploy_frontend=true" \
        -e "deploy_backend=true" \
        --tags "all,!cleanup"
    log_info "Configuración desplegada"
    cd ..
}

#Iniicar base de datos
init_database() {
    log_info "Inicializando base de datos..."
    
    cd ansible
    
    ansible-playbook playbook.yaml \
        -e "environment=$ENVIRONMENT" \
        -e "initialize_database=true" \
        --tags "database"
    log_info "Base de datos inicializada"
    cd ..
}
#olo build de imágenes
build_images() {
    log_info "Construyendo imágenes Docker..."
    
    cd ansible
    
    ansible-playbook playbook.yaml \
        -e "environment=$ENVIRONMENT" \
        -e "build_frontend=true" \
        -e "build_backend=true" \
        --tags "docker"
    log_info "Imágenes Docker construidas"
    cd ..
}
# Main
case $ACTION in
    provision)
        check_prerequisites
        provision_infrastructure
        ;;
    configure)
        check_prerequisites
        configure_system
        ;;
    deploy)
        check_prerequisites
        provision_infrastructure
        configure_system
        ;;
    init-db)
        check_prerequisites
        init_database
        ;;
    build)
        check_prerequisites
        build_images
        ;;
    deploy-only)
        check_prerequisites
        deploy_only
        ;;
    cleanup)
        check_prerequisites
        cleanup
        ;;
    rollback)
        check_prerequisites
        rollback
        ;;
    logs)
        show_logs
        ;;
    destroy)
        destroy
        ;;
    *)
        echo "Uso: $0 <environment> <action>"
        echo ""
        echo "Environments: dev, staging, prod"
        echo ""
        echo "Actions:"
        echo "  provision    - Solo Terraform (infraestructura)"
        echo "  configure    - Solo Ansible (configuración)"
        echo "  deploy       - Full deployment (Terraform + Ansible)"
        echo "  init-db      - Inicializar base de datos"
        echo "  build        - Solo construir imágenes Docker"
        echo "  deploy-only  - Solo deploy sin rebuild"
        echo "  cleanup      - Limpiar recursos antiguos"
        echo "  rollback     - Volver al deployment anterior"
        echo "  logs         - Ver logs (añade: frontend|backend)"
        echo ""
        echo "  $0 dev deploy"
        echo "  $0 prod deploy-only"
        echo "  $0 dev logs backend"
        exit 1
        ;;
esac

echo ""
log_info "Script completado exitosamente amigo"