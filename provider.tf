terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "roboshop-terraform-dev-daws-test"
    key    = "remote-state-roboshop-dev-70-user"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}

