terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.11"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "access_key"
  secret_key = "secret_key"
}

#vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/10"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "VPC-demo"
  }
}

#subnet
resource "aws_subnet" "subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"

    tags = {
        Name = "subnet-demo"
    }
}

#internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "prod-igw"
    }
}

#routetable
resource "aws_route_table" "route" {
    vpc_id = aws_vpc.vpc.id
    
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

    tags = {
        Name = "route-demo"
    }
}

#routetable association
resource "aws_route_table_association" "association"{
    subnet_id = aws_subnet.subnet.id
    route_table_id = aws_route_table.route.id
}

#security group
resource "aws_security_group" "security" {
    vpc_id = aws_vpc.vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "sg"
    }
}


###key-pair
resource "aws_key_pair" "key_pair" {
  key_name   = "key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "key-pair"
}

#instance
resource "aws_instance" "ec2" {
  ami = "ami-09538990a0c4fe9be"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet.id
  associate_public_ip_address = "true"
  key_name = aws_key_pair.kp.id
  vpc_security_group_ids = [aws_security_group.security.id]
  
  tags = {
        Name = "instance"
    }
}  
