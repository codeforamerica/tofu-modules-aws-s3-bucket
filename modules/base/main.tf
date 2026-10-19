resource "aws_s3_bucket" "this" {
  bucket        = var.name
  region        = var.region
  force_destroy = var.force_delete

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(var.name) >= 3 && length(var.name) <= 63
      error_message = <<-EOT
        The bucket name (${var.name}) must be between 3 and 63 characters.
        Shorten project, environment, or name, or set add_suffix to true to
        truncate the name automatically.
        EOT
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id
  region = var.region

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  region = var.region

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  region = var.region

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  for_each = var.object_lock.enabled ? toset(["this"]) : toset([])

  # Object lock requires versioning to be enabled on the bucket first.
  depends_on = [aws_s3_bucket_versioning.this]

  bucket = aws_s3_bucket.this.id
  region = var.region

  dynamic "rule" {
    for_each = var.object_lock.days != null ? toset(["this"]) : toset([])

    content {
      default_retention {
        mode = var.object_lock.mode
        days = var.object_lock.days
      }
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  region = var.region

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  # Referencing noncurrent-version behavior requires versioning to be enabled
  # first.
  depends_on = [aws_s3_bucket_versioning.this]

  bucket = aws_s3_bucket.this.id
  region = var.region

  rule {
    id     = "state"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    dynamic "expiration" {
      for_each = var.expiration != null ? toset(["this"]) : toset([])
      content {
        days = var.expiration
      }
    }

    dynamic "transition" {
      for_each = var.storage_class_transitions
      content {
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  # The public access block must be in place before a bucket policy can be
  # applied.
  depends_on = [aws_s3_bucket_public_access_block.this]

  bucket = aws_s3_bucket.this.id
  region = var.region
  policy = var.policy
}
