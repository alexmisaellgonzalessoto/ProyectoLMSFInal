# Organizacion de Carpetas

Estructura propuesta y usada para esta entrega:

```text
ProyectoLMSFinal/
├─ back/                     # App backend (Node.js)
├─ front/                    # App frontend estatico (Nginx)
├─ infra/
│  ├─ terraform/             # Infraestructura principal AWS
│  ├─ ansible/               # Orquestacion operativa/deploy
│  └─ tf/                    # Sandbox/ejemplo simple (no productivo)
├─ terratest/                # Pruebas de IaC
└─ docs/
   ├─ ARQUITECTURA.md        # Diagrama + capacidades ECS/Fargate
   └─ PROJECT_STRUCTURE.md   # Este archivo
```

## Regla de uso

- `infra/terraform` es la fuente principal de verdad para provisionar.
- `infra/tf` queda solo como ejemplo/sandbox local.
- `jenkinsfile` y scripts operativos deben apuntar a `infra/terraform`.
