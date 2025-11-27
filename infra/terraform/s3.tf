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

#VIDEOS, PDF E IMAGENES 
resource "aws_s3_bucket" "educational_resources" {
  bucket = "lms-educational-resources-${var.environment}-${var.accountId}"

  tags = {
    Name        = "lms-educational-resources"
    Environment = var.environment
    Purpose     = "Educational Content Storage"
  }
}

# Versionado
resource "aws_s3_bucket_versioning" "resources_versioning" {
  bucket = aws_s3_bucket.educational_resources.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación
resource "aws_s3_bucket_server_side_encryption_configuration" "resources_encryption" {
  bucket = aws_s3_bucket.educational_resources.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
    bucket_key_enabled = true
  }
}


resource "aws_s3_bucket_public_access_block" "resources_block" {
  bucket = aws_s3_bucket.educational_resources.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS para acceso desde frontend
resource "aws_s3_bucket_cors_configuration" "resources_cors" {
  bucket = aws_s3_bucket.educational_resources.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [
      "https://${var.domain_name}",
      "https://*.${var.domain_name}"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Ciclo de vida (inteligente según uso)
resource "aws_s3_bucket_lifecycle_configuration" "resources_lifecycle" {
  bucket = aws_s3_bucket.educational_resources.id

  rule {
    id     = "optimize-storage"
    status = "Enabled"

    # Mover a Infrequent Access después de 30 días sin acceso
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Mover a Glacier después de 90 días
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

#TAREAS DE ESTUDIANTES
resource "aws_s3_bucket" "student_submissions" {
  bucket = "lms-student-submissions-${var.environment}-${var.accountId}"

  tags = {
    Name        = "lms-student-submissions"
    Environment = var.environment
    Purpose     = "Student Assignment Submissions"
  }
}

# Versionado
resource "aws_s3_bucket_versioning" "submissions_versioning" {
  bucket = aws_s3_bucket.student_submissions.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación
resource "aws_s3_bucket_server_side_encryption_configuration" "submissions_encryption" {
  bucket = aws_s3_bucket.student_submissions.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
    bucket_key_enabled = true
  }
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "submissions_block" {
  bucket = aws_s3_bucket.student_submissions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS para uploads desde frontend
resource "aws_s3_bucket_cors_configuration" "submissions_cors" {
  bucket = aws_s3_bucket.student_submissions.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = [
      "https://${var.domain_name}",
      "https://*.${var.domain_name}"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Ciclo de vida (eliminar después de que termine el curso)
resource "aws_s3_bucket_lifecycle_configuration" "submissions_lifecycle" {
  bucket = aws_s3_bucket.student_submissions.id

  rule {
    id     = "archive-old-submissions"
    status = "Enabled"

    # Mover a IA después de 60 días
    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    # Mover a Glacier después de 180 días (6 meses)
    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    # Eliminar después de 2 años (políticas educativas)
    expiration {
      days = 730
    }
  }
}