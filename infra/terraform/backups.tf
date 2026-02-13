resource "aws_s3_bucket" "backups" {
  bucket = "lms-backups-${var.environment}-${var.accountId}"

  tags = {
    Name        = "lms-backups"
    Environment = var.environment
    Purpose     = "System Backups"
  }
}

# Versionado
resource "aws_s3_bucket_versioning" "backups_versioning" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación
resource "aws_s3_bucket_server_side_encryption_configuration" "backups_encryption" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
    bucket_key_enabled = true
  }
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "backups_block" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ciclo de vida agresivo para backups
resource "aws_s3_bucket_lifecycle_configuration" "backups_lifecycle" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "manage-backups"
    status = "Enabled"

    # Mover a Glacier inmediatamente
    transition {
      days          = 1
      storage_class = "GLACIER"
    }

    # Debe ser al menos 90 días después de la transición previa a Glacier.
    transition {
      days          = 91
      storage_class = "DEEP_ARCHIVE"
    }

    # Retener backups por 1 año que es lo habitual ps
    expiration {
      days = 365
    }
  }
}
