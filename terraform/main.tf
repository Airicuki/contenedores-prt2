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
# Ubuntu AMI
# -----------------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "fintech_ec2" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.fintech_sg.id]

  user_data = <<-EOF
#!/bin/bash

apt-get update -y

apt-get install -y docker.io docker-compose git

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

cd /home/ubuntu

git clone ${var.github_repo}

echo '#!/bin/bash' > /home/ubuntu/start.sh
echo 'sleep 30' >> /home/ubuntu/start.sh
echo 'cd /home/ubuntu/contenedores-prt2' >> /home/ubuntu/start.sh
echo 'docker-compose up -d --build > /home/ubuntu/deploy.log 2>&1' >> /home/ubuntu/start.sh

chmod +x /home/ubuntu/start.sh

nohup bash /home/ubuntu/start.sh &

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