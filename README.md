
> Infraestructura como código para un Sistema de Gestión de Aprendizaje (LMS) escalable y de alta disponibilidad en AWS.


## Equipo de Desarrollo - JalCubo 

**Universidad Privada Antenor Orrego  (UPAO)**

| Integrante | Rol |
|------------|-----|
| **Gonzales Soto Alex** | DevOps |
| **Tisnado Guevara Anthony** | Arquitectura en la nube |

---

## Descripción del Proyecto

Este proyecto implementa una infraestructura para un Sistema de Gestion de Aprendizaje (LMS) usando Infraestructura como Codigo (IaC). La arquitectura esta pensada para ser escalable, segura y con alta disponibilidad, soportando picos altos de trafico.

### Objetivos

-  Desplegar la plataforma LMS en AWS con Terraform, desde red hasta servicios de aplicacion.
-  Corregir errores reales de despliegue detectados en pruebas (`apply` y `destroy`) para tener un flujo estable.
-  Estandarizar autenticacion con AWS SSO y variables de entorno para ejecucion segura desde terminal.
-  Reducir costos de pruebas con configuracion `dev` (servicios opcionales desactivados y escalado minimo).
-  Documentar el proceso paso a paso con troubleshooting de los errores encontrados durante la implementacion.

---

## Arquitectura


### Componentes Principales

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Computo** | ECS Fargate | Ejecucion de frontend y backend en tareas administradas |
| **Base de datos** | Aurora MySQL | Persistencia principal del LMS y manejo de credenciales con Secrets Manager |
| **Almacenamiento** | S3 | Buckets para recursos, entregas, certificados y backups con cifrado/versionado |
| **Cache** | ElastiCache Redis | Soporte de cache para mejorar tiempos de respuesta |
| **Red** | VPC, subnets publicas/privadas, ALB, NAT | Aislamiento de servicios y enrutamiento interno/externo |
| **Seguridad** | Security Groups, IAM, KMS, Secrets Manager, WAF | Control de acceso, cifrado y proteccion perimetral |
| **Monitoreo** | CloudWatch | Alarmas, metricas y tableros para seguimiento operativo |
| **Mensajeria** | SQS, SNS | Comunicacion asincrona y desacople entre componentes |
| **Orquestacion** | Lambda, API Gateway, EventBridge | Integraciones por eventos y endpoints del sistema |
| **Operacion IaC** | Terraform + Ansible | Provisionamiento, ajustes y ejecucion repetible del entorno |

---

## Estructura del Proyecto

```
lms-infrastructure/
│
├──  terraform/                    # Infraestructura como código
│   ├── main.tf                      # Configuracion principal
│   ├── variables.tf                 # Variables de entrada
│   ├── outputs.tf                   # Salidas
│   ├── locals.tf                    # Variables locales
│   │
│   ├── vpc.tf                       # Red VPC
│   ├── ecs.tf                       # Cluster ECS Fargate
│   ├── aurora.tf                    # Base de datos Aurora
│   ├── s3.tf                        # Buckets S3
│   ├── alb.tf                       # Balanceador de carga
│   ├── waf.tf                       # Web Application Firewall
│   ├── sqs.tf                       # Colas SQS
│   ├── cloudwatch.tf                # Monitoreo y alertas
│   ├── api_gateway.tf               # API Gateway
│   ├── lambda.tf                    # Funciones de apoyo
│   └── iam.tf                       # Roles y políticas
│
├──  ansible/                      # Configuracion y despliegue
│   ├── playbook.yaml                # Playbook principal
│   ├── inventory.ini                # Inventario de hosts
│   ├── ansible.cfg                  # Configuración Ansible
│   ├── requirements.yml             # Colecciones necesarias
│   │
│   ├── group_vars/               # Variables por entorno
│   │   ├── all.yml
│   │   ├── dev.yml
│   │   └── prod.yml
│   │
│   ├── templates/                # Plantillas Jinja2
│   │   ├── init_database.sql.j2
│   │   ├── backend.env.j2
│   │   ├── nginx.conf.j2
│   │   └── logging.conf.j2
│   │
│   ├── scripts/                  # Scripts de automatizacion
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

### Validacion rapida despues del despliegue

```bash
terraform output
aws sts get-caller-identity
```

### Problemas comunes

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

## Cambios realizados

Durante la implementacion se corrigieron principalmente estos puntos:

- Referencias rotas entre recursos de API Gateway, Lambda, ECS, ALB, Aurora y SQS.
- Configuracion de Aurora (password valido para RDS, snapshots en destroy y ajustes para entorno dev).
- Politicas IAM y SQS para que cada recurso tenga permisos correctos.
- Configuracion para pruebas de bajo costo en `terraform.tfvars`.
- Actualizacion de documentacion y flujo real de uso con AWS SSO.

Estado del proyecto:

- Se pudo ejecutar `terraform apply` y generar recursos en AWS.
- Se verificaron los outputs de Terraform.
- Se pudo ejecutar `terraform destroy` para limpiar recursos y cortar costos.

## Tecnologias utilizadas

### Infraestructura como codigo
- **Terraform** 1.0+ - Aprovisionamiento de infraestructura
- **Ansible** 2.9+ - Configuracion y despliegue

### Proveedor en la nube
- **AWS** - Amazon Web Services
  - ECS Fargate
  - Aurora MySQL
  - S3, CloudWatch
  - ALB, WAF, VPC
  - SQS, SNS, Lambda

### Contenerizacion
- **Docker** - Contenedores de aplicacion
- **Amazon ECR** - Registro de imagenes



## Nota Final

Proyecto orientado a despliegue y pruebas en AWS con Terraform.
Para evitar costos innecesarios, ejecutar siempre `terraform destroy` al finalizar la validacion.
