# LMS Infrastructure (IaC)

Infraestructura como codigo para un LMS en AWS usando Terraform + Ansible.

## Equipo

- Gonzales Soto Alex (DevOps)
- Tisnado Guevara Anthony (Arquitectura Cloud)

## Objetivo

- Provisionar infraestructura reproducible con Terraform.
- Desplegar servicios en ECS Fargate.
- Integrar almacenamiento, base de datos y mensajeria.
- Mantener despliegue legible y operable para entorno academico.

## Estructura del repositorio

```text
ProyectoLMSFinal/
├─ back/                     # Backend Node.js
├─ front/                    # Frontend estatico (Nginx)
├─ infra/
│  ├─ terraform/             # IaC principal AWS
│  ├─ ansible/               # Operacion/despliegue
│  └─ tf/                    # Sandbox simple (no productivo)
├─ terratest/                # Tests de IaC
└─ docs/
   ├─ ARCHITECTURE.md
   └─ PROJECT_STRUCTURE.md
```

Notas:
- El pipeline CI/CD usa `infra/terraform` como ruta principal.
- `infra/tf` se mantiene como ejemplo/sandbox.

## Arquitectura y diagrama

- Diagrama actualizado: `docs/ARCHITECTURE.md`
- Incluye configuracion ECS Fargate por servicio:
  - `desired_count`
  - `min_capacity`
  - `max_capacity`

## Lambdas (nombres claros)

Se estandarizaron nombres de funciones e integraciones en español:

- `ingestor_eventos_aprendizaje` (API Gateway -> Lambda -> EventBridge)
- `procesador_archivos_entregas` (S3 -> Lambda)
- `despachador_notificaciones` (SQS -> Lambda -> SNS)
- `despachador_correos` (SQS -> Lambda -> SES)

## Configuracion ECS/Fargate

Los minimos y maximos ya no estan hardcodeados en `ecs.tf`.
Ahora se definen en variables:

- `frontend_min_capacity`, `frontend_max_capacity`
- `backend_min_capacity`, `backend_max_capacity`
- `worker_min_capacity`, `worker_max_capacity`

Para `dev` (bajo costo), `infra/terraform/terraform.tfvars` usa:

- desired = `0`
- min = `0`
- max = `1`

## Flujo recomendado

### Terraform

```bash
cd infra/terraform
terraform init
terraform validate
terraform plan
terraform apply
```

### Ansible

```bash
cd infra/ansible
ansible-playbook playbook.yaml -e "env=dev"
```

### Script de apoyo

```bash
infra/ansible/scripts/deploy.sh dev deploy
```

## Observaciones de organizacion aplicadas

- Se corrigieron rutas rotas entre carpetas (`front`, `back`, `infra/terraform`).
- Se alinearon nombres de templates Ansible con archivos reales.
- Se agrego `front/nginx.conf` y se completo `front/dockerfile`.
