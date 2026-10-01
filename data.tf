data "aws_caller_identity" "identity" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "logging" {
  for_each = var.logging_bucket != null ? toset(["this"]) : toset([])

  bucket = var.logging_bucket
  region = local.region
}
