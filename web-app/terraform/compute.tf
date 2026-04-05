resource "aws_launch_template" "web-server" {
  name_prefix   = "web-server-"
  image_id      = "ami-0ec10929233384c7f" 
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }
  user_data = filebase64("userdata.sh") 
  key_name  = "first"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app_sg.id]
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-asg"
  vpc_zone_identifier       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] 
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4
  health_check_type         = "EC2"
  health_check_grace_period = 600
  target_group_arns = [aws_lb_target_group.web_tg.arn]
  launch_template {
    id      = aws_launch_template.web-server.id
    version = "$Latest" 
  }

  tag {
    key                 = "first"
    value               = "web-server-instance"
    propagate_at_launch = true
  }

  
  depends_on = [
    aws_route_table_association.private_1_assoc,
    aws_route_table_association.private_2_assoc,
    aws_nat_gateway.nat_gw,
    aws_lb_target_group.web_tg
  ]
}
