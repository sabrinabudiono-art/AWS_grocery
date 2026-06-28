output "repository_url" {
  description = "URL of the ECR repository — used to tag and push the Docker image"
  value       = aws_ecr_repository.main.repository_url
}
