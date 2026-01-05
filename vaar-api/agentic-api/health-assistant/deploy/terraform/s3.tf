# S3 Bucket for Vector Store
resource "aws_s3_bucket" "vector_store" {
  bucket = var.s3_bucket_name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vector-store"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "vector_store" {
  bucket = aws_s3_bucket.vector_store.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vector_store" {
  bucket = aws_s3_bucket.vector_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "vector_store" {
  bucket = aws_s3_bucket.vector_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.vector_store.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.vector_store.arn
}
