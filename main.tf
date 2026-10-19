resource "random_string" "suffix" {
  count = var.add_suffix ? 1 : 0

  length  = local.suffix_length
  lower   = true
  numeric = true
  special = false
  upper   = false
}

module "bucket" {
  source = "./modules/base"

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
  expiration                             = var.expiration
  force_delete                           = var.force_delete
  kms_key_arn                            = local.kms_key_arn
  logging_bucket                         = var.logging_bucket
  logging_cloudwatch_log_group_arn       = var.logging_cloudwatch_log_group_arn
  name                                   = local.bucket_name
  noncurrent_version_expiration_days     = var.noncurrent_version_expiration_days
  object_lock                            = var.object_lock
  region                                 = local.region
  storage_class_transitions              = var.storage_class_transitions
  tags                                   = local.tags

  policy = jsonencode(merge(local.base_bucket_policy, {
    Statement = concat(local.base_bucket_policy.Statement, var.additional_policy_statements)
  }))
}
