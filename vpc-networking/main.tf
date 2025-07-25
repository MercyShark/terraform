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

resource "aws_vpc" "my_custom_vpc" {
  cidr_block = var.vpc_cidr_block_address
  tags = {
    Name = "my_custom_vpc_made_with_terraform"
  }
}

resource "aws_internet_gateway" "my_custom_itg" {
  vpc_id = aws_vpc.my_custom_vpc.id
  tags = {
    Name : "My custom Internet Gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_custom_itg.id
  }

  tags = {
    Name : "Public Route Table"
  }
}


resource "aws_eip" "my_elastic_ip_for_nat_gatway" {
  depends_on = [ aws_internet_gateway.my_custom_itg ]
}

resource "aws_nat_gateway" "my_custom_nat_gateway" {

  allocation_id = aws_eip.my_elastic_ip_for_nat_gatway.id
  subnet_id = aws_subnet.public_subnet_A.id
  tags = {
    Name: "My Custom Nat Gatway"
  }
  depends_on = [ aws_internet_gateway.my_custom_itg]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_custom_vpc.id
  tags = {
    Name : "Public Route Table"
  }

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_custom_nat_gateway.id
  }
}

resource "aws_route_table_association" "public_subnet_association_with_route_table" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_A.id
}

resource "aws_route_table_association" "private_subnet_association_with_route_table" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_A.id
}

resource "aws_subnet" "public_subnet_A" {
  cidr_block              = var.public_subnet_a_cidr_block
  vpc_id                  = aws_vpc.my_custom_vpc.id
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "Public Subnet A"
  }

}


resource "aws_subnet" "public_subnet_B" {
  cidr_block              = var.public_subnet_b_cidr_block
  vpc_id                  = aws_vpc.my_custom_vpc.id
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "Public Subnet B"
  }
}


resource "aws_subnet" "private_subnet_A" {
  cidr_block        = var.private_subnet_a_cidr_block
  vpc_id            = aws_vpc.my_custom_vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    "Name" = "Private Subnet A"
  }
}

resource "aws_subnet" "private_subnet_B" {
  cidr_block        = var.private_subnet_b_cidr_block
  vpc_id            = aws_vpc.my_custom_vpc.id
  availability_zone = "ap-south-1b"
  tags = {
    "Name" = "Private Subnet B"
  }
}

resource "aws_key_pair" "testing_key_pair" {
  key_name   = "my test key"
  public_key = file(var.public_key_path)
}

data "external" "ip_lookup" {
  program = ["python", "${path.module}/get_public_ip.py"]
}

resource "aws_security_group" "my_custom_sg_for_public_instance" {
  name   = "my_custom_sg"
  vpc_id = aws_vpc.my_custom_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    description = "For Accessing the public Instance"
    protocol    = "tcp"
    cidr_blocks = [
      data.external.ip_lookup.result["authorized_ip"]
    ]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    description = "For Web Server Nginx"
    protocol    = "tcp"
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

  tags = {
    Name : "Custom Security Group Build using Terraform"
  }
}


resource "aws_security_group" "my_custom_sg_for_private_instance" {
  vpc_id = aws_vpc.my_custom_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    description = "For Accessing the Private Instance via Bastion Public Instance"
    protocol    = "tcp"
    security_groups = [
      aws_security_group.my_custom_sg_for_public_instance.id
    ]
  }

  ingress {
    from_port = 8
    to_port   = 0
    protocol  = "icmp"
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

  tags = {
    Name : "Private SG for Testing"
  }
}


resource "aws_instance" "sample_ec2_instance" {
  ami                         = var.ubuntu_ami_id
  subnet_id                   = aws_subnet.public_subnet_A.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.testing_key_pair.key_name
  vpc_security_group_ids  = [
    aws_security_group.my_custom_sg_for_public_instance.id
  ]
  user_data = file(
    "${path.module}/myscript.sh"
  )
  tags = {
    Name : "Bastion Host"
  }
}


resource "aws_instance" "private_ec2_instance" {
  ami           = var.ubuntu_ami_id
  subnet_id     = aws_subnet.private_subnet_A.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.testing_key_pair.key_name
  vpc_security_group_ids  = [
    aws_security_group.my_custom_sg_for_private_instance.id
  ]
  tags = {
    Name : "Private Host"
  }
}

output "public_ip_of_sample_ec2_instance" {
  value = aws_instance.sample_ec2_instance.public_ip
}

output "private_ip_of_private_ec2_instance" {
  value = aws_instance.private_ec2_instance.private_ip
}





