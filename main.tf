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
    private_key = local.ssh_loginpass
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