output "bucket_name" {
  description = "Nome do S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN do S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}
