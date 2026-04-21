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

