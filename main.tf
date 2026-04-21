resource "aws_instance" "user" {
  ami           = local.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.user_sg_id]
  subnet_id = local.private_subnet_id
  iam_instance_profile = aws_iam_instance_profile.User-SSM-Role.name

  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name}-user"
    }
  )
}

resource "aws_iam_instance_profile" "User-SSM-Role" {
  name = "User-SSM-Role"
  role = "EC2SSMParameterStore"
}

resource "terraform_data" "user" {
  triggers_replace = [
    aws_instance.user.id
  ]

connection {
    type        = "ssh"
    user        = "ec2-user"
    password    =  local.ssh_loginpass
    host        = aws_instance.user.private_ip
  }
  provisioner "file" {
    source      = "user.sh"           # Local path
    destination = "/tmp/user.sh"      # Remote path
  }
  provisioner "remote-exec" {
    inline = [ 
        "chmod +x /tmp/user.sh",
        "sudo /tmp/user.sh user ${var.env}"
     ]
  }
}

resource "aws_ec2_instance_state" "user" {
  instance_id = aws_instance.user.id
  state       = "stopped"
  depends_on = [ aws_instance.user ]
}

resource "aws_ami_from_instance" "user" {
  name               = "${local.common_name}-user-ami"
  source_instance_id = aws_ec2_instance_state.user.id # Replace with your instance ID
  depends_on = [ aws_ec2_instance_state.user ]
  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name}-user"
    }
  )
}

resource "aws_launch_template" "user" {
  name = "${local.common_name}-user"
  image_id = aws_ami_from_instance.user.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"
  update_default_version = true
  vpc_security_group_ids = [local.user_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name}-user"
    }
  )
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name}-user"
    }
  )
  }
  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name}-user"
    }
  )
}

resource "aws_lb_target_group" "user" {
  name     = "${local.common_name}-user"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60

  health_check {
    enabled             = true
    path                = "/health"
    port                = 8080
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 10
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_placement_group" "test" {
  name     = "test"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "user" {
  name                      = "${local.common_name}-user"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  vpc_zone_identifier       = local.private_subnet_ids
  launch_template {
    id      = aws_launch_template.user.id
    version = aws_launch_template.user.latest_version
  }
  target_group_arns = [ aws_lb_target_group.user.arn ]
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  dynamic "tag" {
    for_each = merge(
                        local.common_tags,
                        {
                            Name = "${local.common_name}-user"
                        }
                    )
    content {
        key                 = tag.key
        value               = tag.value
        propagate_at_launch = true
    }
    
  }

  timeouts {
    delete = "15m"
  }
}
