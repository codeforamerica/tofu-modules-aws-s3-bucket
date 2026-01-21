resource "aws_kms_key" "bucket" {
  for_each = var.encryption_key_arn != null ? toset([]) : toset(["this"])

  description             = "Encryption key for bucket ${local.bucket_name}"
  deletion_window_in_days = var.key_recovery_period
  enable_key_rotation     = true
  policy = templatefile("${path.module}/templates/key-policy.json.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    bucket : local.bucket_name
    partition : data.aws_partition.current.partition
    principals : var.allowed_principals
  })

  tags = var.tags
}

resource "aws_kms_alias" "bucket" {
  for_each = var.encryption_key_arn != null ? toset([]) : toset(["this"])

  name          = "alias/${local.bucket_name}"
  target_key_id = each.value.id
}

module "this" {
  source  = "boldlink/s3/aws"
  version = "2.6.0"

  bucket        = local.bucket_name
  force_destroy = var.force_delete

  bucket_policy = templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    partition : data.aws_partition.current.partition
    bucket : local.bucket_name
  })

  lifecycle_configuration = [{
    id     = "state"
    status = "Enabled"

    filter = {
      prefix = ""
    }

    abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days

    noncurrent_version_expiration = [{
      noncurrent_days = var.noncurrent_version_expiration_days
    }]

    transition = var.storage_class_transitions
  }]

  sse_bucket_key_enabled = true
  sse_kms_master_key_arn = local.kms_key_arn
  sse_sse_algorithm      = "aws:kms"

  versioning_status = "Enabled"

  s3_logging = {
    target_bucket = var.logging_bucket
    target_prefix = "${local.logs_path}/s3accesslogs/${local.bucket_name}"
  }

  tags = var.tags
}
