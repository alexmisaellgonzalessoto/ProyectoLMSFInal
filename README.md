
> Infraestructura como código para un Sistema de Gestión de Aprendizaje (LMS) escalable y de alta disponibilidad en AWS.


## Equipo de Desarrollo - JalCubo xD

**Universidad Privada Antenor Orrego (UPAO)**

| Integrante | Rol |
|------------|-----|
| **Junior** | DevOps Engineer |
| **Joel** | Cloud Architect |
| **Jeremy** | Infrastructure Developer |

---

## Descripción del Proyecto

Este proyecto implementa una infraestructura completa para un Learning Management System (LMS) utilizando las mejores prácticas de DevOps e Infrastructure as Code (IaC). La arquitectura está diseñada para ser escalable, segura y de alta disponibilidad. Lo que se busca es basicamente la tolerancia a altos picos de trafico de red.

### Objetivos

-  Automatizar el aprovisionamiento de infraestructura en AWS
-  Implementar CI/CD con Terraform y Ansible
-  Garantizar alta disponibilidad y tolerancia a picos altos de trafico de red
-  Optimizar costos mediante autoscaling y lifecycle policies
-  Asegurar la seguridad con WAF, KMS y Secrets Manager

---

## Arquitectura


### Componentes Principales

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Compute** | ECS Fargate | Contenedores sin servidor |
| **Database** | Aurora MySQL | Base de datos relacional |
| **Storage** | S3 | Certificados, recursos, tareas |
| **Cache** | ElastiCache Redis | Caché de aplicación |
| **Networking** | VPC, ALB, NAT Gateway | Red privada y balanceo |
| **Security** | WAF, KMS, Secrets Manager | Seguridad multicapa |
| **Monitoring** | CloudWatch | Métricas y logs |
| **Messaging** | SQS, SNS | Notificaciones asíncronas |
| **Orchestration** | Lambda, EventBridge | Eventos y procesos |

---

## Estructura del Proyecto

```
lms-infrastructure/
│
├──  terraform/                    # Infraestructura como código
│   ├── main.tf                      # Configuración principal
│   ├── variables.tf                 # Variables de entrada
│   ├── outputs.tf                   # Valores de salida
│   ├── locals.tf                    # Variables locales
│   │
│   ├── vpc.tf                       # Red VPC
│   ├── ecs.tf                       # ECS Fargate Cluster
│   ├── aurora.tf                    # Base de datos Aurora
│   ├── s3.tf                        # Buckets S3
│   ├── alb.tf                       # Load Balancer
│   ├── waf.tf                       # Web Application Firewall
│   ├── sqs.tf                       # Colas SQS
│   ├── cloudwatch.tf                # Monitoreo
│   ├── api_gateway.tf               # API Gateway
│   ├── lambda.tf                    # Funciones Lambda
│   └── iam.tf                       # Roles y políticas
│
├──  ansible/                      # Configuración y deployment
│   ├── playbook.yaml                # Playbook principal
│   ├── inventory.ini                # Inventario de hosts
│   ├── ansible.cfg                  # Configuración Ansible
│   ├── requirements.yml             # Collections necesarias
│   │
│   ├── group_vars/               # Variables por entorno
│   │   ├── all.yml
│   │   ├── dev.yml
│   │   └── prod.yml
│   │
│   ├── templates/                # Templates Jinja2
│   │   ├── init_database.sql.j2
│   │   ├── backend.env.j2
│   │   ├── nginx.conf.j2
│   │   └── logging.conf.j2
│   │
│   ├── scripts/                  # Scripts de automatización
│   │   ├── deploy.sh
│   │   └── check-health.sh
│   │
│   └── README.md
│
├── frontend/                     # Aplicación frontend
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
│
├── backend/                      # Aplicación backend
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│
├── docs/                         # Documentación
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   └── API.md
│
|
└── README.md                        # Este archivo
```



###  Clonar el Repositorio

```bash
git clone https://github.com/JalCubo/lms-infrastructure.git
cd lms-infrastructure
```

### Configurar Credenciales AWS

```bash
aws configure
# Ingresar:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Region: us-east-1
# - Output format: json
```

### Deployment Automático

```bash
cd ansible
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev deploy

## Tecnologías Utilizadas

### Infrastructure as Code
- **Terraform** 1.0+ - Aprovisionamiento de infraestructura
- **Ansible** 2.9+ - Configuración y deployment

### Cloud Provider
- **AWS** - Amazon Web Services
  - ECS Fargate
  - Aurora MySQL
  - S3, CloudWatch
  - ALB, WAF, VPC
  - SQS, SNS, Lambda

### Containerización
- **Docker** - Contenedores de aplicación
- **Amazon ECR** - Registro de imágenes


## Comandos Útiles

```bash
# Ver estado de la infraestructura
cd terraform && terraform show

# Ver outputs
terraform output

# Ver servicios ECS
aws ecs list-services --cluster lms-cluster-dev

# Ver logs en tiempo real
cd ansible && ./scripts/deploy.sh dev logs backend

# Health check
./scripts/check-health.sh dev

# Actualizar solo código (sin rebuild infra)
./scripts/deploy.sh dev deploy-only

# Rollback
./scripts/deploy.sh dev rollback
```

---

## Costos Estimados

### Ambiente Development (24/7)

| Recurso | Configuración | Costo Mensual |
|---------|---------------|---------------|
| ECS Fargate | 4 tasks (0.5 vCPU, 1GB) | ~$30 |
| Aurora MySQL | db.t3.medium (1 writer) | ~$50 |
| ALB | 1 ALB | ~$20 |
| NAT Gateway | 1 NAT | ~$35 |
| S3 | 100 GB | ~$3 |
| CloudWatch | Logs + Metrics | ~$10 |
| **TOTAL** | | **~$148/mes** |

### Ambiente Production (24/7)

| Recurso | Configuración | Costo Mensual |
|---------|---------------|---------------|
| ECS Fargate | 8 tasks (1 vCPU, 2GB) | ~$120 |
| Aurora MySQL | db.r6g.large (1 writer + 1 reader) | ~$230 |
| ElastiCache | cache.t3.medium | ~$50 |
| ALB | 1 ALB | ~$20 |
| NAT Gateway | 2 NAT (HA) | ~$70 |
| S3 | 500 GB + Glacier | ~$15 |
| WAF | Web ACL + Rules | ~$10 |
| CloudWatch | Dashboards + Alarms | ~$20 |
| **TOTAL** | | **~$535/mes** |

 **Optimizaciones posibles:**
- Usar Fargate Spot (-70% en compute)
- Reserved Instances para Aurora (-40%)
- S3 Intelligent Tiering

---

## Testing

```bash
# Unit tests de Terraform
cd terraform
terraform fmt -check
terraform validate

# Ansible syntax check
cd ansible
ansible-playbook playbook.yaml --syntax-check

# Integration tests
./scripts/check-health.sh dev
```

---

## CI/CD

El proyecto está preparado para integrarse con:

- **GitHub Actions** - Deployment automático
- **GitLab CI** - Pipelines de infraestructura
- **Jenkins** - Build y deployment





---

<div align="center">

**Si este proyecto te fue útil, dile al profesor Leturia que nos apruebe IAC, si entendimos iac**

No se que hicimos pero nos desvelamos - UPAO 2025

</div>