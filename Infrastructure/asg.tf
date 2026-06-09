# Launch Template — defines how every EC2 instance in the ASG is created
resource "aws_launch_template" "main" {
  name_prefix   = "grocery-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type
  key_name      = aws_key_pair.main.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ssh.id]
  }

  # Bootstrap script — installs a simple web server so the ALB health check passes
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
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

# Auto Scaling Group — keeps the desired number of instances running
resource "aws_autoscaling_group" "main" {
  name                = "grocery-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = data.aws_subnets.alb.ids

  # Attach to the ALB target group so the ALB can route to these instances
  target_group_arns = [aws_lb_target_group.main.arn]

  # Replace unhealthy instances based on the ALB health check
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
