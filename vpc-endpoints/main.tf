provider "aws" {
  region = "ap-south-1"
  profile = "sova-profile"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
    enable_dns_support   = true
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "my_elastic_ip_for_nat_gatway" {
  depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_nat_gateway" "my_custom_nat_gateway" {
  allocation_id = aws_eip.my_elastic_ip_for_nat_gatway.id
  subnet_id = aws_subnet.public.id
  tags = {
    Name: "My Custom Nat Gatway"
  }
  depends_on = [ aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_custom_nat_gateway.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


resource "aws_iam_role" "ssm_role" {
  name = "SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "private" {
  ami                    = "ami-0f9708d1cd2cfee41"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  associate_public_ip_address = false
  tags = {
    Name = "PrivateInstance"
  }
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
}

variable "region" {
  default = "ap-south-1"
}

locals {
  services = {
    "ec2messages" : {
      "name" : "com.amazonaws.${var.region}.ec2messages"
    },
    "ssm" : {
      "name" : "com.amazonaws.${var.region}.ssm"
    },
    "ssmmessages" : {
      "name" : "com.amazonaws.${var.region}.ssmmessages"
    }
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each = local.services
  vpc_id   = aws_vpc.main.id
  service_name        = each.value.name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_https.id]
  private_dns_enabled = true
  ip_address_type     = "ipv4"
  subnet_ids          = [aws_subnet.private.id]
}

resource "aws_security_group" "ssm_https" {
  name        = "allow_ssm"
  description = "Allow SSM traffic"
  vpc_id      =  aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ aws_subnet.private.cidr_block ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


