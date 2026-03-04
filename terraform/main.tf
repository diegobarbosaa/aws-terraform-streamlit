# Módulo EC2 - Instância Ubuntu com Security Group
module "ec2" {
  source = "./modules/ec2"

  instance_name      = "terraform-streamlit-ec2-ubuntu"
  instance_type      = "t2.micro"
  enable_ssm         = true
  enable_streamlit   = true
  
  # Git Clone (deixe vazio para usar scripts inline)
  git_repository_url = "https://github.com/SEU-USUARIO/SEU-REPO.git"
  git_branch         = "main"

  tags = {
    Ambiente    = "Desenvolvimento"
    Projeto     = "Terraform Stremlit"
    Responsavel = "Diego Vanderlei"
  }
}

# Módulo S3 - Bucket para armazenamento
module "s3" {
  source = "./modules/s3"

  bucket_name = "terraform-streamlit"

  tags = {
    Ambiente    = "Desenvolvimento"
    Projeto     = "Terraform Stremlit"
    Responsavel = "Diego Vanderlei"
  }
}
