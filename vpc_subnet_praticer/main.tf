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

resource "aws_vpc" "my_custom_vpc" {
    cidr_block = var.vpc_cidr_block_address
    tags = {
        Name = "my_custom_vpc_made_with_terraform"
    }
}

output "my_custom_vpc_cird_block" {
  value = aws_vpc.my_custom_vpc.cidr_block
}


