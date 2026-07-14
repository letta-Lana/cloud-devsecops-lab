terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Security group: only allows SSH from your IP, and HTTP from anywhere
resource "aws_security_group" "web_sg" {
  name        = "project2-web-sg"
  description = "Allow SSH from my IP only, HTTP from anywhere"

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["31.94.26.189/32"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project2-web-sg"
  }
}

# The EC2 instance itself
resource "aws_instance" "web" {
  ami                    = "ami-0d68691f9cd24a9b7" # Amazon Linux 2023, eu-west-2
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "project2-web-server"
  }
}

# SSH key pair for accessing the instance
resource "aws_key_pair" "deployer" {
  key_name   = "project2-key"
  public_key = file("project2-key.pub")
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}