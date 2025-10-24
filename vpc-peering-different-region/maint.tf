provider "aws" {
  alias = "ap_south"
  region = "ap-south-1"
  profile = "sova-profile"
}

provider "aws" {
  alias = "us_east"
  region = "us-east-1"
  profile = "sova-profile"
}

# ========== First VPC (ap-south-1) ==========
resource "aws_vpc" "first" {
  provider             = aws.ap_south
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "first-vpc-ap-south"
  }
}

# Internet Gateway for First VPC
resource "aws_internet_gateway" "first_igw" {
  provider = aws.ap_south
  vpc_id   = aws_vpc.first.id
  
  tags = {
    Name = "first-igw"
  }
}

# Public Subnet in First VPC
resource "aws_subnet" "first_public" {
  provider                = aws.ap_south
  vpc_id                  = aws_vpc.first.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "first-public-subnet"
  }
}

# Route Table for First VPC Public Subnet
resource "aws_route_table" "first_public_rt" {
  provider = aws.ap_south
  vpc_id   = aws_vpc.first.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.first_igw.id
  }
  
  tags = {
    Name = "first-public-rt"
  }
}

# Associate Route Table with First Public Subnet
resource "aws_route_table_association" "first_public_rta" {
  provider       = aws.ap_south
  subnet_id      = aws_subnet.first_public.id
  route_table_id = aws_route_table.first_public_rt.id
}

# ========== Second VPC (us-east-1) ==========
resource "aws_vpc" "second" {
  provider             = aws.us_east
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "second-vpc-us-east"
  }
}

# Internet Gateway for Second VPC
resource "aws_internet_gateway" "second_igw" {
  provider = aws.us_east
  vpc_id   = aws_vpc.second.id
  
  tags = {
    Name = "second-igw"
  }
}

# Public Subnet in Second VPC
resource "aws_subnet" "second_public" {
  provider                = aws.us_east
  vpc_id                  = aws_vpc.second.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "second-public-subnet"
  }
}

# Route Table for Second VPC Public Subnet
resource "aws_route_table" "second_public_rt" {
  provider = aws.us_east
  vpc_id   = aws_vpc.second.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.second_igw.id
  }
  
  tags = {
    Name = "second-public-rt"
  }
}

# Associate Route Table with Second Public Subnet
resource "aws_route_table_association" "second_public_rta" {
  provider       = aws.us_east
  subnet_id      = aws_subnet.second_public.id
  route_table_id = aws_route_table.second_public_rt.id
}

# ========== Security Groups ==========

# Security Group for First VPC EC2
resource "aws_security_group" "first_sg" {
  provider    = aws.ap_south
  name        = "first-vpc-sg"
  description = "Security group for first VPC EC2"
  vpc_id      = aws_vpc.first.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ICMP from second VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "first-vpc-sg"
  }
}


# Security Group for Second VPC EC2
resource "aws_security_group" "second_sg" {
  provider    = aws.us_east
  name        = "second-vpc-sg"
  description = "Security group for second VPC EC2"
  vpc_id      = aws_vpc.second.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ICMP from first VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "second-vpc-sg"
  }
}

# ========== VPC Peering (Cross-Region) ==========

# VPC Peering Connection from ap-south-1 to us-east-1
resource "aws_vpc_peering_connection" "peer" {
  provider      = aws.ap_south
  vpc_id        = aws_vpc.first.id
  peer_vpc_id   = aws_vpc.second.id
  peer_region   = "us-east-1"
  auto_accept   = false

  tags = {
    Name = "ap-south-to-us-east-peering"
  }
}

# Accept the peering connection in us-east-1
resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  provider                  = aws.us_east
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Name = "us-east-accept-peering"
  }
}

# Route from First VPC to Second VPC
resource "aws_route" "first_to_second" {
  provider                  = aws.ap_south
  route_table_id            = aws_route_table.first_public_rt.id
  destination_cidr_block    = aws_vpc.second.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Route from Second VPC to First VPC
resource "aws_route" "second_to_first" {
  provider                  = aws.us_east
  route_table_id            = aws_route_table.second_public_rt.id
  destination_cidr_block    = aws_vpc.first.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# ========== EC2 Instances ==========

# EC2 Instance in First VPC (ap-south-1)
resource "aws_instance" "first_ec2" {
  provider               = aws.ap_south
  ami                    = "ami-06fa3f12191aa3337"  # Amazon Linux 2 in ap-south-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.first_public.id
  vpc_security_group_ids = [aws_security_group.first_sg.id]
  
  tags = {
    Name = "first-vpc-ec2"
  }
}

# EC2 Instance in Second VPC (us-east-1)
resource "aws_instance" "second_ec2" {
  provider               = aws.us_east
  ami                    = "ami-0341d95f75f311023"  # Amazon Linux 2 in us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.second_public.id
  vpc_security_group_ids = [aws_security_group.second_sg.id]
  
  tags = {
    Name = "second-vpc-ec2"
  }
}

# ========== Outputs ==========
output "first_vpc_id" {
  value       = aws_vpc.first.id
  description = "ID of the first VPC"
}

output "first_public_subnet_id" {
  value       = aws_subnet.first_public.id
  description = "ID of the first public subnet"
}

output "first_ec2_id" {
  value       = aws_instance.first_ec2.id
  description = "ID of EC2 instance in first VPC"
}

output "first_ec2_public_ip" {
  value       = aws_instance.first_ec2.public_ip
  description = "Public IP of EC2 instance in first VPC"
}

output "second_vpc_id" {
  value       = aws_vpc.second.id
  description = "ID of the second VPC"
}

output "second_public_subnet_id" {
  value       = aws_subnet.second_public.id
  description = "ID of the second public subnet"
}

output "second_ec2_id" {
  value       = aws_instance.second_ec2.id
  description = "ID of EC2 instance in second VPC"
}

output "second_ec2_public_ip" {
  value       = aws_instance.second_ec2.public_ip
  description = "Public IP of EC2 instance in second VPC"
}

