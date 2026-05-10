provider "aws" {
  region = var.aws_region
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "fintech_sg" {
  name        = "fintech-security-group"
  description = "Permitir acceso SSH, frontend y backend"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frontend"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Backend API"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "fintech_ec2" {

  ami                    = "ami-0c1c30571d2dae5c9"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.fintech_sg.id]

  user_data = <<-EOF
              #!/bin/bash

              apt update -y

              apt install docker.io docker-compose git -y

              systemctl start docker
              systemctl enable docker

              usermod -aG docker ubuntu

              cd /home/ubuntu

              git clone ${var.github_repo}

              cd FinTech-App-Unir

              docker compose up -d --build

              EOF

  tags = {
    Name = "FinTech-Docker-Compose"
  }
}

# -----------------------------
# Output Public IP
# -----------------------------
output "public_ip" {
  value = aws_instance.fintech_ec2.public_ip
}