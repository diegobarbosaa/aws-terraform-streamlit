# Busca a AMI mais recente do Ubuntu 22.04 LTS (Jammy Jellyfish)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Busca o VPC padrão da região
data "aws_vpc" "default" {
  default = true
}

# Busca todas as subnets do VPC padrão
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Seleciona a primeira subnet disponível
data "aws_subnet" "default" {
  id = element(data.aws_subnets.default.ids, 0)
}

# Define o user_data condicionalmente
# Usa Git Clone se git_repository_url for fornecido, senão usa scripts inline
locals {
  user_data_git = <<-EOF
              #!/bin/bash
              set -e

              # Atualiza pacotes
              apt-get update

              # Instala Docker e Git
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh
              apt-get install -y git

              # Cria diretório final do app
              mkdir -p /app/streamlit
              cd /app/streamlit

              # Clona o repositório em pasta temporária
              git clone -b ${var.git_branch} ${var.git_repository_url} /tmp/repo-temp

              # Copia apenas o conteúdo da pasta app/ para o diretório final
              cp -r /tmp/repo-temp/app/* .

              # Limpa pasta temporária
              rm -rf /tmp/repo-temp

              # Build da imagem Docker
              docker build -t streamlit-app .

              # Roda o container
              # --restart=always: reinicia automaticamente se falhar ou no boot
              # -p 8501:8501: expõe a porta do Streamlit
              # -d: roda em background
              docker run -d --restart=always -p 8501:8501 --name streamlit-app streamlit-app
              EOF

  user_data_inline = <<-EOF
              #!/bin/bash
              set -e

              # Atualiza pacotes
              apt-get update

              # Instala Docker
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh

              # Cria diretório do app
              mkdir -p /app/streamlit
              cd /app/streamlit

              # Cria Dockerfile
              cat > Dockerfile << 'DOCKERFILE'
              FROM python:3.11-slim
              WORKDIR /app
              RUN apt-get update && apt-get install -y --no-install-recommends gcc && rm -rf /var/lib/apt/lists/*
              COPY requirements.txt .
              RUN pip install --no-cache-dir -r requirements.txt
              COPY main.py .
              EXPOSE 8501
              CMD ["streamlit", "run", "main.py", "--server.address=0.0.0.0", "--server.headless=true"]
              DOCKERFILE

              # Cria requirements.txt
              cat > requirements.txt << 'REQS'
              streamlit
              pandas
              numpy
              pydeck
              REQS

              # Cria main.py
              cat > main.py << 'MAINPY'
              import streamlit as st
              import pandas as pd
              import numpy as np
              import pydeck as pdk

              def main():
                  chart_data = pd.DataFrame(
                      np.random.randn(1000, 2) / [50, 50] + [37.76, -122.4],
                      columns=pd.Index(["lat", "lon"], name=None),
                  )
                  st.pydeck_chart(
                      pdk.Deck(
                          map_style="",
                          initial_view_state=pdk.ViewState(
                              latitude=37.76,
                              longitude=-122.4,
                              zoom=11,
                              pitch=50,
                          ),
                          layers=[
                              pdk.Layer(
                                  "HexagonLayer",
                                  data=chart_data,
                                  get_position="[lon, lat]",
                                  radius=200,
                                  elevation_scale=4,
                                  elevation_range=[0, 1000],
                                  pickable=True,
                                  extruded=True,
                              ),
                              pdk.Layer(
                                  "ScatterplotLayer",
                                  data=chart_data,
                                  get_position="[lon, lat]",
                                  get_color="[200, 30, 0, 160]",
                                  get_radius=200,
                              ),
                          ],
                      )
                  )

              if __name__ == "__main__":
                  main()
              MAINPY

              # Build da imagem Docker
              docker build -t streamlit-app .

              # Roda o container
              docker run -d --restart=always -p 8501:8501 --name streamlit-app streamlit-app
              EOF

  # Usa Git se URL fornecida, senão usa inline
  user_data_streamlit = var.git_repository_url != "" ? local.user_data_git : local.user_data_inline
}

# Security Group para a instância EC2
# NOTA: SSH removido! Usamos AWS Systems Manager (Session Manager) para acesso
resource "aws_security_group" "ec2" {
  name        = "${var.instance_name}-sg"
  description = "Security group para ${var.instance_name}"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acesso HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acesso HTTPS"
  }

  # Streamlit
  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acesso Streamlit"
  }

  # Todo trafego de saida permitido
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permitir todo trafego de saida"
  }

  tags = merge(var.tags, {
    Name = "${var.instance_name}-sg"
  })
}

# IAM Role para Session Manager (SSM)
resource "aws_iam_role" "ssm" {
  count = var.enable_ssm ? 1 : 0

  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.instance_name}-ssm-role"
  })
}

# Anexar policy do SSM Managed Instance Core
resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Anexar policy para CloudWatch Logs (opcional, mas recomendado)
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile para associar a IAM Role à EC2
resource "aws_iam_instance_profile" "ssm" {
  count = var.enable_ssm ? 1 : 0

  name = "${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm[0].name

  tags = merge(var.tags, {
    Name = "${var.instance_name}-ssm-profile"
  })
}

# Instância EC2
resource "aws_instance" "ec2" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = data.aws_subnet.default.id

  # IAM Instance Profile para Session Manager (SSM)
  iam_instance_profile = var.enable_ssm ? aws_iam_instance_profile.ssm[0].name : null

  # Script de inicialização (user_data)
  # Instala Docker e sobe o app Streamlit se habilitado
  user_data = var.enable_streamlit ? local.user_data_streamlit : null

  # Configuração do volume root
  # Free Tier: 30 GB de EBS incluídos (gp2 ou gp3)
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = var.instance_name
  })
}
