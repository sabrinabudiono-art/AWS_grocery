# Application Load Balancer — the public "front door" that receives all HTTP traffic.
resource "aws_lb" "main" {
  name               = "grocery-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids

  tags = {
    Name = "grocery-alb"
  }
}

# Target Group — the list of servers the ALB forwards requests to.
# The Auto Scaling Group registers its instances here automatically.
resource "aws_lb_target_group" "main" {
  name     = "grocery-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "grocery-tg"
  }
}

# Listener — "when traffic arrives on port 80, forward it to the target group".
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
