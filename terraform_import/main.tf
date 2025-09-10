terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}


resource "aws_instance" "ec2" {
    ami = "ami-0861f4e788f5069dd"
    instance_type = "t2.micro"
    tags = {
        Name : "my instance tracked my terraform import"
    }
}