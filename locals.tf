locals {
  bucket_name = join("-", [var.project, var.environment, var.name])
  kms_key_arn = var.kms.create ? aws_kms_key.bucket["this"].arn : var.kms.arn
  logs_path   = "/AWSLogs/${data.aws_caller_identity.identity.account_id}"
  tags        = merge({ use : "file-uploads" }, var.tags)
}
