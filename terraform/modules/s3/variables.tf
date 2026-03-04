variable "bucket_name" {
  description = "Nome do bucket S3"
  type        = string
  default     = "terraform-streamlit"
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}
