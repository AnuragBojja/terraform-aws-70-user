locals {
  common_tags = {
    Project_name = var.project_name
    Env = var.env
    Terraform = "true"
  }
  common_name = ("${var.project_name}-${var.env}")
  ami_id = data.aws_ami.roboshop_ami.id
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  user_sg_id = data.aws_ssm_parameter.user_sg_id.value
  private_subnet_id = split(",",data.aws_ssm_parameter.private_subnet_ids.value)[0]
  private_subnet_ids = split(",",data.aws_ssm_parameter.private_subnet_ids.value)
  ssh_loginpass = data.aws_ssm_parameter.ssh_loginpass.value
}