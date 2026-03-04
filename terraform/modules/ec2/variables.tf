variable "instance_name" {
  description = "Nome para a instância EC2"
  type        = string
  default     = "meu-ec2-ubuntu"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID da AMI para usar na instância (vazio usa Ubuntu 22.04 padrão)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Nome do par de chaves SSH (opcional, não necessário se usar SSM)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID do VPC (vazio usa o VPC padrão)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}

variable "enable_streamlit" {
  description = "Habilita instalação do Docker e deploy do Streamlit via user_data"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Habilita AWS Systems Manager Session Manager para acesso sem SSH"
  type        = bool
  default     = true
}

variable "git_repository_url" {
  description = "URL do repositório Git para clonar o app Streamlit"
  type        = string
  default     = ""
}

variable "git_branch" {
  description = "Branch do Git para clonar (padrão: main)"
  type        = string
  default     = "main"
}
