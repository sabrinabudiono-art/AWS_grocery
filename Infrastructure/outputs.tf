output "alb_dns_name" {
  description = "Paste this URL into your browser to reach the app"
  value       = "http://${module.alb.alb_dns_name}"
}

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.rds.db_endpoint
}

output "s3_bucket_name" {
  description = "Name of the avatars S3 bucket"
  value       = module.s3.bucket_name
}
