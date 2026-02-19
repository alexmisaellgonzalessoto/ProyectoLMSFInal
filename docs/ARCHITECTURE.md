# Arquitectura LMS (IaC)

Este documento muestra la arquitectura principal y, en especial, la configuracion de tareas ECS Fargate por servicio.

## Diagrama

```mermaid
flowchart LR
    Client[Usuario / Cliente Web]
    APIGW[API Gateway]
    ALB[ALB Interno]

    subgraph VPC[VPC LMS]
        subgraph ECS[ECS Cluster - Fargate]
            FE[Frontend Service\nPort 3000\nDesired: var.frontend_desired_count\nMin: var.frontend_min_capacity\nMax: var.frontend_max_capacity]
            BE[Backend Service\nPort 8000\nDesired: var.backend_desired_count\nMin: var.backend_min_capacity\nMax: var.backend_max_capacity]
            AU[Auth Service\nPort 3001\nDesired: var.auth_desired_count\nScaling: fijo]
            WK[Image Worker Service\nDesired: var.worker_desired_count\nMin: var.worker_min_capacity\nMax: var.worker_max_capacity]
        end

        subgraph DATA[Capa de Datos]
            RDS[Aurora MySQL]
            REDIS[ElastiCache Redis]
            S3[S3 Buckets]
        end

        subgraph EVENTS[Mensajeria y Eventos]
            SQS[SQS Queues]
            SNS[SNS Topic]
            EVB[EventBridge Bus]
        end

        subgraph LAMBDA[Lambdas]
            L1[ingestor_eventos_aprendizaje]
            L2[procesador_archivos_entregas]
            L3[despachador_notificaciones]
            L4[despachador_correos]
        end
    end

    Client --> APIGW
    Client --> ALB
    APIGW --> L1
    APIGW --> ALB
    ALB --> FE
    ALB --> BE
    ALB --> AU
    WK --> SQS
    BE --> SQS
    L3 --> SNS
    L1 --> EVB
    FE --> BE
    BE --> RDS
    BE --> REDIS
    BE --> S3
    L2 --> S3
    L1 --> RDS
```

## Configuracion Fargate por defecto (variables.tf)

| Servicio | Desired | Min | Max |
|----------|---------|-----|-----|
| Frontend | `2` | `1` | `4` |
| Backend | `2` | `1` | `4` |
| Auth | `1` | N/A | N/A |
| Image Worker | `1` | `1` | `6` |

## Configuracion de bajo costo (terraform.tfvars dev)

| Servicio | Desired | Min | Max |
|----------|---------|-----|-----|
| Frontend | `0` | `0` | `1` |
| Backend | `0` | `0` | `1` |
| Auth | `0` | N/A | N/A |
| Image Worker | `0` | `0` | `1` |
