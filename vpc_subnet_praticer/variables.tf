variable "vpc_cidr_block_address" {
  description = "VPC cidr block for Infra"
}
variable "public_subnet_a_cidr_block" {}
variable "public_subnet_b_cidr_block" {}
variable "private_subnet_a_cidr_block" {}
variable "private_subnet_b_cidr_block" {}


variable "ubuntu_ami_id" {}
variable "public_key_path" {}