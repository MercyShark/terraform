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

resource "aws_ebs_volume" "my_ebs_volume" {
  availability_zone = "ap-south-1a"
  size = 2

  tags = {
    Name = "My EBS Volume"
  }
}

resource "aws_key_pair" "testing_key_pair" {
  key_name   = "my test key"
  public_key = file("C:/Users/Rishabh/.ssh/testing_key_pair.pub")
}


data "external" "ip_lookup" {
  program = ["python", "${path.module}/get_public_ip.py"]
}

resource "aws_security_group" "my_custom_sg" {
    name        = "my_custom_sg_for_ebs"
    ingress {
    from_port   = 22
    to_port     = 22
    description = "For Accessing the public Instance"
    protocol    = "tcp"
    cidr_blocks = [
      data.external.ip_lookup.result["authorized_ip"]
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name = "Custom EBS Security Group"
  }
}

resource "aws_instance" "instance_with_volume" {
    ami = "ami-0f918f7e67a3323f0" 
    key_name = aws_key_pair.testing_key_pair.key_name
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.my_custom_sg.id]
    availability_zone = "ap-south-1a"
    root_block_device {
        volume_size = 8
        volume_type = "gp2"
    }

    user_data = <<-EOF
      #!/bin/bash
        sudo su 
        mkfs -t ext4 /dev/xdvf
        mkdir /mnt/data
        mount /dev/xvdf /mnt/data
        echo 'hello world' > /mnt/data/hello.txt
        EOF
    tags = {
      Name = "Instance with EBS Volume"
    }
}

resource "aws_volume_attachment" "my_attachment" {
    device_name = "/dev/sdf"
    volume_id   = aws_ebs_volume.my_ebs_volume.id
    instance_id = aws_instance.instance_with_volume.id
}

output "security_group_id" {
 value = aws_security_group.my_custom_sg.id  
} 

