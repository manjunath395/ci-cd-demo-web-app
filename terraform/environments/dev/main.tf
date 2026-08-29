module "s3" {
  source = "../../modules/s3"

  bucket_name = var.bucket_name
  environment = var.environment
  versioning  = var.versioning

  tags = {
    Project = "ci-cd-demo-web-app"
    Owner   = "DevOps"
  }
}
