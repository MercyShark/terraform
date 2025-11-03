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


resource "random_password" "rds_password" {
  length = 16
}

output "password" {
  value = random_password.rds_password.result
  sensitive = true
}
