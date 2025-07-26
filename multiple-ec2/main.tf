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

variable "ubuntu_ami_id" {}
variable "public_key_path" {}
variable "public_ip_address" {}

resource "aws_key_pair" "testing_key_pair" {
  key_name   = "my test key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "my_custom_sg" {
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [
            var.public_ip_address
        ]
        
    }
}

resource "aws_instance" "ubuntu_instances" {
    count = 2
    ami = var.ubuntu_ami_id
    instance_type = "t2.micro"
    associate_public_ip_address = true
    key_name = aws_key_pair.testing_key_pair.key_name
    vpc_security_group_ids = [ aws_security_group.my_custom_sg.id ]

    tags = {
      Name = "EC2-testing-${count.index + 1}"
    }

}
output "public_ips" {
  value = [for instance in aws_instance.ubuntu_instances : instance.public_ip]
}