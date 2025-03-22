terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "default_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    name = "${var.prefix}-vpc "
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.default_vpc.id
  availability_zone = var.availability_zones[0]
  cidr_block        = "10.0.1.0/24"
  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "allows ssh inbound traffic"
  vpc_id      = aws_vpc.default_vpc.id
  tags = {
    name = "${var.prefix}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_rule" {
  count             = var.ssh_access ? 1 : 0
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = aws_vpc.default_vpc.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}

resource "aws_instance" "main_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    name = "${var.prefix}-ec2"
  }
}