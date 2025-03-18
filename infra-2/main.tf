terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
  region         = "us-east-1"
  bucket         = "foostatebucket-s2001"
  dynamodb_table = "foostatelock"
  key            = "terraform.tfstate"
  encrypt        = true
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
  # If allow_all_ip_addresses is true, then allow all IP addresses.
  allowed_cidrs_for_db = var.allow_all_ip_addresses ? ["0.0.0.0/0"] : (var.app_address_1 == "" && var.app_address_2 == "") ? ["${var.my_ip_address}/32"] : ["${var.my_ip_address}/32", "${var.app_address_1}/32", "${var.app_address_2}/32"]
  allowed_cidrs_for_app = var.allow_all_ip_addresses  ? ["0.0.0.0/0"] : (var.db_address == "") ? ["${var.my_ip_address}/32"] : ["${var.my_ip_address}/32", "${var.db_address}/32",]
}

resource "aws_key_pair" "admin" {
  key_name = "key_for_section_B"
  public_key = file(var.path_to_ssh_public_key)
}

# Security group for instances
resource "aws_security_group" "db_group" {
  name = "ass2-db-section-B"
  
  # SSH
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

  # PostgreSQL in
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidrs_for_db
  }

  # HTTPS out
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for instances
resource "aws_security_group" "app_group" {
  name = "ass2-app-section-B"
  
  # SSH
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

  # PostgreSQL out
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidrs_for_app
  }

  # HTTPS out
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_instance_1" {
  ami                   = data.aws_ami.ubuntu.id
  instance_type         = "t2.micro"
  
  key_name              = aws_key_pair.admin.key_name
  security_groups        = [aws_security_group.app_group.name]

  tags = {
    Name = "app-1"
  }
}

resource "aws_instance" "app_instance_2" {
  ami                   = data.aws_ami.ubuntu.id
  instance_type         = "t2.micro"

  key_name              = aws_key_pair.admin.key_name
  security_groups        = [aws_security_group.app_group.name]

  tags = {
    Name = "app-2"
  }
}

resource "aws_instance" "db_instance" {
  ami                   = data.aws_ami.ubuntu.id
  instance_type         = "t2.micro"

  key_name              = aws_key_pair.admin.key_name
  security_groups        = [aws_security_group.db_group.name]

  tags = {
    Name = "db"
  }
}

# Security group for load balancer
resource "aws_security_group" "lb_group" {
  name = "app-load-balancer-sg"

  # Ingress rule for the load balancer
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule for the load balancer
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a load balancer
resource "aws_elb" "app_load_balancer" {
  name               = "app-load-balancer"
  availability_zones = ["us-east-1e", "us-east-1f"]

  # Security group for load balancer
  security_groups = [aws_security_group.lb_group.id]

  # Specify listeners
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  # Attach app instances to the load balancer
  instances = [
    aws_instance.app_instance_1.id,
    aws_instance.app_instance_2.id,
  ]

  tags = {
    Name = "App Load Balancer"
  }
}

# Update app security group to allow traffic from load balancer
resource "aws_security_group_rule" "allow_lb_to_app" {
  type                      = "ingress"
  from_port                 = 80
  to_port                   = 80
  protocol                  = "tcp"
  security_group_id        = aws_security_group.app_group.id
  source_security_group_id  = aws_security_group.lb_group.id  # Reference the LB's security group
}

output "app_instance_1_public_ip" {
  value = aws_instance.app_instance_1.public_ip
}

output "app_instance_2_public_ip" {
  value = aws_instance.app_instance_2.public_ip
}

output "db_instance_public_ip" {
  value = aws_instance.db_instance.public_ip
}