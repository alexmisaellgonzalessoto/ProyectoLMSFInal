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