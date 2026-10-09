resource "aws_kms_replica_key" "replica" {
  for_each = local.replica_kms_source == "replica" ? toset(["this"]) : toset([])

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
}

# A single-region primary key can't be replicated, so the replica bucket gets
# its own key in the replica region instead.
resource "aws_kms_key" "replica" {
  for_each = local.replica_kms_source == "create" ? toset(["this"]) : toset([])

  description             = "Encryption key for bucket ${local.replica_bucket_name}"
  deletion_window_in_days = var.kms.recovery_period
  enable_key_rotation     = true
  region                  = local.replica_region

  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/key-policy.yaml.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    bucket : local.replica_bucket_name
    partition : data.aws_partition.current.partition
    principals : var.kms.allowed_principals
  })))

  tags = var.tags
}

resource "aws_kms_alias" "replica" {
  for_each = contains(["replica", "create"], local.replica_kms_source) ? toset(["this"]) : toset([])

  name          = "alias/${local.replica_bucket_name}"
  region        = local.replica_region
  target_key_id = local.replica_kms_key_arn
}

check "replica_kms_multi_region" {
  assert {
    condition     = !(local.replica_kms_source == "create" && var.kms.multi_region)
    error_message = <<-EOT
      The bucket's KMS key is single-region, so it can't be replicated. A
      separate single-region key is being created in ${local.replica_region}
      for the replica bucket instead.
      EOT
  }
}

module "replica" {
  source   = "./modules/base"
  for_each = var.replication.enabled ? toset(["this"]) : toset([])

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
  expiration                             = var.expiration
  force_delete                           = var.force_delete
  kms_key_arn                            = local.replica_kms_key_arn
  logging_bucket                         = var.replication.logging_bucket
  logging_cloudwatch_log_group_arn       = var.replication.logging_cloudwatch_log_group_arn
  name                                   = local.replica_bucket_name
  noncurrent_version_expiration_days     = var.noncurrent_version_expiration_days
  object_lock                            = var.object_lock
  region                                 = local.replica_region
  storage_class_transitions              = var.storage_class_transitions
  tags                                   = local.tags

  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    account          = data.aws_caller_identity.identity.account_id
    bucket           = local.replica_bucket_name
    partition        = data.aws_partition.current.partition
    restrict_malware = false
    scan_role_arn    = ""
  })))
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
    delete_markers      = var.replication.delete_markers
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
  depends_on = [module.bucket, module.replica]

  bucket = module.bucket.id
  region = local.region
  role   = aws_iam_role.replication["this"].arn

  rule {
    id     = "replication"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = var.replication.delete_markers ? "Enabled" : "Disabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = module.replica["this"].arn
      storage_class = var.replication.storage_class

      encryption_configuration {
        replica_kms_key_id = local.replica_kms_key_arn
      }
    }
  }

  lifecycle {
    precondition {
      condition     = local.replica_region != local.region
      error_message = "The replica region must be different from the bucket region (${local.region})."
    }
  }
}
