# Módulo S3 Bucket usando terraform-aws-modules
# https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.bucket_name

  # Controle de propriedade de objeto
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  # Versionamento habilitado para proteção de dados
  versioning = {
    enabled = true
  }

  # Bloqueia todo acesso público por padrão
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = var.tags
}
