output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.ec2.id
}

output "instance_arn" {
  description = "ARN da instância EC2"
  value       = aws_instance.ec2.arn
}

output "public_ip" {
  description = "IP público da instância"
  value       = aws_instance.ec2.public_ip
}

output "private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.ec2.private_ip
}

output "security_group_id" {
  description = "ID do security group"
  value       = aws_security_group.ec2.id
}

output "ssm_iam_role_arn" {
  description = "ARN da IAM Role para Session Manager (SSM)"
  value       = var.enable_ssm ? aws_iam_role.ssm[0].arn : null
}

output "ssm_iam_instance_profile_arn" {
  description = "ARN do Instance Profile para SSM"
  value       = var.enable_ssm ? aws_iam_instance_profile.ssm[0].arn : null
}
