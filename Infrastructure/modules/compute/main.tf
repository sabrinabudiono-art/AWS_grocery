# Launch Template — the blueprint every EC2 instance in the ASG is stamped from.
resource "aws_launch_template" "main" {
  name_prefix   = "grocery-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ec2_sg_id]
  }

  # Bootstrap script — installs nginx on first boot so the ALB health check passes.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "grocery-ec2"
    }
  }
}

# Auto Scaling Group — keeps the desired number of instances running and healthy.
resource "aws_autoscaling_group" "main" {
  name                = "grocery-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids

  # Register instances with the ALB target group automatically.
  target_group_arns = [var.target_group_arn]

  # Replace instances the ALB reports as unhealthy.
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "grocery-asg-instance"
    propagate_at_launch = true
  }
}
