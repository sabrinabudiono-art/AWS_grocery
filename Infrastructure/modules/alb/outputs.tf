output "target_group_arn" {
  description = "ARN of the target group — the Auto Scaling Group attaches to this"
  value       = aws_lb_target_group.main.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}
