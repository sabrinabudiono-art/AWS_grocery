output "bucket_name" {
  description = "Name of the avatars S3 bucket"
  value       = aws_s3_bucket.avatars.id
}
