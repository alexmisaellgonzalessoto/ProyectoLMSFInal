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
  description = "Nombre del bucket S3 para certificados"
  type        = string
  default     = "lms-certificates"
}

variable "lms_resources_bucket" {
  description = "Nombre del bucket S3 para recursos educativos"
  type        = string
  default     = "lms-educational-resources"
}

variable "lms_submissions_bucket" {
  description = "Nombre del bucket S3 para tareas de estudiantes"
  type        = string
  default     = "lms-student-submissions"
}