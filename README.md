
> Infraestructura como código para un Sistema de Gestión de Aprendizaje (LMS) escalable y de alta disponibilidad en AWS.


## Equipo de Desarrollo - JalCubo 

**Universidad Privada Antenor Orrego  (UPAO)**

| Integrante | Rol |
|------------|-----|
| **Gonzales Soto Alex** | DevOps Engineer |
| **Tisnado Guevara Anthony** | Cloud Architect |

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
aws configure sso
# Perfil recomendado:
# AdministratorAccess-218085830508
```

### Flujo de Terraform (recomendado para pruebas)

```bash
cd /home/alex/IAC/infra/terraform
aws sso login --profile AdministratorAccess-218085830508
export AWS_PROFILE=AdministratorAccess-218085830508
export AWS_REGION=us-east-1

terraform init -backend=false
terraform validate
terraform plan
terraform apply

# Al terminar pruebas/demo (evitar costos):
terraform destroy
```

### Variables de entorno para demo de bajo costo

Archivo: `infra/terraform/terraform.tfvars`

```hcl
accountId               = "218085830508"
environment             = "dev"
domain_name             = "tudominio.com"
myregion                = "us-east-1"

enable_https_listener   = false
enable_optional_lambdas = false
frontend_desired_count  = 0
backend_desired_count   = 0
```

### Validación rápida post-deploy

```bash
terraform output
aws sts get-caller-identity
```

### Troubleshooting común

- `No valid credential sources found`:
  Ejecutar `aws sso login --profile AdministratorAccess-218085830508` y exportar `AWS_PROFILE`.
- `Error acquiring the state lock`:
  Cerrar procesos terraform previos y reintentar.
- `CertificateNotFound`:
  Usar `enable_https_listener = false` en dev o configurar `certificate_arn` válido en ACM.
- `reading ZIP file ... no such file`:
  Mantener `enable_optional_lambdas = false` si no existen zips de funciones opcionales.
- `RDS Cluster final_snapshot_identifier is required` al destroy:
  En `dev` se usa `skip_final_snapshot = true` en el código actual.

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



<div align="center">

**Si este proyecto te fue útil, dile al profesor Leturia que nos apruebe IAC, si entendimos iac**

No se que hicimos pero nos desvelamos - UPAO 2025

</div>
