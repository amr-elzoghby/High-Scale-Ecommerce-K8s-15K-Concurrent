resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id] 
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] 
}

resource "aws_lb_target_group" "web_tg" {
  name_prefix = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.web-vpc.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }
  lifecycle {
    create_before_destroy = true
}
  }
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port                = "80"
  protocol            = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


 