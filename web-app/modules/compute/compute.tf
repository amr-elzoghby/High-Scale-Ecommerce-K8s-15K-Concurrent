# ─── Launch Template ──────────────────────────────────────────────────────────
resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  block_device_mappings {
    device_name = var.ebs_device_name
    ebs {
      volume_size = var.ebs_volume_size
      volume_type = var.ebs_volume_type
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # userdata.sh is base64-encoded and passed to user_data
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    s3_bucket   = local.s3_bucket_name
    db_password = var.db_password
    alb_dns     = aws_lb.main.dns_name
  }))




  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [local.app_security_group_id]
    delete_on_termination       = true
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2 — more secure
    http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-instance"
    }
  }
}

# ─── Auto Scaling Group ───────────────────────────────────────────────────────
resource "aws_autoscaling_group" "app" {
  name                      = "${var.name_prefix}-asg"
  vpc_zone_identifier       = local.private_subnet_ids
  desired_capacity          = var.asg_desired_capacity

  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  target_group_arns         = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-instance"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_target_group.app,
  ]
}

