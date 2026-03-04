# Outputs - Módulo EC2
output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = module.ec2.public_ip
}

output "ec2_private_ip" {
  description = "IP privado da instância EC2"
  value       = module.ec2.private_ip
}

# Outputs - Módulo S3
output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = module.s3.bucket_arn
}
