resource "aws_s3_bucket_logging" "enabled" {
  for_each = var.logging_bucket != null ? toset(["this"]) : toset([])

  bucket = aws_s3_bucket.this.id
  region = var.region

  target_bucket = var.logging_bucket
  target_prefix = "${local.logs_path}/s3accesslogs/${var.name}"

  lifecycle {
    precondition {
      condition     = data.aws_s3_bucket.logging["this"].bucket_region == var.region
      error_message = "The logging bucket must be in the same region as the bucket (${var.region})."
    }
  }
}

resource "aws_cloudwatch_log_delivery_source" "logging" {
  for_each = var.logging_cloudwatch_log_group_arn != null ? toset(["this"]) : toset([])

  name         = var.name
  log_type     = "S3_SERVER_ACCESS_LOGS"
  resource_arn = aws_s3_bucket.this.arn
  region       = var.region

  tags = var.tags
}

resource "aws_cloudwatch_log_delivery_destination" "logging" {
  for_each = var.logging_cloudwatch_log_group_arn != null ? toset(["this"]) : toset([])

  name   = var.name
  region = var.region

  delivery_destination_configuration {
    destination_resource_arn = var.logging_cloudwatch_log_group_arn
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = regex("^arn:[^:]+:logs:([^:]+):", var.logging_cloudwatch_log_group_arn)[0] == var.region
      error_message = "The logging_cloudwatch_log_group_arn must be in the same region as the bucket (${var.region})."
    }
  }
}

resource "aws_cloudwatch_log_delivery" "logging" {
  for_each = var.logging_cloudwatch_log_group_arn != null ? toset(["this"]) : toset([])

  delivery_source_name     = aws_cloudwatch_log_delivery_source.logging["this"].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.logging["this"].arn
  region                   = var.region

  tags = var.tags
}
