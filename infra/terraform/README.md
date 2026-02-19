# Terraform Principal

Stack principal de infraestructura LMS.

## Bloques por archivo

- `vpc.tf`: red base (VPC, subnets, routes, NAT, IGW)
- `lb.tf`: ALB, listeners, target groups
- `ecs.tf`: cluster, task definitions, servicios y autoscaling
- `aurora.tf`: cluster Aurora y secretos
- `elasticache.tf`: Redis
- `s3.tf`: buckets, cifrado y lifecycle
- `sqs.tf`: colas y politicas
- `lambda.tf`: funciones Lambda e integraciones (API, S3, SQS)
- `api_gateway.tf`: REST API para eventos
- `api_gateway_vpc_link.tf`: HTTP API + VPC Link a ALB
- `iam.tf`: roles y politicas IAM
- `clw.tf`: logs, alarmas y dashboard
- `waf.tf`: WAF para ALB
- `eventbridge.tf`: bus de eventos
- `grafana.tf`: workspace de Amazon Managed Grafana
- `outputs.tf`: salidas clave

## Convenciones

- Recursos Lambda nombrados por responsabilidad:
  - `ingestor_eventos_aprendizaje`
  - `procesador_archivos_entregas`
  - `despachador_notificaciones`
  - `despachador_correos`
- Capacidades ECS no hardcodeadas en `ecs.tf`; usan variables:
  - `*_desired_count`
  - `*_min_capacity`
  - `*_max_capacity`

## Grafana

- Activacion: `enable_grafana = true`
- Outputs:
  - `grafana_workspace_id`
  - `grafana_workspace_url`
