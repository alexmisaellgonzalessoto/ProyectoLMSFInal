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
