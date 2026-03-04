# Versões requeridas do Terraform e provedores
terraform {
  required_version = ">= 1.0"

  # Backend remoto para armazenar o estado (tfstate) no S3
  # O DynamoDB é usado para locking e prevenir conflitos
  backend "s3" {
    bucket         = "terraform-state-streamlit"
    key            = "terraform-aws/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
