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
  profile = "sova-profile"
}

variable "ubuntu_ami_id" {}
variable "public_key_path" {}
variable "public_ip_address" {}
variable "amazon_linux_ami_id" {}
variable "private_key_path" {
  
}
variable "domain_name" {
  
}


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
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ 
        "0.0.0.0/0"
       ]
    }
    ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = [ 
        "0.0.0.0/0"
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
}


resource "aws_instance" "ubuntu_instances" {
    count = 1
    ami = var.ubuntu_ami_id
    instance_type = "t2.micro"
    associate_public_ip_address = true
    key_name = aws_key_pair.testing_key_pair.key_name
    vpc_security_group_ids = [ aws_security_group.my_custom_sg.id ]
    user_data = <<-EOF
      #!/bin/bash
      sudo apt-get update
      sudo apt-get install -y nginx certbot python3-certbot-nginx
      sudo systemctl enable nginx
      sudo systemctl start nginx
    EOF

    tags = {
      Name = "EC2-testing-${count.index + 1}"
    }

}


resource "aws_eip" "my_eip" {
  instance = aws_instance.ubuntu_instances[0].id
}


resource "null_resource" "upload_files" {
  depends_on = [aws_instance.ubuntu_instances[0]]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_eip.my_eip.public_ip
  }

  provisioner "file" {
    source      = "index.html"
    destination = "/home/ubuntu/index.html"
  }

  provisioner "file" {
    source      = "video.mp4"
    destination = "/home/ubuntu/video.mp4"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/index.html /var/www/html/index.html",
      "sudo mv /home/ubuntu/video.mp4 /var/www/html/video.mp4",
    ]
  }
}


data "aws_route53_zone" "milkeywayzone" {
  name = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "my_record" {
  zone_id  = data.aws_route53_zone.milkeywayzone.zone_id
  name = data.aws_route53_zone.milkeywayzone.name
  type = "A"
  ttl = 300
  records = [
    aws_eip.my_eip.public_ip
  ]
}
resource "aws_route53_record" "my_record_for_www_subdomain" {
  zone_id  = data.aws_route53_zone.milkeywayzone.zone_id
  name = "www.${data.aws_route53_zone.milkeywayzone.name}"
  type = "A"
  ttl = 300
  records = [
    aws_eip.my_eip.public_ip
  ]
}


output "link_1" {
  value = aws_route53_record.my_record.name
}
output "link_2" {
  value = aws_route53_record.my_record_for_www_subdomain.name
}

# output "public_ips" {
#   value = [for instance in aws_instance.ubuntu_instances : instance.public_ip]
# }

# output "ssh" {
#   value = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.ubuntu_instances[0].public_ip}"
# }