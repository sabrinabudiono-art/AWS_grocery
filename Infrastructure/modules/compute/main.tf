# IAM role — gives each EC2 instance permission to pull images from ECR
# without storing any passwords on the machine.
resource "aws_iam_role" "ec2" {
  name = "grocery-ec2-role"

  # Allow EC2 instances to assume (use) this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach AWS's built-in read-only ECR policy (lets instances pull images).
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance profile — the wrapper that actually attaches the role to an instance.
resource "aws_iam_instance_profile" "ec2" {
  name = "grocery-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Launch Template — the blueprint every EC2 instance in the ASG is stamped from.
resource "aws_launch_template" "main" {
  name_prefix   = "grocery-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Attach the IAM role so the instance can pull from ECR.
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ec2_sg_id]
  }

  # Bootstrap script — runs once on first boot. It installs Docker, logs in to
  # ECR, pulls our image, and starts the container with its secrets as env vars.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # 1. Install and start Docker
    dnf install -y docker
    systemctl enable --now docker

    # 2. Log in to ECR (uses the instance's IAM role — no password needed)
    aws ecr get-login-password --region ${var.aws_region} \
      | docker login --username AWS --password-stdin ${var.ecr_registry}

    # 3. Pull the latest image
    docker pull ${var.image_url}

    # 4. Run the container. --restart always brings it back if it crashes or
    #    the instance reboots. -p 80:80 maps the instance's port 80 to the
    #    container's port 80 (where gunicorn listens).
    docker run -d --restart always -p 80:80 \
      -e POSTGRES_URI="postgresql://${var.db_username}:${var.db_password}@${var.db_endpoint}/${var.db_name}" \
      -e JWT_SECRET_KEY="${var.jwt_secret}" \
      -e DEPLOYMENT_ENV="aws" \
      ${var.image_url}
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
