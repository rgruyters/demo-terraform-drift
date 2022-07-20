provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Sue-Learn = "coffee-as-code"
      Owner     = "Robin Gruyters"
    }
  }
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

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  cidr = var.aws_vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.aws_private_subnet_cidrs
  public_subnets  = var.aws_public_subnet_cidrs

  enable_nat_gateway = true
}

resource "aws_key_pair" "demo_keypair" {
  key_name   = "demo_keypair_robin"
  public_key = var.public_key
}

resource "aws_instance" "demo_instance" {
  ami   = data.aws_ami.ubuntu.id
  count = var.aws_instance_count

  instance_type          = var.aws_instance_type
  key_name               = aws_key_pair.demo_keypair.id
  vpc_security_group_ids = [aws_security_group.services.id]
  subnet_id              = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]

  tags = {
    Name  = format("demo-instance-%02d", count.index + 1)
    Owner = "Robin Gruyters"
  }

}

resource "aws_security_group" "services" {
  name        = "services"
  description = "Default security group for meetup"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Services security rules"
    Owner = "Robin Gruyters"
  }

}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
