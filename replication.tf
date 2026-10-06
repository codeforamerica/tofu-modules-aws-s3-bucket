resource "aws_kms_replica_key" "replica" {
  for_each = var.replication.enabled && var.kms.create ? toset(["this"]) : toset([])

  description             = "Encryption key for bucket ${local.replica_bucket_name}"
  deletion_window_in_days = var.kms.recovery_period
  primary_key_arn         = aws_kms_key.bucket["this"].arn
  region                  = local.replica_region

  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/key-policy.yaml.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    bucket : local.replica_bucket_name
    partition : data.aws_partition.current.partition
    principals : var.kms.allowed_principals
  })))

  tags = var.tags

  lifecycle {
    precondition {
      condition     = aws_kms_key.bucket["this"].multi_region
      error_message = <<-EOT
        Replication requires a multi-region KMS key, and the bucket's existing
        key is single-region. The multi-region setting can't be changed on an
        existing key.
        EOT
    }
  }
}

resource "aws_kms_alias" "replica" {
  for_each = var.replication.enabled && var.kms.create ? toset(["this"]) : toset([])

  name          = "alias/${local.replica_bucket_name}"
  region        = local.replica_region
  target_key_id = aws_kms_replica_key.replica["this"].arn
}

resource "aws_s3_bucket" "replica" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  bucket        = local.replica_bucket_name
  region        = local.replica_region
  force_destroy = var.force_delete

  tags = local.tags

  lifecycle {
    precondition {
      condition     = length(local.replica_bucket_name) <= 63
      error_message = <<-EOT
        The replica bucket name (${local.replica_bucket_name}) is longer than 63
        characters. Shorten project, environment, or name.
        EOT
    }

    precondition {
      condition     = local.replica_region != local.region
      error_message = "The replica region must be different from the bucket region (${local.region})."
    }
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "replica" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "replica" {
  for_each = var.replication.enabled && var.object_lock.enabled ? toset(["this"]) : toset([])

  # Object lock requires versioning to be enabled on the bucket first.
  depends_on = [aws_s3_bucket_versioning.replica]

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region

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

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.replica_kms_key_arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  # Referencing noncurrent-version behavior requires versioning to be enabled
  # first.
  depends_on = [aws_s3_bucket_versioning.replica]

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region

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

resource "aws_s3_bucket_policy" "replica" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  # The public access block must be in place before a bucket policy can be
  # applied.
  depends_on = [aws_s3_bucket_public_access_block.replica]

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region
  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    account          = data.aws_caller_identity.identity.account_id
    bucket           = local.replica_bucket_name
    partition        = data.aws_partition.current.partition
    restrict_malware = false
    scan_role_arn    = ""
  })))
}

resource "aws_s3_bucket_logging" "replica" {
  for_each = var.replication.enabled && var.replication.logging_bucket != null ? toset(["this"]) : toset([])

  bucket = aws_s3_bucket.replica["this"].id
  region = local.replica_region

  target_bucket = var.replication.logging_bucket
  target_prefix = "${local.logs_path}/s3accesslogs/${local.replica_bucket_name}"

  lifecycle {
    precondition {
      condition     = data.aws_s3_bucket.replica_logging["this"].bucket_region == local.replica_region
      error_message = "The replication logging bucket must be in the replica region (${local.replica_region})."
    }
  }
}

resource "aws_iam_role" "replication" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  # bucket_name can be up to 63 characters, so use a truncated prefix and let
  # AWS append a unique suffix to stay within the 64-character role name limit.
  name_prefix = substr("${local.bucket_name}-repl-", 0, 38)
  description = "Role for S3 replication of bucket ${local.bucket_name}"
  path        = "/service-role/"

  assume_role_policy = jsonencode(yamldecode(templatefile("${path.module}/templates/replication-trust.yaml.tftpl", {
    account   = data.aws_caller_identity.identity.account_id
    bucket    = local.bucket_name
    partition = data.aws_partition.current.partition
  })))

  tags = var.tags
}

resource "aws_iam_role_policy" "replication" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  # bucket_name can be up to 63 characters, so use a truncated prefix and let
  # AWS append a unique suffix to stay within the 64-character role name limit.
  name_prefix = substr("${local.bucket_name}-repl-", 0, 38)
  role        = aws_iam_role.replication["this"].id

  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/replication-policy.yaml.tftpl", {
    bucket              = local.bucket_name
    kms_key_arn         = local.kms_key_arn
    partition           = data.aws_partition.current.partition
    region              = local.region
    replica_bucket      = local.replica_bucket_name
    replica_kms_key_arn = local.replica_kms_key_arn
    replica_region      = local.replica_region
  })))
}

resource "aws_s3_bucket_replication_configuration" "this" {
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  # Both buckets need versioning enabled before replication can be configured.
  depends_on = [
    aws_s3_bucket_versioning.this,
    aws_s3_bucket_versioning.replica,
  ]

  bucket = aws_s3_bucket.this.id
  region = local.region
  role   = aws_iam_role.replication["this"].arn

  rule {
    id     = "replication"
    status = "Enabled"

    filter {}

    # Delete markers aren't replicated, so deleting an object in the primary
    # bucket leaves the replica intact. The replica's own lifecycle rules handle
    # expiration.
    delete_marker_replication {
      status = "Disabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.replica["this"].arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = local.replica_kms_key_arn
      }
    }
  }
}
