terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
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

  owners = ["099720109477"] # Canonical
}

locals {
  allowed_cidrs = var.allow_all_ip_addresses ? ["0.0.0.0/0"] : ["${var.my_ip_address}/32"]
}

resource "aws_key_pair" "section-A-admin" {
  key_name = "section-A-admin-key"
  public_key = file(var.path_to_ssh_public_key)
}

resource "aws_instance" "foo_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name        = aws_key_pair.section-A-admin.key_name
  security_groups = [aws_security_group.foo_group.name]

  tags = {
    Name = "foo_instance"
  }
}

resource "aws_security_group" "foo_group" {
  name = "ass2-section-A"

  # SSH (Only allow user to SSH into instance.)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP in
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS out
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "foo_instance_public_ip" {
  value = aws_instance.foo_instance.public_ip
}