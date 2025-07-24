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

variable "vpc_cidr_block_address" {
  description = "VPC cidr block for Infra"
}

variable "public_subnet_a_cidr_block" {}
variable "public_subnet_b_cidr_block" {}
variable "private_subnet_a_cidr_block" {}
variable "private_subnet_b_cidr_block" {}


resource "aws_vpc" "my_custom_vpc" {
    cidr_block = var.vpc_cidr_block_address
    tags = {
        Name = "my_custom_vpc_made_with_terraform"
    }
}

resource "aws_subnet" "public_subnet_A" { 
  cidr_block =  var.public_subnet_a_cidr_block
  vpc_id = aws_vpc.my_custom_vpc.id
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    "name" = "Public Subnet A" 
  }
  
}


resource "aws_subnet" "public_subnet_B" { 
  cidr_block =  var.public_subnet_b_cidr_block
  vpc_id = aws_vpc.my_custom_vpc.id
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    "name" = "Public Subnet B" 
  }
}


resource "aws_subnet" "private_subnet_A" { 
  cidr_block =  var.private_subnet_a_cidr_block
  vpc_id = aws_vpc.my_custom_vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    "name" = "Private Subnet A" 
  }
}

resource "aws_subnet" "private_subnet_B" { 
  cidr_block =  var.private_subnet_b_cidr_block
  vpc_id = aws_vpc.my_custom_vpc.id
  availability_zone = "ap-south-1b"
  tags = {
    "name" = "Private Subnet B" 
  }
}

output "my_custom_vpc_cird_block" {
  value = aws_vpc.my_custom_vpc.cidr_block
}


