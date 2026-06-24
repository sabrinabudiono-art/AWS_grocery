# S3 bucket for user avatars. The account ID in the name keeps it globally unique.
resource "aws_s3_bucket" "avatars" {
  bucket = "grocerymate-avatars-${var.account_id}"

  tags = {
    Name        = "grocerymate-avatars"
    Environment = "Dev"
  }
}

# Block all public access — objects should only be reachable by your app.
resource "aws_s3_bucket_public_access_block" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt all objects at rest using AWS-managed keys.
resource "aws_s3_bucket_server_side_encryption_configuration" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Keep previous versions of files so accidental deletes can be recovered.
resource "aws_s3_bucket_versioning" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  versioning_configuration {
    status = "Enabled"
  }
}
