# Implementacion Paso a Paso (Terraform + AWS)

Este documento resume los cambios aplicados en el proyecto, en orden cronologico, con su objetivo tecnico y resultado esperado.

## Objetivo

- Tener trazabilidad real de cada ajuste de infraestructura.
- Explicar el "por que" de cada cambio.
- Facilitar defensa academica y soporte operativo.

## Resumen de Commits

### `fbb615f` - `fix(terraform): unify API/Lambda/SQS resource references`

Que se hizo:
- Se corrigieron referencias rotas entre recursos de API Gateway, Lambda y SQS.
- Se eliminaron referencias a recursos inexistentes.
- Se alinearon nombres para que Terraform pudiera resolver dependencias correctamente.

Por que:
- Habia recursos definidos con un nombre y referenciados con otro.
- Eso rompe `plan`/`apply` por errores de graph y dependencias.

Resultado:
- Terraform dejo de fallar por referencias invalidas en esos modulos.

---

### `866ce16` - `fix(terraform): repair Aurora resources and KMS wiring`

Que se hizo:
- Se corrigio el tipo de recurso subnet group de Aurora.
- Se corrigieron referencias de password de Aurora.
- Se agrego KMS para Performance Insights de Aurora.

Por que:
- Habia typos y referencias a recursos que no existian.

Resultado:
- La definicion base de Aurora quedo consistente.

---

### `2098632` - `fix(terraform): align ECS/ALB/CloudWatch wiring and S3 syntax`

Que se hizo:
- Se alinearon ECS services con target groups/listeners existentes.
- Se corrigieron referencias de CloudWatch hacia servicios ECS reales.
- Se corrigio sintaxis HCL de `s3.tf`.

Por que:
- ALB/ECS estaban conectados a nombres de recursos incorrectos.
- Habia error de sintaxis en S3 que podia romper validacion.

Resultado:
- Se estabilizo el flujo de red ALB -> ECS y la configuracion de monitoreo.

---

### `1a14976` - `chore(terraform): remove provider duplication and IAM role collision`

Que se hizo:
- Se elimino proveedor `aws` duplicado.
- Se removio bloque IAM duplicado con colision de nombre de rol.
- Se dejaron defaults en variables legacy para evitar prompts innecesarios.

Por que:
- Proveedores y roles duplicados causan comportamiento ambiguo y fallas de apply.

Resultado:
- Base de Terraform mas limpia y predecible.

---

### `46ee937` - `fix(terraform): resolve apply-time AWS errors for dev deploy`

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

---

### `6116fe6` - `chore(terraform): set low-cost dev tfvars defaults`

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

---

### `79c6854` - `fix(terraform): unblock dev apply for Aurora and learning lambda`

Que se hizo:
- Performance Insights se dejo solo para `prod`.
- Se agrego `lambda.zip` minimo para desbloquear despliegue de `learning_events_lambda`.

Por que:
- Algunos tipos de instancia/configuracion dev no soportaban PI.
- Faltaba artefacto zip requerido por Lambda.

Resultado:
- `apply` ya no fallaba por esos dos puntos.

---

### `2582a4e` - `fix(terraform): handle Aurora final snapshot on destroy by environment`

Que se hizo:
- Se definio logica de destroy para Aurora:
  - `dev`: `skip_final_snapshot = true`
  - `prod`: `final_snapshot_identifier` dinamico

Por que:
- AWS RDS exige snapshot final o skip final snapshot en destroy.

Resultado:
- `terraform destroy` en dev deja de bloquearse por snapshot final.

---

### `61a3433` - `docs(readme): update team names and real terraform workflow`

Que se hizo:
- Se actualizaron integrantes:
  - Gonzales Soto Alex
  - Tisnado Guevara Anthony
- Se actualizo flujo real de SSO + Terraform.
- Se agrego troubleshooting de errores comunes.

Por que:
- README desactualizado respecto a implementacion real.

Resultado:
- Documentacion alineada al proceso ejecutado.

## Estado Operativo

- Se pudo ejecutar `terraform apply` completo con salida de `Apply complete`.
- Se verificaron outputs de infraestructura.
- Se ejecuto `terraform destroy` para apagar recursos y cortar costos.

## Recomendacion para siguientes cambios

Mantener esta disciplina:
1. Hacer un cambio tecnico.
2. Validar (`plan`/`apply` o prueba puntual).
3. Commit con mensaje claro.
4. Actualizar documentacion de causa/solucion.

