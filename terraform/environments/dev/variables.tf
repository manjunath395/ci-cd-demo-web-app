variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "versioning" {
  description = "S3 bucket versioning status"
  type        = string
  default     = "Enabled"
}
