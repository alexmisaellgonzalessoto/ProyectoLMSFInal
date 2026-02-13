
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

## Implementacion Paso a Paso (Bitacora)

### Objetivo

- Tener trazabilidad real de cada ajuste de infraestructura.
- Explicar el "por que" de cada cambio.
- Facilitar defensa academica y soporte operativo.

### Resumen de Commits

#### `fbb615f` - `fix(terraform): unify API/Lambda/SQS resource references`

Que se hizo:
- Se corrigieron referencias rotas entre recursos de API Gateway, Lambda y SQS.
- Se eliminaron referencias a recursos inexistentes.
- Se alinearon nombres para que Terraform pudiera resolver dependencias correctamente.

Por que:
- Habia recursos definidos con un nombre y referenciados con otro.
- Eso rompe `plan`/`apply` por errores de graph y dependencias.

Resultado:
- Terraform dejo de fallar por referencias invalidas en esos modulos.

#### `866ce16` - `fix(terraform): repair Aurora resources and KMS wiring`

Que se hizo:
- Se corrigio el tipo de recurso subnet group de Aurora.
- Se corrigieron referencias de password de Aurora.
- Se agrego KMS para Performance Insights de Aurora.

Por que:
- Habia typos y referencias a recursos que no existian.

Resultado:
- La definicion base de Aurora quedo consistente.

#### `2098632` - `fix(terraform): align ECS/ALB/CloudWatch wiring and S3 syntax`

Que se hizo:
- Se alinearon ECS services con target groups/listeners existentes.
- Se corrigieron referencias de CloudWatch hacia servicios ECS reales.
- Se corrigio sintaxis HCL de `s3.tf`.

Por que:
- ALB/ECS estaban conectados a nombres de recursos incorrectos.
- Habia error de sintaxis en S3 que podia romper validacion.

Resultado:
- Se estabilizo el flujo de red ALB -> ECS y la configuracion de monitoreo.

#### `1a14976` - `chore(terraform): remove provider duplication and IAM role collision`

Que se hizo:
- Se elimino proveedor `aws` duplicado.
- Se removio bloque IAM duplicado con colision de nombre de rol.
- Se dejaron defaults en variables legacy para evitar prompts innecesarios.

Por que:
- Proveedores y roles duplicados causan comportamiento ambiguo y fallas de apply.

Resultado:
- Base de Terraform mas limpia y predecible.

#### `46ee937` - `fix(terraform): resolve apply-time AWS errors for dev deploy`

Que se hizo:
- Secrets Manager: nombre ajustado para evitar colision de nombre.
- RDS password: se removieron caracteres no permitidos por AWS RDS.
- S3 lifecycle: se corrigio regla Glacier -> Deep Archive.
- SQS queue policy: se separaron politicas por cola (1 recurso por statement).
- ALB HTTPS: se hizo opcional para entorno dev sin certificado real.
- Lambdas zip opcionales: se togglearon para no romper apply sin artefactos.

Por que:
- Estos eran errores reales de runtime en AWS durante `terraform apply`.

Resultado:
- Apply de dev mucho mas estable y sin bloqueos recurrentes.

#### `6116fe6` - `chore(terraform): set low-cost dev tfvars defaults`

Que se hizo:
- Se actualizo `infra/terraform/terraform.tfvars` para pruebas controladas:
  - `enable_https_listener = false`
  - `enable_optional_lambdas = false`
  - `frontend_desired_count = 0`
  - `backend_desired_count = 0`

Por que:
- Reducir riesgo de costos durante demos y pruebas.

Resultado:
- Entorno dev preparado para pruebas con menor costo operativo.

#### `79c6854` - `fix(terraform): unblock dev apply for Aurora and learning lambda`

Que se hizo:
- Performance Insights se dejo solo para `prod`.
- Se agrego `lambda.zip` minimo para desbloquear despliegue de `learning_events_lambda`.

Por que:
- Algunos tipos de instancia/configuracion dev no soportaban PI.
- Faltaba artefacto zip requerido por Lambda.

Resultado:
- `apply` ya no fallaba por esos dos puntos.

#### `2582a4e` - `fix(terraform): handle Aurora final snapshot on destroy by environment`

Que se hizo:
- Se definio logica de destroy para Aurora:
  - `dev`: `skip_final_snapshot = true`
  - `prod`: `final_snapshot_identifier` dinamico

Por que:
- AWS RDS exige snapshot final o skip final snapshot en destroy.

Resultado:
- `terraform destroy` en dev deja de bloquearse por snapshot final.

### Estado Operativo

- Se pudo ejecutar `terraform apply` completo con salida de `Apply complete`.
- Se verificaron outputs de infraestructura.
- Se ejecuto `terraform destroy` para apagar recursos y cortar costos.

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



## Nota Final

Proyecto orientado a despliegue y pruebas en AWS con Terraform.
Para evitar costos innecesarios, ejecutar siempre `terraform destroy` al finalizar la validacion.
