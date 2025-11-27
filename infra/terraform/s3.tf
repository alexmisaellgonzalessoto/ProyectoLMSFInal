#CERTIFICADO DE ESTUDIANTES
resource "aws_s3_bucket" "certificates" {
  bucket = "lms-certificates-${var.environment}-${var.accountId}"

  tags = {
    Name        = "lms-certificates"
    Environment = var.environment
    Purpose     = "Student Certificates Storage"
  }
}

# Versionado (mantener historial de certificados)
resource "aws_s3_bucket_versioning" "certificates_versioning" {
  bucket = aws_s3_bucket.certificates.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación en reposo
resource "aws_s3_bucket_server_side_encryption_configuration" "certificates_encryption" {
  bucket = aws_s3_bucket.certificates.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
    bucket_key_enabled = true
  }
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "certificates_block" {
  bucket = aws_s3_bucket.certificates.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ciclo de vida (mover a Glacier después de 90 días)
resource "aws_s3_bucket_lifecycle_configuration" "certificates_lifecycle" {
  bucket = aws_s3_bucket.certificates.id

  rule {
    id     = "archive-old-certificates"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
  }
}