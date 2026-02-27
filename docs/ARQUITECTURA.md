# Arquitectura LMS (IaC)

Este documento muestra la arquitectura principal y, en especial, la configuracion de tareas ECS Fargate por servicio.

## Configuracion Fargate por defecto (variables.tf)

| Servicio | Deseado | Minimo | Maximo |
|----------|---------|--------|--------|
| Frontend | `2` | `1` | `4` |
| Backend | `2` | `1` | `4` |
| Autenticacion | `1` | No aplica | No aplica |
| Worker de imagenes | `1` | `1` | `6` |

## Configuracion de bajo costo (terraform.tfvars dev)

| Servicio | Deseado | Minimo | Maximo |
|----------|---------|--------|--------|
| Frontend | `0` | `0` | `1` |
| Backend | `0` | `0` | `1` |
| Autenticacion | `0` | No aplica | No aplica |
| Worker de imagenes | `0` | `0` | `1` |
