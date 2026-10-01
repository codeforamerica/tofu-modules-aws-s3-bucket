data "aws_caller_identity" "identity" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "logging" {
  bucket = var.logging_bucket
  region = local.region
}
