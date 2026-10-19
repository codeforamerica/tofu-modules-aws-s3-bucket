data "aws_caller_identity" "identity" {}

data "aws_s3_bucket" "logging" {
  for_each = var.logging_bucket != null ? toset(["this"]) : toset([])

  bucket = var.logging_bucket
  region = var.region
}
