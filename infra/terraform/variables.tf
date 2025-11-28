variable "myregion" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "accountId" {
  description = "Pasa el ID de tu cuenta ps joel"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Rutina de mi lambda"
  type        = string
  default     = "python3.12"
}

variable "api_name" {
  description = "API lambda"
  type        = string
  default     = "lms-api"
}
variable "s3_bucket_name" {
  description = "No se que nonmbre poner xD"
  type        = string 
}
#VARIABLES VPC
variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de subnets públicas para el ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN del certificado SSL en ACM"
  type        = string
}
variable "lms_certificates_bucket" {
  description = "Cerficados"
  type        = string
  default     = "lms-certificates"
}

variable "lms_resources_bucket" {
  description = "Recursos educativos"
  type        = string
  default     = "lms-educational-resources"
}

variable "lms_submissions_bucket" {
  description = "Tareas de estudiantes"
  type        = string
  default     = "lms-student-submissions"
}

# Aurora Configuration
variable "aurora_master_username" {
  description = "Usuario master de Aurora"
  type        = string
  default     = "lmsadmin"
}

variable "aurora_database_name" {
  description = "Aurora"
  type        = string
  default     = "lms_database"
}

variable "aurora_instance_class" {
  description = "Tipo de instancia Aurora"
  type        = string
  default     = "db.t3.medium"  
}

#variable para desarrollo de s3 (Su dominio)
# variables.tf
variable "domain_name" {
  description = "Dominio del LMS"
  type        = string
  default     = "localhost"  #Esto cambiar en produccion pa que funcione xd
}

#VARIABLES PARA EL ECS
variable "frontend_image" {
  description = "Imagen Docker del frontend"
  type        = string
  default     = "nginx:latest"  # Cambiar por tu imagen real
}

variable "backend_image" {
  description = "Imagen Docker del backend"
  type        = string
  default     = "node:18-alpine"  # Cambiar por tu imagen real
}

variable "frontend_cpu" {
  description = "CPU para frontend (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "frontend_memory" {
  description = "Memoria para frontend (512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192)"
  type        = string
  default     = "512"
}

variable "backend_cpu" {
  description = "CPU para backend"
  type        = string
  default     = "512"
}

variable "backend_memory" {
  description = "Memoria para backend"
  type        = string
  default     = "1024"
}

variable "frontend_desired_count" {
  description = "Número de tareas frontend"
  type        = number
  default     = 2
}

variable "backend_desired_count" {
  description = "Número de tareas backend"
  type        = number
  default     = 2
}

#VARIABLE PARA SQS
variable "ses_from_email" {
  description = "Email verificado en SES para enviar notificaciones"
  type        = string
  default     = "noreply@lms.tuescuela.edu"
}