# Variável para região AWS
variable "aws_region" {
  description = "Região AWS para deploy dos recursos"
  type        = string
  default     = "us-east-1"
}
