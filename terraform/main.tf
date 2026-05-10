# Configuración del proveedor de AWS
provider "aws" { 
  # Región de AWS especificada en la variable aws_region
  region = var.aws_region
}

# -----------------------------
# Configuración del Security Group
# -----------------------------
resource "aws_security_group" "fintech_sg" {
  # Nombre del Security Group
  name        = "fintech-security-group"
  # Descripción del Security Group
  description = "Permitir acceso SSH, frontend y backend"

  # Reglas de entrada (ingress)
  ingress {
    # Permitir acceso SSH (puerto 22)
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Acceso desde cualquier IP
  }

  ingress {
    # Permitir acceso al frontend (puerto 8080)
    description = "Frontend"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Acceso desde cualquier IP
  }

  ingress {
    # Permitir acceso a la API del backend (puerto 3001)
    description = "Backend API"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Acceso desde cualquier IP
  }

  # Reglas de salida (egress)
  egress {
    # Permitir todo el tráfico de salida
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# Configuración de la AMI de Ubuntu
# -----------------------------
data "aws_ami" "ubuntu" {
  # Seleccionar la AMI más reciente
  most_recent = true

  # Propietario de la AMI (Canonical)
  owners = ["099720109477"]

  # Filtro para buscar AMIs de Ubuntu 22.04
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # Filtro para buscar AMIs con virtualización HVM
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------
# Configuración de la instancia EC2
# -----------------------------
resource "aws_instance" "fintech_ec2" {
  # ID de la AMI de Ubuntu
  ami                    = data.aws_ami.ubuntu.id
  # Tipo de instancia (t2.micro)
  instance_type          = "t2.micro"
  # Nombre de la clave SSH especificada en la variable key_name
  key_name               = var.key_name
  # Asociar el Security Group creado anteriormente
  vpc_security_group_ids = [aws_security_group.fintech_sg.id]

  # Script de inicialización (user_data)
  user_data = <<-EOF
#!/bin/bash

# Actualizar los paquetes del sistema
apt-get update -y

# Instalar Docker, Docker Compose y Git
apt-get install -y docker.io docker-compose git

# Habilitar y arrancar el servicio de Docker
systemctl enable docker
systemctl start docker

# Agregar el usuario 'ubuntu' al grupo de Docker
usermod -aG docker ubuntu

# Cambiar al directorio /home/ubuntu
cd /home/ubuntu

# Clonar el repositorio de GitHub especificado en la variable github_repo
git clone ${var.github_repo}

# Crear un script para iniciar los contenedores
echo '#!/bin/bash' > /home/ubuntu/start.sh
echo 'sleep 30' >> /home/ubuntu/start.sh
echo 'cd /home/ubuntu/contenedores-prt2' >> /home/ubuntu/start.sh
echo 'docker-compose up -d --build > /home/ubuntu/deploy.log 2>&1' >> /home/ubuntu/start.sh

# Hacer el script ejecutable
chmod +x /home/ubuntu/start.sh

# Ejecutar el script en segundo plano
nohup bash /home/ubuntu/start.sh &

EOF

  # Etiquetas para la instancia
  tags = {
    Name = "FinTech-Docker-Compose"
  }
}

# -----------------------------
# Salida de la IP pública
# -----------------------------
output "public_ip" {
  # Mostrar la IP pública de la instancia EC2
  value = aws_instance.fintech_ec2.public_ip
}