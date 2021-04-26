terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.12.23"
  backend "s3" {}
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}





###########  EC2 ##############


resource "aws_instance" "app_server" {
  ami           = "ami-05d72852800cbf29e"
  instance_type = "t2.micro"

  tags = {
    Name = "Processing App Instance"
    Project = "Automated Analytics"
  }
}



############# RDS  #############






############# EMR ##############

